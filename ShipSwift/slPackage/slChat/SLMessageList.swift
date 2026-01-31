//
//  SLMessageList.swift
//  ShipSwift
//
//  消息列表组件 - SwiftUI 最佳实践
//
//  重要：
//  1. 使用 List 而不是 ScrollView + LazyVStack
//     原因：LazyVStack 在频繁更新时会导致布局计算无限循环，CPU 100%
//
//  2. 使用翻转技术实现从底部开始显示
//     原因：defaultScrollAnchor(.bottom) 对 List 的 lazy 渲染不可靠
//     参考：https://www.swiftwithvincent.com/blog/building-the-inverted-scroll-of-a-messaging-app
//

import SwiftUI
import UIKit

// MARK: - 翻转修饰符

extension View {
    /// 翻转视图，用于实现聊天列表从底部开始显示
    ///
    /// 原理：
    /// 1. 翻转整个 List → 原来的顶部变底部
    /// 2. 翻转每个 item → 内容方向恢复正常
    /// 3. 反转消息数组 → 最新消息显示在底部
    ///
    /// 参考：https://www.swiftwithvincent.com/blog/building-the-inverted-scroll-of-a-messaging-app
    func slFlipped() -> some View {
        rotationEffect(.radians(.pi))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

// MARK: - Message List View

/// 消息列表视图
///
/// ## 最佳实践
///
/// ### 1. 使用 List 而不是 ScrollView + LazyVStack
/// LazyVStack 在频繁更新时会导致布局计算无限循环，CPU 100%
///
/// ### 2. 使用翻转技术实现从底部开始
/// `defaultScrollAnchor(.bottom)` 对 List 的 lazy 渲染不可靠，
/// 翻转技术是聊天应用的行业标准做法（Messages、WhatsApp 等）
///
/// ## 错误示例（会导致 CPU 100%）
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
/// ## 正确示例
/// ```swift
/// SLMessageList(messages: messages) { message in
///     MessageBubble(message: message)
/// }
/// ```
///
/// ## 手动实现（不使用组件）
/// ```swift
/// List {
///     ForEach(messages.reversed()) { message in
///         MessageBubble(message: message)
///             .slFlipped()  // 翻转每个 item
///             .listRowSeparator(.hidden)
///             .listRowBackground(Color.clear)
///     }
/// }
/// .listStyle(.plain)
/// .scrollContentBackground(.hidden)
/// .slFlipped()  // 翻转整个 List
/// ```
public struct SLMessageList<Message: Identifiable, Content: View>: View {
    let messages: [Message]
    let content: (Message) -> Content

    /// 初始化消息列表
    /// - Parameters:
    ///   - messages: 消息数组（按时间顺序，最旧在前，最新在后）
    ///   - content: 消息视图构建器
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
                    .slFlipped()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .slFlipped()
    }
}

// MARK: - Message Bubble Base

/// 消息气泡基础视图
///
/// 最佳实践：
/// - 使用 `.frame(maxWidth: .infinity)` 固定宽度，避免布局计算循环
/// - 使用 `.fixedSize(horizontal: false, vertical: true)` 让内容垂直自适应
public struct SLMessageBubble<Content: View>: View {
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
    SLMessageList(messages: [
        PreviewMessage(content: "Hello!", isUser: true),
        PreviewMessage(content: "Hi there! How can I help you today?", isUser: false),
        PreviewMessage(content: "I have a question about SwiftUI performance.", isUser: true),
        PreviewMessage(content: "Sure, I'd be happy to help! What would you like to know about SwiftUI performance optimization?", isUser: false),
        PreviewMessage(content: "Why does my chat view freeze with 100% CPU?", isUser: true),
        PreviewMessage(content: "That's likely caused by using ScrollView + LazyVStack. When messages update frequently during streaming, LazyVStack can enter an infinite layout calculation loop. The solution is to use List instead, which has more stable layout behavior.", isUser: false),
    ]) { message in
        SLMessageBubble(isFromUser: message.isUser) {
            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.accentColor : Color(UIColor.systemGray6))
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
