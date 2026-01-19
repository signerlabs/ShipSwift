//
//  SLChatInputView.swift
//  ShipSwift
//
//  聊天输入视图，集成语音识别功能
//

import SwiftUI

// MARK: - Chat Input View

/// 聊天输入视图
///
/// 集成文本输入和语音识别功能，包含：
/// - 文本输入框
/// - 麦克风按钮（点击开始录音）
/// - 录音时显示音波动画
/// - 转录中显示加载状态
/// - 发送按钮
///
/// 配合 `SLMessageList` 使用构建完整聊天界面：
/// ```swift
/// VStack(spacing: 0) {
///     SLMessageList(messages: messages) { message in
///         SLMessageBubble(isFromUser: message.isUser) {
///             Text(message.content)
///         }
///     }
///
///     SLChatInputView(text: $text, asrConfig: asrConfig) {
///         sendMessage()
///     }
/// }
/// ```
///
/// 单独使用:
/// ```swift
/// @State private var text = ""
///
/// let asrConfig = SLASRConfig(
///     appId: "你的AppID",
///     accessToken: "你的AccessToken"
/// )
///
/// SLChatInputView(text: $text, asrConfig: asrConfig) {
///     print("发送: \(text)")
///     text = ""
/// }
/// ```
public struct SLChatInputView: View {
    @Binding public var text: String
    public var onSend: () -> Void
    public var isDisabled: Bool
    public var placeHolderText: LocalizedStringKey
    public var minLines: Int
    public let asrConfig: SLASRConfig

    @FocusState private var isFocused: Bool
    @State private var asrState: SLASRState = .idle
    @State private var asrService: SLVolcEngineASRService?

    public init(
        text: Binding<String>,
        asrConfig: SLASRConfig,
        isDisabled: Bool = false,
        placeHolderText: LocalizedStringKey = "输入消息...",
        minLines: Int = 1,
        onSend: @escaping () -> Void
    ) {
        self._text = text
        self.asrConfig = asrConfig
        self.isDisabled = isDisabled
        self.placeHolderText = placeHolderText
        self.minLines = minLines
        self.onSend = onSend
    }

    /// 输入框是否有有效文字
    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 是否处于ASR活动状态（录音或转录中）
    private var isASRActive: Bool {
        asrState == .recording || asrState == .transcribing
    }

    public var body: some View {
        VStack(spacing: 8) {
            // 输入框区域
            inputArea

            // 语音/发送按钮
            HStack(spacing: 16) {
                Spacer()

                // 麦克风/停止按钮
                microphoneButton

                // 发送按钮
                sendButton
            }
            .padding(.bottom, -2)
            .padding(.trailing, -2)
        }
        .padding(10)
        .contentShape(Rectangle()) // 让整个区域可点击
        .onTapGesture {
            if !isDisabled && asrState == .idle {
                isFocused = true
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.accent, lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - 输入区域

    @ViewBuilder
    private var inputArea: some View {
        switch asrState {
        case .idle:
            // 普通文本输入
            TextField(placeHolderText, text: $text, axis: .vertical)
                .lineLimit(minLines...5)
                .focused($isFocused)
                .disabled(isDisabled)
                .onChange(of: isDisabled) { oldValue, newValue in
                    // 当从禁用状态恢复时，保持输入框非焦点状态，避免键盘自动弹出
                    if oldValue && !newValue {
                        isFocused = false
                    }
                }

        case .recording:
            // 录音中显示音波
            SLAudioWaveformView()

        case .transcribing:
            // 转录中显示loading
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("转录中...")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Spacer()
            }
            .frame(minHeight: 24)
        }
    }

    // MARK: - 麦克风按钮

    @ViewBuilder
    private var microphoneButton: some View {
        switch asrState {
        case .idle:
            // 仅在无文字时显示麦克风
            if !hasText {
                Button {
                    startRecording()
                } label: {
                    Image(systemName: "microphone")
                        .imageScale(.large)
                        .foregroundStyle(.blue, .secondary)
                }
            }

        case .recording:
            // 录音中显示停止按钮
            Button {
                stopRecording()
            } label: {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.red)
            }

        case .transcribing:
            // 转录中显示灰色麦克风
            Image(systemName: "microphone")
                .imageScale(.large)
                .foregroundStyle(.gray)
        }
    }

    // MARK: - 发送按钮

    @ViewBuilder
    private var sendButton: some View {
        Button {
            guard hasText else { return }
            // 先取消焦点，避免键盘弹出
            isFocused = false
            onSend()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(hasText && !isDisabled && !isASRActive ? .blue : .gray)
        }
        .disabled(!hasText || isDisabled || isASRActive)
    }

    // MARK: - ASR操作

    private func startRecording() {
        text = "" // 清空之前的文字
        asrState = .recording

        let service = SLVolcEngineASRService(config: asrConfig)
        asrService = service

        // 设置回调
        service.onTranscriptionUpdate = { transcribedText in
            self.text = transcribedText
        }

        service.onTranscriptionComplete = { finalText in
            self.text = finalText
            self.asrState = .idle
        }

        service.onError = { error in
            print("❌ [SLChatInput] ASR 错误: \(error.localizedDescription)")
            self.asrState = .idle
        }

        // 启动录音
        Task {
            do {
                try await service.startRecording()
            } catch {
                print("❌ [SLChatInput] 启动录音失败: \(error.localizedDescription)")
                asrState = .idle
            }
        }
    }

    private func stopRecording() {
        asrState = .transcribing

        Task {
            await asrService?.stopRecording()
        }
    }
}

// MARK: - ASR State

/// ASR录音状态
fileprivate enum SLASRState: Equatable {
    case idle           // 空闲状态
    case recording      // 录音中
    case transcribing   // 转录中
}

// MARK: - Audio Waveform View

/// 音波动画视图 - 自动填满整个宽度
fileprivate struct SLAudioWaveformView: View {
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 4
    var minHeight: CGFloat = 4
    var maxHeight: CGFloat = 24
    var color: Color = .accentColor

    @State private var phases: [Double] = []
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geometry in
            let barCount = Int(geometry.size.width / (barWidth + spacing))
            HStack(spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(color)
                        .frame(width: barWidth, height: barHeight(for: index, total: barCount))
                }
            }
            .frame(maxWidth: .infinity)
            .onAppear {
                phases = (0..<barCount).map { Double($0) }
                startAnimation(barCount: barCount)
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
        .frame(height: maxHeight)
    }

    private func barHeight(for index: Int, total: Int) -> CGFloat {
        guard phases.indices.contains(index) else { return minHeight }
        let phase = phases[index]
        let normalizedHeight = (sin(phase) + 1) / 2 // 0 到 1
        return minHeight + (maxHeight - minHeight) * normalizedHeight
    }

    private func startAnimation(barCount: Int) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                for i in 0..<barCount {
                    if phases.indices.contains(i) {
                        // 每个bar有不同的相位偏移，产生波浪效果
                        phases[i] += 0.15 + Double(i % 3) * 0.05
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Idle - Empty") {
    SLChatInputView(
        text: .constant(""),
        asrConfig: SLASRConfig(appId: "test", accessToken: "test")
    ) {}
}

#Preview("Idle - With Text") {
    SLChatInputView(
        text: .constant("Hello"),
        asrConfig: SLASRConfig(appId: "test", accessToken: "test")
    ) {}
}

#Preview("Interactive") {
    SLChatInputPreview()
}

private struct SLChatInputPreview: View {
    @State private var text = ""

    var body: some View {
        VStack {
            Spacer()
            SLChatInputView(
                text: $text,
                asrConfig: SLASRConfig(appId: "test", accessToken: "test")
            ) {
                print("Send: \(text)")
                text = ""
            }
        }
    }
}
