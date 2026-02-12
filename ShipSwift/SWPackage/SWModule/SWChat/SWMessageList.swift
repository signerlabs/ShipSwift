//
//  SWMessageList.swift
//  ShipSwift
//
//  Scrollable chat message list with bubble styling.
//  Uses the flip technique (industry standard for chat apps) to anchor
//  scroll position at the bottom. Avoids ScrollView + LazyVStack which
//  causes 100% CPU from infinite layout loops during streaming updates.
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
//    // 4. The .swFlipped() modifier is available for manual implementations
//    //    if you need custom List behavior (see doc comments in source).
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI
import UIKit

// MARK: - Flip Modifier

extension View {
    /// Flips the view to display the chat list starting from the bottom
    ///
    /// How it works:
    /// 1. Flip the entire List -> the original top becomes the bottom
    /// 2. Flip each item -> content direction is restored
    /// 3. Reverse the message array -> newest messages appear at the bottom
    ///
    /// Reference: https://www.swiftwithvincent.com/blog/building-the-inverted-scroll-of-a-messaging-app
    func swFlipped() -> some View {
        rotationEffect(.radians(.pi))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

// MARK: - Message List View

/// Message list view
///
/// ## Best Practices
///
/// ### 1. Use List instead of ScrollView + LazyVStack
/// LazyVStack causes infinite layout calculation loops during frequent updates, CPU 100%
///
/// ### 2. Use flip technique to start from the bottom
/// `defaultScrollAnchor(.bottom)` is unreliable with List's lazy rendering.
/// The flip technique is the industry standard for chat apps (Messages, WhatsApp, etc.)
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
///
/// ## Manual Implementation (without the component)
/// ```swift
/// List {
///     ForEach(messages.reversed()) { message in
///         MessageBubble(message: message)
///             .swFlipped()  // Flip each item
///             .listRowSeparator(.hidden)
///             .listRowBackground(Color.clear)
///     }
/// }
/// .listStyle(.plain)
/// .scrollContentBackground(.hidden)
/// .swFlipped()  // Flip the entire List
/// ```
public struct SWMessageList<Message: Identifiable, Content: View>: View {
    let messages: [Message]
    let content: (Message) -> Content

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
        List {
            ForEach(messages.reversed()) { message in
                content(message)
                    .swFlipped()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .swFlipped()
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
                .background(message.isUser ? Color.accentColor : Color(UIColor.systemGray6))
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
