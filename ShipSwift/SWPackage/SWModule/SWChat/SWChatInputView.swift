//
//  SWChatInputView.swift
//  ShipSwift
//
//  Chat input view with integrated speech recognition
//

import SwiftUI

// MARK: - Chat Input View

/// Chat input view
///
/// Integrates text input and speech recognition, including:
/// - Text input field
/// - Microphone button (tap to start recording)
/// - Audio waveform animation while recording
/// - Loading state during transcription
/// - Send button
///
/// Use with `SWMessageList` to build a complete chat interface:
/// ```swift
/// VStack(spacing: 0) {
///     SWMessageList(messages: messages) { message in
///         SWMessageBubble(isFromUser: message.isUser) {
///             Text(message.content)
///         }
///     }
///
///     SWChatInputView(text: $text, asrConfig: asrConfig) {
///         sendMessage()
///     }
/// }
/// ```
///
/// Standalone usage:
/// ```swift
/// @State private var text = ""
///
/// let asrConfig = SWASRConfig(
///     appId: "YourAppID",
///     accessToken: "YourAccessToken"
/// )
///
/// SWChatInputView(text: $text, asrConfig: asrConfig) {
///     print("Send: \(text)")
///     text = ""
/// }
/// ```
public struct SWChatInputView: View {
    @Binding public var text: String
    public var onSend: () -> Void
    public var isDisabled: Bool
    public var placeHolderText: LocalizedStringKey
    public var minLines: Int
    public let asrConfig: SWASRConfig

    @FocusState private var isFocused: Bool
    @State private var asrState: SWASRState = .idle
    @State private var asrService: SWVolcEngineASRService?

    public init(
        text: Binding<String>,
        asrConfig: SWASRConfig,
        isDisabled: Bool = false,
        placeHolderText: LocalizedStringKey = "Type a message...",
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

    /// Whether the input field has valid text
    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Whether ASR is active (recording or transcribing)
    private var isASRActive: Bool {
        asrState == .recording || asrState == .transcribing
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Input area
            inputArea

            // Voice / send buttons
            HStack(spacing: 16) {
                Spacer()

                // Microphone / stop button
                microphoneButton

                // Send button
                sendButton
            }
            .padding(.bottom, -2)
            .padding(.trailing, -2)
        }
        .padding(10)
        .contentShape(Rectangle()) // Make the entire area tappable
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

    // MARK: - Input Area

    @ViewBuilder
    private var inputArea: some View {
        switch asrState {
        case .idle:
            // Normal text input
            TextField(placeHolderText, text: $text, axis: .vertical)
                .lineLimit(minLines...5)
                .focused($isFocused)
                .disabled(isDisabled)
                .onChange(of: isDisabled) { oldValue, newValue in
                    // When recovering from disabled state, keep the input unfocused to avoid keyboard auto-popup
                    if oldValue && !newValue {
                        isFocused = false
                    }
                }

        case .recording:
            // Show waveform while recording
            SWAudioWaveformView()

        case .transcribing:
            // Show loading during transcription
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Transcribing...")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Spacer()
            }
            .frame(minHeight: 24)
        }
    }

    // MARK: - Microphone Button

    @ViewBuilder
    private var microphoneButton: some View {
        switch asrState {
        case .idle:
            // Only show microphone when there is no text
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
            // Show stop button while recording
            Button {
                stopRecording()
            } label: {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.red)
            }

        case .transcribing:
            // Show grayed-out microphone during transcription
            Image(systemName: "microphone")
                .imageScale(.large)
                .foregroundStyle(.gray)
        }
    }

    // MARK: - Send Button

    @ViewBuilder
    private var sendButton: some View {
        Button {
            guard hasText else { return }
            // Dismiss focus first to avoid keyboard popup
            isFocused = false
            onSend()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(hasText && !isDisabled && !isASRActive ? .blue : .gray)
        }
        .disabled(!hasText || isDisabled || isASRActive)
    }

    // MARK: - ASR Actions

    private func startRecording() {
        text = "" // Clear previous text
        asrState = .recording

        let service = SWVolcEngineASRService(config: asrConfig)
        asrService = service

        // Set callbacks
        service.onTranscriptionUpdate = { transcribedText in
            self.text = transcribedText
        }

        service.onTranscriptionComplete = { finalText in
            self.text = finalText
            self.asrState = .idle
        }

        service.onError = { error in
            print("[SWChatInput] ASR error: \(error.localizedDescription)")
            self.asrState = .idle
        }

        // Start recording
        Task {
            do {
                try await service.startRecording()
            } catch {
                print("[SWChatInput] Failed to start recording: \(error.localizedDescription)")
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

/// ASR recording state
fileprivate enum SWASRState: Equatable {
    case idle           // Idle state
    case recording      // Recording
    case transcribing   // Transcribing
}

// MARK: - Audio Waveform View

/// Audio waveform animation view - automatically fills the entire width
fileprivate struct SWAudioWaveformView: View {
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
        let normalizedHeight = (sin(phase) + 1) / 2 // 0 to 1
        return minHeight + (maxHeight - minHeight) * normalizedHeight
    }

    private func startAnimation(barCount: Int) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                for i in 0..<barCount {
                    if phases.indices.contains(i) {
                        // Each bar has a different phase offset to create a wave effect
                        phases[i] += 0.15 + Double(i % 3) * 0.05
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Idle - Empty") {
    SWChatInputView(
        text: .constant(""),
        asrConfig: SWASRConfig(appId: "test", accessToken: "test")
    ) {}
}

#Preview("Idle - With Text") {
    SWChatInputView(
        text: .constant("Hello"),
        asrConfig: SWASRConfig(appId: "test", accessToken: "test")
    ) {}
}

#Preview("Interactive") {
    SWChatInputPreview()
}

private struct SWChatInputPreview: View {
    @State private var text = ""

    var body: some View {
        VStack {
            Spacer()
            SWChatInputView(
                text: $text,
                asrConfig: SWASRConfig(appId: "test", accessToken: "test")
            ) {
                print("Send: \(text)")
                text = ""
            }
        }
    }
}
