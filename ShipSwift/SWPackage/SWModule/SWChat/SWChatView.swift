//
//  SWChatView.swift
//  ShipSwift
//
//  All-in-one chat view that combines SWMessageList, SWMessageBubble,
//  and SWChatInputView into a single, ready-to-use component.
//  Manages input state internally and appends user messages automatically.
//
//  Usage:
//    // 1. Minimal setup — just provide messages and an onSend callback
//    @State private var messages: [SWChatMessage] = []
//
//    SWChatView(messages: $messages) { text in
//        // Called after the user message is already appended.
//        // Use this to send the text to your AI backend and append the response.
//        Task {
//            let reply = await myAI.send(text)
//            messages.append(SWChatMessage(content: reply, isUser: false))
//        }
//    }
//
//    // 2. Enable voice input by providing an ASR config
//    let asrConfig = SWASRConfig(appId: "YourAppID", accessToken: "YourToken")
//
//    SWChatView(messages: $messages, asrConfig: asrConfig) { text in
//        // ...
//    }
//
//    // 3. Disable input while waiting for AI response
//    @State private var isWaiting = false
//
//    SWChatView(
//        messages: $messages,
//        asrConfig: asrConfig,
//        isDisabled: isWaiting,
//        placeholderText: "Ask anything..."
//    ) { text in
//        isWaiting = true
//        Task {
//            let reply = await myAI.send(text)
//            messages.append(SWChatMessage(content: reply, isUser: false))
//            isWaiting = false
//        }
//    }
//
//    // 4. Custom bubble styling via the optional bubbleContent parameter
//    SWChatView(
//        messages: $messages,
//        asrConfig: asrConfig,
//        onSend: { _ in }
//    ) { message in
//        // Return any View to replace the default bubble
//        Text(message.content)
//            .padding(12)
//            .background(.green)
//            .clipShape(Capsule())
//    }
//
//  Created by Wei Zhong on 2/14/26.
//

import SwiftUI

// MARK: - Chat Message Model

/// A single chat message.
///
/// Conforms to `Identifiable` so it works with `ForEach` / `SWMessageList`.
/// Create user messages with `isUser: true` and AI/system messages with `isUser: false`.
public struct SWChatMessage: Identifiable {
    public let id: UUID
    public let content: String
    public let isUser: Bool
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - Chat View

/// All-in-one chat view.
///
/// Integrates `SWMessageList`, `SWMessageBubble`, and `SWChatInputView`
/// into a single component. The view:
/// - Maintains input text state internally
/// - Appends user messages to the binding automatically on send
/// - Displays messages using the flip-based `SWMessageList`
/// - Provides default bubble styling (accent for user, gray for AI)
/// - Optionally supports ASR voice input when `asrConfig` is provided
///
/// Minimal usage (text only, no voice):
/// ```swift
/// @State private var messages: [SWChatMessage] = []
///
/// SWChatView(messages: $messages) { text in
///     // Handle AI response
/// }
/// ```
///
/// With voice input:
/// ```swift
/// SWChatView(
///     messages: $messages,
///     asrConfig: SWASRConfig(appId: "id", accessToken: "token")
/// ) { text in
///     // Handle AI response
/// }
/// ```
public struct SWChatView<BubbleContent: View>: View {
    @Binding public var messages: [SWChatMessage]
    public let asrConfig: SWASRConfig?
    public let isDisabled: Bool
    public let placeholderText: LocalizedStringKey
    public let onSend: (String) -> Void
    public let bubbleContent: ((SWChatMessage) -> BubbleContent)?

    @State private var inputText = ""

    /// Initialize with default bubble styling.
    /// - Parameters:
    ///   - messages: Binding to the message array (chronological order, oldest first)
    ///   - asrConfig: ASR configuration for voice input. Pass nil to hide the microphone button.
    ///   - isDisabled: Disable input (e.g. while waiting for AI response)
    ///   - placeholderText: Placeholder text for the input field
    ///   - onSend: Callback fired after the user message is appended.
    ///             Receives the sent text so you can forward it to your backend.
    public init(
        messages: Binding<[SWChatMessage]>,
        asrConfig: SWASRConfig? = nil,
        isDisabled: Bool = false,
        placeholderText: LocalizedStringKey = "Type a message...",
        onSend: @escaping (String) -> Void
    ) where BubbleContent == EmptyView {
        self._messages = messages
        self.asrConfig = asrConfig
        self.isDisabled = isDisabled
        self.placeholderText = placeholderText
        self.onSend = onSend
        self.bubbleContent = nil
    }

    /// Initialize with custom bubble content.
    /// - Parameters:
    ///   - messages: Binding to the message array (chronological order, oldest first)
    ///   - asrConfig: ASR configuration for voice input. Pass nil to hide the microphone button.
    ///   - isDisabled: Disable input (e.g. while waiting for AI response)
    ///   - placeholderText: Placeholder text for the input field
    ///   - onSend: Callback fired after the user message is appended
    ///   - bubbleContent: Custom view builder for each message bubble
    public init(
        messages: Binding<[SWChatMessage]>,
        asrConfig: SWASRConfig? = nil,
        isDisabled: Bool = false,
        placeholderText: LocalizedStringKey = "Type a message...",
        onSend: @escaping (String) -> Void,
        @ViewBuilder bubbleContent: @escaping (SWChatMessage) -> BubbleContent
    ) {
        self._messages = messages
        self.asrConfig = asrConfig
        self.isDisabled = isDisabled
        self.placeholderText = placeholderText
        self.onSend = onSend
        self.bubbleContent = bubbleContent
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Message list
            SWMessageList(messages: messages) { message in
                SWMessageBubble(isFromUser: message.isUser) {
                    if let bubbleContent {
                        bubbleContent(message)
                    } else {
                        defaultBubble(for: message)
                    }
                }
            }

            // Input bar
            SWChatInputView(
                text: $inputText,
                asrConfig: asrConfig,
                isDisabled: isDisabled,
                placeHolderText: placeholderText
            ) {
                send()
            }
        }
    }

    // MARK: - Default Bubble

    /// Default bubble styling: accent background for user, gray for AI.
    @ViewBuilder
    private func defaultBubble(for message: SWChatMessage) -> some View {
        Text(message.content)
            .padding(12)
            .background(message.isUser ? Color.accentColor : Color(UIColor.systemGray6))
            .foregroundStyle(message.isUser ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Send Action

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Append user message
        let userMessage = SWChatMessage(content: text, isUser: true)
        messages.append(userMessage)

        // Clear input
        inputText = ""

        // Notify caller
        onSend(text)
    }
}

// MARK: - Previews

#Preview("Chat View") {
    SWChatPreview()
}

private struct SWChatPreview: View {
    @State private var messages: [SWChatMessage] = [
        SWChatMessage(content: "Hello!", isUser: true),
        SWChatMessage(content: "Hi there! How can I help you today?", isUser: false),
        SWChatMessage(content: "Show me how SWChatView works.", isUser: true),
        SWChatMessage(
            content: "SWChatView combines SWMessageList, SWMessageBubble, and SWChatInputView into one component. Just provide a messages binding, ASR config, and an onSend callback.",
            isUser: false
        ),
    ]

    var body: some View {
        SWChatView(messages: $messages) { text in
            // Simulate AI response
            Task {
                try? await Task.sleep(for: .seconds(1))
                messages.append(
                    SWChatMessage(
                        content: "This is a demo response. Connect ShipSwift MCP to enable full AI chat functionality.",
                        isUser: false
                    )
                )
            }
        }
    }
}
