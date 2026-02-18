//
//  ChatView.swift
//  ShipSwift
//
//  Chat tab — AI-powered component discovery and preview.
//  Users describe what they need in natural language, and the AI
//  recommends matching SwiftUI components rendered inline as real views.
//
//  Created by Wei Zhong on 18/2/26.
//

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
    @State private var fullScreenComponent: String?
    @State private var sheetComponent: String?
    @State private var pushComponent: String?
    @State private var showPushDestination = false

    private let chatService = ChatService()
    private let registry = ComponentRegistry()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Message list using flip-based SWMessageList
                SWMessageList(messages: messages) { message in
                    SWMessageBubble(isFromUser: message.isUser) {
                        if let componentId = message.componentId,
                           registry.entries[componentId] != nil {
                            ComponentPreviewBubble(
                                componentId: componentId,
                                registry: registry,
                                onViewFullScreen: { presentFullView(for: componentId) },
                                onGetCode: { openGitHub() }
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
            }
            .navigationTitle("ShipSwift AI")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .navigationDestination(isPresented: $showPushDestination) {
                if let id = pushComponent, let view = registry.fullView(for: id) {
                    view
                }
            }
        }
        .fullScreenCover(item: fullScreenComponentBinding) { wrapper in
            if let view = registry.fullView(for: wrapper.id) {
                view
            }
        }
        .sheet(item: sheetComponentBinding) { wrapper in
            if let view = registry.fullView(for: wrapper.id) {
                view
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

    // MARK: - Full View Presentation

    private func presentFullView(for componentId: String) {
        let presentation = registry.presentation(for: componentId)
        switch presentation {
        case .push:
            pushComponent = componentId
            showPushDestination = true
        case .sheet:
            sheetComponent = componentId
        case .fullScreenCover:
            fullScreenComponent = componentId
        }
    }

    // MARK: - Get Code (Copy MCP Command)

    private func openGitHub() {
        if let url = URL(string: "https://github.com/signerlabs/ShipSwift") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Identifiable Wrappers for sheet/fullScreenCover

    @State private var fullScreenComponentWrapper: IdentifiableString?
    @State private var sheetComponentWrapper: IdentifiableString?

    private var fullScreenComponentBinding: Binding<IdentifiableString?> {
        Binding(
            get: { fullScreenComponent.map { IdentifiableString(id: $0) } },
            set: { fullScreenComponent = $0?.id }
        )
    }

    private var sheetComponentBinding: Binding<IdentifiableString?> {
        Binding(
            get: { sheetComponent.map { IdentifiableString(id: $0) } },
            set: { sheetComponent = $0?.id }
        )
    }
}

/// Identifiable wrapper for String used by sheet/fullScreenCover(item:).
private struct IdentifiableString: Identifiable {
    let id: String
}

// MARK: - Component Preview Bubble

/// Renders a live SwiftUI component preview inside a chat bubble.
///
/// Includes the component title, a compact preview area (max height 300pt),
/// and action buttons for full-screen viewing and getting the code.
struct ComponentPreviewBubble: View {
    let componentId: String
    let registry: ComponentRegistry
    let onViewFullScreen: () -> Void
    let onGetCode: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with icon and title
            HStack(spacing: 8) {
                Image(systemName: registry.icon(for: componentId))
                    .foregroundStyle(.accent)
                Text(registry.title(for: componentId))
                    .font(.headline)
            }

            // Component preview area
            if let preview = registry.view(for: componentId) {
                preview
                    .frame(maxHeight: 300)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                    .allowsHitTesting(false)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    onViewFullScreen()
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                        Text("View")
                    }
                    .font(.footnote)
                }

                Button {
                    onGetCode()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Get Code")
                    }
                    .font(.footnote)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    ChatView()
        .swAlert()
}
