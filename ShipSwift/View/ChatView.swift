//
//  ChatView.swift
//  ShipSwift
//
//  Chat tab (iOS only) — AI-powered component discovery and preview.
//  Users describe what they need in natural language, and the AI
//  recommends matching SwiftUI components rendered inline as real views.
//
//  Created by Wei Zhong on 18/2/26.
//

#if os(iOS)

import SwiftUI

// MARK: - Chat Message Model

/// Extended chat message supporting optional component rendering.
///
/// When `componentId` is non-nil, the chat bubble renders a live SwiftUI
/// component preview instead of plain text.
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let componentId: String?

    init(
        content: String,
        isUser: Bool,
        componentId: String? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.componentId = componentId
    }

    // MARK: - Local Persistence

    private static let fileName = "chat_history.json"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    static func loadFromDisk() -> [ChatMessage]? {
        guard let data = try? Data(contentsOf: fileURL),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data),
              !messages.isEmpty else { return nil }
        return messages
    }

    static func saveToDisk(_ messages: [ChatMessage]) {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func clearDisk() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - Chat View

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var isWaiting = false

    private let chatService = ChatService()
    private let registry = ComponentRegistry()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Message list
                SWMessageList(messages: messages) { message in
                    SWMessageBubble(isFromUser: message.isUser) {
                        if let componentId = message.componentId,
                           registry.entries[componentId] != nil {
                            ComponentPreviewBubble(
                                componentId: componentId,
                                registry: registry
                            )
                        } else {
                            // Default text bubble
                            Text(message.content)
                                .padding(12)
                                .background(message.isUser ? Color.accentColor : Color(UIColor.systemGray6))
                                .foregroundStyle(message.isUser ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }

                // Quick suggestions — shown only at initial state
                if messages.count <= 1 && !isWaiting {
                    SWScrollingFAQ(
                        rows: [
                            ["Paywall", "Auth Flow", "Camera", "Chat UI", "Settings", "Face Camera"],
                            ["Bar Chart", "Line Chart", "Donut Chart", "Heatmap", "Radar Chart", "Area Chart"],
                            ["Shimmer", "Onboarding", "Alert", "Loading", "Stepper", "Typewriter Text"]
                        ]
                    ) { question in
                        inputText = question
                        sendMessage()
                    }
                }

                // Thinking indicator when waiting for AI response
                if isWaiting {
                    HStack {
                        HStack(spacing: 4) {
                            Text("Thinking")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            SWThinkingIndicator()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }

                // Input bar
                SWChatInputView(
                    text: $inputText,
                    isDisabled: isWaiting,
                    placeHolderText: "Describe a component..."
                ) {
                    sendMessage()
                }
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
            .navigationTitle("ShipSwift AI")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SettingView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
        .task {
            if let saved = ChatMessage.loadFromDisk() {
                messages = saved
            } else {
                let welcome = ChatMessage(
                    content: "Hi! Describe what you need, and I'll show you the best SwiftUI component from our library.",
                    isUser: false
                )
                messages = [welcome]
            }
        }
        .onChange(of: messages.count) {
            ChatMessage.saveToDisk(messages)
        }
    }

    @State private var inputText = ""

    // MARK: - Send Message

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Append user message
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)

        inputText = ""
        isWaiting = true

        Task {
            let response = await chatService.send(message: text, history: messages)

            // Append AI text reply
            let replyMessage = ChatMessage(content: response.reply, isUser: false)
            messages.append(replyMessage)

            // If a component was matched, append a component preview message
            if let componentId = response.component, registry.entries[componentId] != nil {
                let componentMessage = ChatMessage(
                    content: registry.title(for: componentId),
                    isUser: false,
                    componentId: componentId
                )
                messages.append(componentMessage)
            }

            isWaiting = false
        }
    }

}

// MARK: - Component Preview Bubble

/// Renders a live SwiftUI component preview inside a chat bubble.
///
/// Tapping the bubble opens the full component view in a sheet.
struct ComponentPreviewBubble: View {
    let componentId: String
    let registry: ComponentRegistry

    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Header with icon and title
                HStack(spacing: 8) {
                    Image(systemName: registry.icon(for: componentId))
                        .foregroundStyle(.accent)
                    Text(registry.title(for: componentId))
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }

                // Component preview area
                if let preview = registry.view(for: componentId) {
                    preview
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .allowsHitTesting(false)
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            registry.fullView(for: componentId)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(44)
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
        .swAlert()
}

#endif
