//
//  slMessageList.swift
//  ShipSwift
//
//  消息列表组件 - SwiftUI 最佳实践
//
//  重要：使用 List 而不是 ScrollView + LazyVStack
//  原因：LazyVStack 在频繁更新时会导致布局计算无限循环，CPU 100%
//

import SwiftUI
import UIKit

// MARK: - Message List View

/// 消息列表视图
///
/// 最佳实践：
/// - 使用 `List` 代替 `ScrollView + LazyVStack`，避免布局计算无限循环
/// - 使用 `ScrollViewReader` 实现滚动到底部
/// - 消息气泡使用 `.frame(maxWidth: .infinity)` 固定宽度
/// - 流式回复时使用 `asyncAfter` 延迟 + 动画，避免滚动冲突
///
/// 错误示例（会导致 CPU 100%）：
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
/// 正确示例：
/// ```swift
/// List {
///     ForEach(messages) { message in
///         MessageBubble(message: message)
///             .listRowSeparator(.hidden)
///             .listRowBackground(Color.clear)
///     }
/// }
/// .listStyle(.plain)
/// .scrollContentBackground(.hidden)
/// ```
public struct SLMessageList<Message: Identifiable, Content: View>: View {
    let messages: [Message]
    let isStreaming: Bool
    let lastMessageContent: String?
    let content: (Message) -> Content

    /// 初始化消息列表
    /// - Parameters:
    ///   - messages: 消息数组
    ///   - isStreaming: 是否正在流式输出（用于触发滚动）
    ///   - lastMessageContent: 最后一条消息的内容（用于流式滚动检测）
    ///   - content: 消息视图构建器
    public init(
        messages: [Message],
        isStreaming: Bool = false,
        lastMessageContent: String? = nil,
        @ViewBuilder content: @escaping (Message) -> Content
    ) {
        self.messages = messages
        self.isStreaming = isStreaming
        self.lastMessageContent = lastMessageContent
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
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .defaultScrollAnchor(.bottom)
            .onChange(of: lastMessageContent) {
                // 流式回复时，内容增长触发滚动
                if isStreaming {
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }

    /// 滚动到底部
    ///
    /// 最佳实践：
    /// - 使用 `asyncAfter` 延迟 0.2s，等待渲染完成
    /// - 使用 `withAnimation` 0.3s 平滑滚动
    /// - UI 更新间隔建议 1s，确保动画不冲突
    ///
    /// 时序图：
    /// ```
    /// |--0.2s--|---0.3s 动画---|-------0.5s 空闲-------|
    ///   延迟       滚动动画            等待下次更新
    ///
    /// |<------------------- 1s 更新周期 ----------------->|
    /// ```
    ///
    /// 参考：https://developer.apple.com/forums/thread/735479
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = messages.last else { return }
        // asyncAfter 加延迟，保留动画效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
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
