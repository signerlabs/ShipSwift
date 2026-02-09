//
//  slFaceCameraManager.swift
//  ShipSwift
//
//  面部识别相机管理器
//  支持前后摄像头切换 + Vision 实时面部地标检测 + 拍照
//
//  使用方法:
//    @State private var camera = slFaceCameraManager(position: .front)
//
//    camera.faceTrackingEnabled = true   // 开启实时面部追踪
//    camera.startSession()
//    camera.faceLandmarks                // 获取实时面部地标数据
//

import SwiftUI
import AVFoundation
import Vision

@Observable
final class slFaceCameraManager: NSObject, @unchecked Sendable {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    var isAuthorized = false

    /// 当前摄像头位置
    var cameraPosition: AVCaptureDevice.Position = .front

    /// 后台线程安全读取的摄像头位置副本
    @ObservationIgnored
    private nonisolated(unsafe) var _bgCameraPosition: AVCaptureDevice.Position = .front

    /// 前置摄像头缩放倍数
    var frontZoomFactor: CGFloat = 1.0

    /// 后置摄像头缩放倍数
    var backZoomFactor: CGFloat = 1.0

    /// 实时检测到的全部面部地标（capture device 归一化坐标，左上角原点）
    var faceLandmarks: [slFaceLandmarkGroup] = []

    /// 是否启用实时面部检测（后台线程也需读取）
    @ObservationIgnored
    nonisolated(unsafe) var faceTrackingEnabled = false

    // 使用专用队列确保线程安全
    private let sessionQueue = DispatchQueue(label: "com.shipswift.facecamera.session")
    private var isConfigured = false
    private var isConfiguring = false
    private var pendingStartSession = false

    // 视频帧处理（实时检测用，后台线程访问）
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataQueue = DispatchQueue(label: "com.shipswift.facecamera.videodata", qos: .userInitiated)
    private nonisolated(unsafe) let sequenceHandler = VNSequenceRequestHandler()

    override init() {
        super.init()
        checkCameraPermission()
    }

    /// 使用指定摄像头位置初始化
    init(position: AVCaptureDevice.Position, frontZoom: CGFloat = 1.0, backZoom: CGFloat = 1.0) {
        self.cameraPosition = position
        self._bgCameraPosition = position
        self.frontZoomFactor = frontZoom
        self.backZoomFactor = backZoom
        super.init()
        checkCameraPermission()
    }

    // MARK: - 权限检查

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted {
                        self.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    // MARK: - 相机配置

    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isConfigured, !self.isConfiguring else { return }

            self.isConfiguring = true
            self.session.beginConfiguration()

            // 清除现有输入和输出
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition) else {
                self.session.commitConfiguration()
                self.isConfiguring = false
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)

                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    self.session.commitConfiguration()
                    self.isConfiguring = false
                    return
                }

                self.session.sessionPreset = .photo

                if self.photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.hevc) {
                    self.photoOutput.maxPhotoQualityPrioritization = .balanced
                }

                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                } else {
                    self.session.commitConfiguration()
                    self.isConfiguring = false
                    return
                }

                // 添加视频帧输出（实时面部检测用）
                self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoDataQueue)
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                if self.session.canAddOutput(self.videoDataOutput) {
                    self.session.addOutput(self.videoDataOutput)
                }

                self.applyZoomFactor(camera, factor: self.zoomFactor(for: self.cameraPosition))
                self.configureAutoFocus(camera)

                self.session.commitConfiguration()
                self.isConfigured = true
                self.isConfiguring = false

                if self.pendingStartSession {
                    self.pendingStartSession = false
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                }

            } catch {
                self.session.commitConfiguration()
                self.isConfiguring = false
            }
        }
    }

    // MARK: - Session 控制

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if self.isConfiguring {
                self.pendingStartSession = true
                return
            }

            guard self.isConfigured else {
                self.pendingStartSession = true
                return
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    // MARK: - 切换摄像头

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            let newPosition: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front

            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
                return
            }

            self.session.beginConfiguration()

            for input in self.session.inputs {
                self.session.removeInput(input)
            }

            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.applyZoomFactor(newCamera, factor: self.zoomFactor(for: newPosition))
                    self.configureAutoFocus(newCamera)
                    self._bgCameraPosition = newPosition
                    DispatchQueue.main.async {
                        self.cameraPosition = newPosition
                    }
                }
            } catch {
                // 切换失败
            }

            self.session.commitConfiguration()
        }
    }

    // MARK: - 拍照

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.captureCompletion = completion

        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            settings = AVCapturePhotoSettings()
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - 内部工具

    private func zoomFactor(for position: AVCaptureDevice.Position) -> CGFloat {
        return position == .front ? frontZoomFactor : backZoomFactor
    }

    private func configureAutoFocus(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()

            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            } else if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }

            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }

            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }

            device.unlockForConfiguration()
        } catch {
            // 配置失败
        }
    }

    private func applyZoomFactor(_ device: AVCaptureDevice, factor: CGFloat) {
        do {
            try device.lockForConfiguration()
            let minZoom = device.minAvailableVideoZoomFactor
            let maxZoom = device.maxAvailableVideoZoomFactor
            let clampedFactor = max(minZoom, min(factor, maxZoom))
            device.videoZoomFactor = clampedFactor
            device.unlockForConfiguration()
        } catch {
            // 缩放失败
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension slFaceCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            DispatchQueue.main.async {
                self.captureCompletion?(nil)
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.captureCompletion?(nil)
            }
            return
        }

        DispatchQueue.main.async {
            self.captureCompletion?(image)
        }
    }
}

// MARK: - 实时面部地标检测

extension slFaceCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard faceTrackingEnabled else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // 前置摄像头镜像，后置正常
        let orientation: CGImagePropertyOrientation = _bgCameraPosition == .front ? .leftMirrored : .right

        let request = VNDetectFaceLandmarksRequest()
        try? sequenceHandler.perform([request], on: pixelBuffer, orientation: orientation)

        guard let face = request.results?.first,
              let landmarks = face.landmarks else {
            Task { @MainActor in
                self.faceLandmarks = []
            }
            return
        }

        let bbox = face.boundingBox
        var groups: [slFaceLandmarkGroup] = []

        /// 将 Vision 地标点转换为 capture device 归一化坐标
        func convert(_ region: VNFaceLandmarkRegion2D?, type: slFaceLandmarkRegion) {
            guard let region else { return }
            let pts = region.normalizedPoints.map { p in
                let x = bbox.origin.x + p.x * bbox.width
                let y = bbox.origin.y + p.y * bbox.height
                return CGPoint(x: x, y: 1.0 - y)
            }
            groups.append(slFaceLandmarkGroup(region: type, points: pts))
        }

        // 提取所有支持的面部地标
        convert(landmarks.faceContour, type: .faceContour)
        convert(landmarks.leftEyebrow, type: .leftEyebrow)
        convert(landmarks.rightEyebrow, type: .rightEyebrow)
        convert(landmarks.leftEye, type: .leftEye)
        convert(landmarks.rightEye, type: .rightEye)
        convert(landmarks.leftPupil, type: .leftPupil)
        convert(landmarks.rightPupil, type: .rightPupil)
        convert(landmarks.nose, type: .nose)
        convert(landmarks.noseCrest, type: .noseCrest)
        convert(landmarks.outerLips, type: .outerLips)
        convert(landmarks.innerLips, type: .innerLips)

        let result = groups
        Task { @MainActor in
            self.faceLandmarks = result
        }
    }
}
