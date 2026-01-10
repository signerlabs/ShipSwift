//
//  SLVolcEngineASRService.swift
//  ShipSwift
//
//  火山引擎流式语音识别服务
//  文档: https://www.volcengine.com/docs/6561/80818
//

import AVFoundation
import Compression
import Foundation
import Network

// MARK: - Configuration

/// 火山引擎 ASR 配置
public struct SLASRConfig {
    public let appId: String
    public let accessToken: String
    public let cluster: String
    public let language: String

    public init(
        appId: String,
        accessToken: String,
        cluster: String = "volcengine_streaming_common",
        language: String = "zh-CN"
    ) {
        self.appId = appId
        self.accessToken = accessToken
        self.cluster = cluster
        self.language = language
    }
}

// MARK: - ASR Service

/// 火山引擎流式语音识别服务
///
/// 使用方式:
/// ```swift
/// let config = SLASRConfig(appId: "xxx", accessToken: "xxx")
/// let asr = SLVolcEngineASRService(config: config)
///
/// asr.onTranscriptionUpdate = { text in print("实时: \(text)") }
/// asr.onTranscriptionComplete = { text in print("完成: \(text)") }
///
/// try await asr.startRecording()
/// // ... 用户说话 ...
/// await asr.stopRecording()
/// ```
@Observable
public final class SLVolcEngineASRService: @unchecked Sendable {

    // MARK: - Configuration

    private let host = "openspeech.bytedance.com"
    private let port: UInt16 = 443
    private let path = "/api/v2/asr"
    private let config: SLASRConfig

    // MARK: - State

    public private(set) var isRecording = false
    public private(set) var transcribedText = ""
    public private(set) var error: Error?

    // MARK: - Callbacks

    /// 实时转录更新回调
    public var onTranscriptionUpdate: ((String) -> Void)?
    /// 转录完成回调
    public var onTranscriptionComplete: ((String) -> Void)?
    /// 错误回调
    public var onError: ((Error) -> Void)?

    // MARK: - Private Properties

    private var connection: NWConnection?
    private var audioEngine: AVAudioEngine?
    private var isConnected = false
    private var connectionContinuation: CheckedContinuation<Void, Error>?
    private var receiveBuffer = Data()
    private let queue = DispatchQueue(label: "com.shipswift.asr.websocket")
    private var audioConverter: AVAudioConverter?
    private let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!

    // MARK: - Initialization

    public init(config: SLASRConfig) {
        self.config = config
    }

    // MARK: - Public Methods

    /// 开始录音并进行语音识别
    public func startRecording() async throws {
        guard !isRecording else { return }

        let granted = await requestMicrophonePermission()
        guard granted else {
            throw SLASRError.microphonePermissionDenied
        }

        transcribedText = ""
        error = nil

        try await connectWebSocket()
        try sendFullClientRequest()
        try startAudioEngine()

        isRecording = true
    }

    /// 停止录音
    public func stopRecording() async {
        guard isRecording else { return }

        isRecording = false
        stopAudioEngine()
        sendEndOfAudio()
    }

    /// 取消录音
    public func cancelRecording() {
        isRecording = false
        stopAudioEngine()
        disconnectWebSocket()
        transcribedText = ""
    }

    // MARK: - Microphone Permission

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - WebSocket Connection

    private func connectWebSocket() async throws {
        let tlsOptions = NWProtocolTLS.Options()
        let tcpOptions = NWProtocolTCP.Options()
        let params = NWParameters(tls: tlsOptions, tcp: tcpOptions)

        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: params)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connectionContinuation = continuation

            connection?.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                Task { @MainActor in
                    switch state {
                    case .ready:
                        self.performWebSocketHandshake()
                    case .failed(let error):
                        self.connectionContinuation?.resume(throwing: error)
                        self.connectionContinuation = nil
                    default:
                        break
                    }
                }
            }

            connection?.start(queue: queue)
        }
    }

    private func performWebSocketHandshake() {
        var keyBytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, 16, &keyBytes)
        let wsKey = Data(keyBytes).base64EncodedString()

        let request = """
        GET \(path) HTTP/1.1\r
        Host: \(host)\r
        Upgrade: websocket\r
        Connection: Upgrade\r
        Sec-WebSocket-Key: \(wsKey)\r
        Sec-WebSocket-Version: 13\r
        Authorization: Bearer;\(config.accessToken)\r
        \r

        """

        connection?.send(content: request.data(using: .utf8), completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.connectionContinuation?.resume(throwing: error)
                self?.connectionContinuation = nil
            } else {
                self?.receiveHandshakeResponse()
            }
        })
    }

    private func receiveHandshakeResponse() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] content, _, _, error in
            guard let self else { return }

            if let error = error {
                self.connectionContinuation?.resume(throwing: error)
                self.connectionContinuation = nil
                return
            }

            if let data = content, let response = String(data: data, encoding: .utf8) {
                if response.contains("101") && response.lowercased().contains("upgrade") {
                    self.isConnected = true
                    self.connectionContinuation?.resume()
                    self.connectionContinuation = nil
                    self.startReceivingFrames()
                } else {
                    self.connectionContinuation?.resume(throwing: SLASRError.connectionFailed)
                    self.connectionContinuation = nil
                }
            }
        }
    }

    private func startReceivingFrames() {
        guard isConnected else { return }

        connection?.receive(minimumIncompleteLength: 2, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self else { return }

            if error != nil {
                DispatchQueue.main.async {
                    if !self.transcribedText.isEmpty {
                        self.onTranscriptionComplete?(self.transcribedText)
                    }
                }
                return
            }

            if let data = content {
                self.receiveBuffer.append(data)
                self.processWebSocketFrames()
            }

            if isComplete {
                self.isConnected = false
                DispatchQueue.main.async {
                    if !self.transcribedText.isEmpty {
                        self.onTranscriptionComplete?(self.transcribedText)
                    }
                }
            } else {
                self.startReceivingFrames()
            }
        }
    }

    private func processWebSocketFrames() {
        let bufferCopy = Array(receiveBuffer)
        guard bufferCopy.count >= 2 else { return }

        var offset = 0
        while bufferCopy.count - offset >= 2 {
            let firstByte = bufferCopy[offset]
            let secondByte = bufferCopy[offset + 1]

            let isMasked = (secondByte & 0x80) != 0
            var payloadLength = UInt64(secondByte & 0x7F)
            var headerSize = 2

            if payloadLength == 126 {
                guard bufferCopy.count - offset >= 4 else { break }
                payloadLength = UInt64(bufferCopy[offset + 2]) << 8 | UInt64(bufferCopy[offset + 3])
                headerSize = 4
            } else if payloadLength == 127 {
                guard bufferCopy.count - offset >= 10 else { break }
                payloadLength = 0
                for i in 0..<8 {
                    payloadLength = payloadLength << 8 | UInt64(bufferCopy[offset + 2 + i])
                }
                headerSize = 10
            }

            if isMasked { headerSize += 4 }

            let totalLength = headerSize + Int(payloadLength)
            guard bufferCopy.count - offset >= totalLength else { break }

            var payload = Data(bufferCopy[(offset + headerSize)..<(offset + totalLength)])

            if isMasked {
                let maskStart = offset + headerSize - 4
                let maskKey = Array(bufferCopy[maskStart..<(maskStart + 4)])
                for i in 0..<payload.count {
                    payload[i] ^= maskKey[i % 4]
                }
            }

            offset += totalLength

            let opcode = firstByte & 0x0F
            switch opcode {
            case 0x01, 0x02:
                handleServerResponse(payload)
            case 0x08:
                isConnected = false
                DispatchQueue.main.async {
                    if !self.transcribedText.isEmpty {
                        self.onTranscriptionComplete?(self.transcribedText)
                    }
                }
            case 0x09:
                sendPong(payload)
            default:
                break
            }
        }

        if offset > 0 {
            receiveBuffer.removeFirst(offset)
        }
    }

    private func sendPong(_ data: Data) {
        sendWebSocketFrame(opcode: 0x0A, payload: data)
    }

    private func disconnectWebSocket() {
        if isConnected {
            sendWebSocketFrame(opcode: 0x08, payload: Data())
        }
        connection?.cancel()
        connection = nil
        isConnected = false
        receiveBuffer.removeAll()
    }

    private func sendWebSocketFrame(opcode: UInt8, payload: Data) {
        var frame = Data()
        frame.append(0x80 | opcode)

        let length = payload.count
        if length < 126 {
            frame.append(UInt8(0x80 | length))
        } else if length < 65536 {
            frame.append(0xFE)
            frame.append(UInt8((length >> 8) & 0xFF))
            frame.append(UInt8(length & 0xFF))
        } else {
            frame.append(0xFF)
            for i in (0..<8).reversed() {
                frame.append(UInt8((length >> (i * 8)) & 0xFF))
            }
        }

        var maskKey = [UInt8](repeating: 0, count: 4)
        _ = SecRandomCopyBytes(kSecRandomDefault, 4, &maskKey)
        frame.append(contentsOf: maskKey)

        var maskedPayload = payload
        for i in 0..<maskedPayload.count {
            maskedPayload[i] ^= maskKey[i % 4]
        }
        frame.append(maskedPayload)

        connection?.send(content: frame, completion: .contentProcessed { _ in })
    }

    // MARK: - Binary Protocol

    private func sendFullClientRequest() throws {
        let payload: [String: Any] = [
            "app": [
                "appid": config.appId,
                "token": config.accessToken,
                "cluster": config.cluster
            ],
            "user": ["uid": UUID().uuidString],
            "audio": [
                "format": "pcm",
                "rate": 16000,
                "bits": 16,
                "channel": 1,
                "language": config.language
            ],
            "request": [
                "reqid": UUID().uuidString,
                "workflow": "audio_in,resample,partition,vad,fe,decode,itn,nlu_punctuate",
                "result_type": "full",
                "show_utterances": true
            ]
        ]

        let message = try buildFullClientRequest(payload: payload)
        sendWebSocketMessage(message)
    }

    private func sendAudioData(_ audioData: Data) {
        guard isConnected else { return }
        let message = buildAudioOnlyRequest(audioData: audioData)
        sendWebSocketMessage(message)
    }

    private func sendEndOfAudio() {
        let message = buildAudioOnlyRequest(audioData: Data(), isLast: true)
        sendWebSocketMessage(message)
    }

    private func sendWebSocketMessage(_ data: Data) {
        sendWebSocketFrame(opcode: 0x02, payload: data)
    }

    private func buildFullClientRequest(payload: [String: Any]) throws -> Data {
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        let compressedPayload = try gzipCompress(jsonData)

        var header = Data()
        header.append(0x11)
        header.append(0x10)
        header.append(0x11)
        header.append(0x00)

        var payloadSize = UInt32(compressedPayload.count).bigEndian
        header.append(Data(bytes: &payloadSize, count: 4))

        return header + compressedPayload
    }

    private func buildAudioOnlyRequest(audioData: Data, isLast: Bool = false) -> Data {
        var header = Data()
        header.append(0x11)
        header.append(isLast ? 0x22 : 0x20)
        header.append(0x00)
        header.append(0x00)

        var payloadSize = UInt32(audioData.count).bigEndian
        header.append(Data(bytes: &payloadSize, count: 4))

        return header + audioData
    }

    private func handleServerResponse(_ data: Data) {
        guard data.count >= 4 else { return }

        let messageType = (data[1] >> 4) & 0x0F
        let compression = data[2] & 0x0F

        if messageType == 0x0B { return }

        if messageType == 0x0F {
            guard data.count >= 8 else { return }
            let payloadSize = data.subdata(in: 4..<8).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            let actualSize = min(Int(payloadSize), data.count - 8)
            guard actualSize > 0 else { return }

            let payloadData = data.subdata(in: 8..<(8 + actualSize))
            var jsonData = payloadData
            if compression == 0x01 {
                jsonData = (try? gzipDecompress(payloadData)) ?? payloadData
            }

            if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let message = json["message"] as? String {
                DispatchQueue.main.async {
                    self.onError?(SLASRError.serverError(message))
                }
            }
            return
        }

        guard data.count >= 8 else { return }
        let payloadSize = Int(data.subdata(in: 4..<8).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian })
        let actualPayloadSize = min(payloadSize, data.count - 8)
        guard actualPayloadSize > 0 else { return }

        let payloadData = data.subdata(in: 8..<(8 + actualPayloadSize))
        var jsonData = payloadData

        if compression == 0x01 {
            guard let decompressed = try? gzipDecompress(payloadData) else { return }
            jsonData = decompressed
        }

        if let response = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            handleASRResponse(response)
        }
    }

    private func handleASRResponse(_ response: [String: Any]) {
        if let code = response["code"] as? Int, code != 1000 {
            let message = response["message"] as? String ?? "未知错误"
            DispatchQueue.main.async {
                self.onError?(SLASRError.serverError(message))
            }
            return
        }

        var text: String?
        var isEnd = false

        if let resultArray = response["result"] as? [[String: Any]], let firstResult = resultArray.first {
            text = firstResult["text"] as? String

            if let utterances = firstResult["utterances"] as? [[String: Any]], !utterances.isEmpty {
                if let lastUtterance = utterances.last {
                    text = lastUtterance["text"] as? String
                    isEnd = (lastUtterance["definite"] as? Int ?? 0) == 1
                }
            }
        }

        if text == nil, let directText = response["text"] as? String {
            text = directText
            isEnd = response["is_end"] as? Bool ?? false
        }

        if let text = text, !text.isEmpty {
            DispatchQueue.main.async {
                self.transcribedText = text
                self.onTranscriptionUpdate?(text)
            }
        }

        if isEnd {
            DispatchQueue.main.async {
                self.onTranscriptionComplete?(self.transcribedText)
            }
        }
    }

    // MARK: - Audio Engine

    private func startAudioEngine() throws {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try audioSession.setActive(true)
        #endif

        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw SLASRError.audioConverterFailed
        }
        audioConverter = converter

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self, self.isRecording else { return }
            if let data = self.convertBuffer(buffer) {
                self.sendAudioData(data)
            }
        }

        try audioEngine.start()
        self.audioEngine = audioEngine
    }

    private func stopAudioEngine() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioConverter = nil
    }

    private func convertBuffer(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let converter = audioConverter else { return nil }

        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

        guard let output = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return nil }

        var error: NSError?
        var hasData = false

        converter.convert(to: output, error: &error) { _, outStatus in
            if hasData {
                outStatus.pointee = .noDataNow
                return nil
            }
            hasData = true
            outStatus.pointee = .haveData
            return buffer
        }

        if error != nil { return nil }

        let audioBuffer = output.audioBufferList.pointee.mBuffers
        guard let mData = audioBuffer.mData, audioBuffer.mDataByteSize > 0 else { return nil }
        return Data(bytes: mData, count: Int(audioBuffer.mDataByteSize))
    }

    // MARK: - Compression

    private func gzipCompress(_ data: Data) throws -> Data {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        defer { buffer.deallocate() }

        let size = data.withUnsafeBytes { src -> Int in
            compression_encode_buffer(buffer, data.count, src.bindMemory(to: UInt8.self).baseAddress!, data.count, nil, COMPRESSION_ZLIB)
        }

        guard size > 0 else { throw SLASRError.compressionFailed }

        var result = Data([0x1F, 0x8B, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03])
        result.append(Data(bytes: buffer, count: size))

        var crc = crc32(data).littleEndian
        result.append(Data(bytes: &crc, count: 4))
        var len = UInt32(data.count).littleEndian
        result.append(Data(bytes: &len, count: 4))

        return result
    }

    private func gzipDecompress(_ data: Data) throws -> Data {
        guard data.count > 18 else { throw SLASRError.decompressionFailed }

        var offset = 10
        if data[3] & 0x04 != 0 { offset += 2 + Int(data[10]) + Int(data[11]) << 8 }
        if data[3] & 0x08 != 0 { while offset < data.count && data[offset] != 0 { offset += 1 }; offset += 1 }
        if data[3] & 0x10 != 0 { while offset < data.count && data[offset] != 0 { offset += 1 }; offset += 1 }
        if data[3] & 0x02 != 0 { offset += 2 }

        let compressed = data.subdata(in: offset..<(data.count - 8))
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: compressed.count * 10)
        defer { buffer.deallocate() }

        let size = compressed.withUnsafeBytes { src -> Int in
            compression_decode_buffer(buffer, compressed.count * 10, src.bindMemory(to: UInt8.self).baseAddress!, compressed.count, nil, COMPRESSION_ZLIB)
        }

        guard size > 0 else { throw SLASRError.decompressionFailed }
        return Data(bytes: buffer, count: size)
    }

    private func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 { crc = crc & 1 != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1 }
        }
        return ~crc
    }
}

// MARK: - Error Types

public enum SLASRError: LocalizedError {
    case microphonePermissionDenied
    case connectionFailed
    case audioConverterFailed
    case compressionFailed
    case decompressionFailed
    case serverError(String)

    public var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied: return "麦克风权限被拒绝"
        case .connectionFailed: return "连接失败"
        case .audioConverterFailed: return "音频转换器创建失败"
        case .compressionFailed: return "数据压缩失败"
        case .decompressionFailed: return "数据解压失败"
        case .serverError(let msg): return "服务器错误: \(msg)"
        }
    }
}
