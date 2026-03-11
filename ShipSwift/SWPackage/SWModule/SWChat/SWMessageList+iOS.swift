//
//  SWMessageList+iOS.swift
//  ShipSwift
//
//  Scrollable chat message list with bubble styling.
//  Uses List + ScrollViewReader with throttled auto-scroll to keep
//  the latest message visible. Avoids ScrollView + LazyVStack which
//  causes 100% CPU from infinite layout loops during streaming updates.
//
//  Advantages over the old flip technique:
//  - Text is selectable (no coordinate system inversion)
//  - Smooth, throttled scrolling during streaming (no jank)
//  - Standard coordinate system — no mental overhead for consumers
//
//  Usage:
//    // 1. Basic message list (messages in chronological order, oldest first)
//    SWMessageList(messages: messages) { message in
//        SWMessageBubble(isFromUser: message.isUser) {
//            Text(message.content)
//                .padding(12)
//                .background(message.isUser ? Color.accentColor : Color(.systemGray6))
//                .foregroundStyle(message.isUser ? .white : .primary)
//                .clipShape(RoundedRectangle(cornerRadius: 16))
//        }
//    }
//
//    // 2. Message model must conform to Identifiable
//    struct ChatMessage: Identifiable {
//        let id = UUID()
//        let content: String
//        let isUser: Bool
//    }
//
//    // 3. SWMessageBubble aligns user messages to trailing, others to leading
//    SWMessageBubble(isFromUser: true) {
//        Text("Hello!")  // right-aligned bubble
//    }
//    SWMessageBubble(isFromUser: false) {
//        Text("Hi!")     // left-aligned bubble
//    }
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

private let swMessageBubbleBackground = Color(UIColor.systemGray6)

// MARK: - Message List View

/// Scrollable chat message list with automatic bottom-anchoring.
///
/// ## Best Practices
///
/// ### 1. Use List instead of ScrollView + LazyVStack
/// LazyVStack causes infinite layout calculation loops during frequent updates, CPU 100%.
///
/// ### 2. Throttled auto-scroll keeps the latest message visible
/// When `messages.count` changes, the list scrolls to the bottom anchor.
/// Scrolling is throttled (max once per 400ms) with a 450ms trailing
/// guarantee, preventing jank during fast streaming updates.
///
/// ## Bad Example (causes CPU 100%)
/// ```swift
/// ScrollView {
///     LazyVStack {
///         ForEach(messages) { message in
///             MessageBubble(message: message)
///         }
///     }
/// }
/// ```
///
/// ## Correct Example
/// ```swift
/// SWMessageList(messages: messages) { message in
///     MessageBubble(message: message)
/// }
/// ```
public struct SWMessageList<Message: Identifiable, Content: View>: View {
    let messages: [Message]
    let content: (Message) -> Content

    // Throttle state for auto-scroll
    @State private var lastScrollTime: Date = .distantPast
    @State private var trailingScrollTask: Task<Void, Never>?

    /// Initialize the message list
    /// - Parameters:
    ///   - messages: Array of messages (in chronological order, oldest first, newest last)
    ///   - content: Message view builder
    public init(
        messages: [Message],
        @ViewBuilder content: @escaping (Message) -> Content
    ) {
        self.messages = messages
        self.content = content
    }

    public var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(messages) { message in
                    content(message)
                        .id(message.id)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .selectionDisabled()
                        #if os(iOS)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        #else
                        .listRowInsets(EdgeInsets(top: 4, leading: 160, bottom: 4, trailing: 160))
                        #endif
                }

                // Bottom anchor — invisible spacer for scroll targeting
                Color.clear
                    .frame(height: 1)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .id("sw-chat-bottom")
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            #if os(iOS)
            .scrollDismissesKeyboard(.immediately)
            #endif
            .onChange(of: messages.count) {
                throttleScroll(proxy: proxy)
            }
        }
    }

    /// Throttled scroll to bottom anchor.
    ///
    /// - Fires immediately if >= 400ms since last scroll (leading edge).
    /// - Always schedules a 450ms trailing task to guarantee the final
    ///   position is correct after a burst of rapid updates.
    private func throttleScroll(proxy: ScrollViewProxy) {
        let now = Date()
        if now.timeIntervalSince(lastScrollTime) >= 0.4 {
            lastScrollTime = now
            proxy.scrollTo("sw-chat-bottom", anchor: .bottom)
        }

        // Cancel any pending trailing scroll and schedule a new one
        trailingScrollTask?.cancel()
        trailingScrollTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            lastScrollTime = .now
            proxy.scrollTo("sw-chat-bottom", anchor: .bottom)
        }
    }
}

// MARK: - Message Bubble Base

/// Message bubble base view
///
/// Best practices:
/// - Use `.frame(maxWidth: .infinity)` to fix width, avoiding layout calculation loops
/// - Use `.fixedSize(horizontal: false, vertical: true)` to let content adapt vertically
public struct SWMessageBubble<Content: View>: View {
    let isFromUser: Bool
    let content: Content

    public init(isFromUser: Bool, @ViewBuilder content: () -> Content) {
        self.isFromUser = isFromUser
        self.content = content()
    }

    public var body: some View {
        HStack {
            if isFromUser {
                Spacer(minLength: 60)
            }

            content
                .fixedSize(horizontal: false, vertical: true)

            if !isFromUser {
                Spacer(minLength: 60)
            }
        }
        .frame(maxWidth: .infinity, alignment: isFromUser ? .trailing : .leading)
    }
}

// MARK: - Preview

private struct PreviewMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

#Preview("Message List") {
    SWMessageList(messages: [
        PreviewMessage(content: "Hello!", isUser: true),
        PreviewMessage(content: "Hi there! How can I help you today?", isUser: false),
        PreviewMessage(content: "I have a question about SwiftUI performance.", isUser: true),
        PreviewMessage(content: "Sure, I'd be happy to help! What would you like to know about SwiftUI performance optimization?", isUser: false),
        PreviewMessage(content: "Why does my chat view freeze with 100% CPU?", isUser: true),
        PreviewMessage(content: "That's likely caused by using ScrollView + LazyVStack. When messages update frequently during streaming, LazyVStack can enter an infinite layout calculation loop. The solution is to use List instead, which has more stable layout behavior.", isUser: false),
    ]) { message in
        SWMessageBubble(isFromUser: message.isUser) {
            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.accentColor : swMessageBubbleBackground)
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
