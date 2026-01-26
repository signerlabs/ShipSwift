//
//  slRotatingQuote.swift
//  ShipSwift
//
//  通用的旋转引用文本组件
//  使用隐藏占位文本确保高度稳定，防止文本切换时布局跳动
//
//  Created by Claude on 2026/1/26.
//

import SwiftUI

/// 旋转显示多条引用文本的组件，支持自定义作者和旋转间隔
struct slRotatingQuote: View {

    // MARK: - 配置

    /// 引用文本数组
    let quotes: [LocalizedStringResource]

    /// 作者名称（显示在右下角）
    let author: LocalizedStringResource

    /// 文本旋转间隔（秒）
    let interval: TimeInterval

    /// 文本字体
    let quoteFont: Font

    /// 作者字体
    let authorFont: Font

    /// 字体设计
    let fontDesign: Font.Design

    /// 文本颜色
    let foregroundStyle: Color

    // MARK: - 状态

    @State private var currentTextIndex = 0
    @State private var textRotationTimer: Timer?

    // MARK: - 初始化

    /// 创建一个旋转引用文本组件
    /// - Parameters:
    ///   - quotes: 引用文本数组（至少包含 1 条）
    ///   - author: 作者名称
    ///   - interval: 文本旋转间隔，默认 5 秒
    ///   - quoteFont: 引用文本字体，默认 .subheadline
    ///   - authorFont: 作者字体，默认 .headline
    ///   - fontDesign: 字体设计，默认 .rounded
    ///   - foregroundStyle: 文本颜色，默认 .secondary
    init(
        quotes: [LocalizedStringResource],
        author: LocalizedStringResource,
        interval: TimeInterval = 5.0,
        quoteFont: Font = .subheadline,
        authorFont: Font = .headline,
        fontDesign: Font.Design = .rounded,
        foregroundStyle: Color = .secondary
    ) {
        self.quotes = quotes
        self.author = author
        self.interval = interval
        self.quoteFont = quoteFont
        self.authorFont = authorFont
        self.fontDesign = fontDesign
        self.foregroundStyle = foregroundStyle
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 隐藏的占位文本，使用最长的 quote 来确定高度
            VStack(alignment: .leading) {
                Text(longestQuote)
                    .font(quoteFont)
                    .contentTransition(.numericText())

                Spacer()

                HStack {
                    Spacer()

                    Text(author)
                        .font(authorFont)
                }
            }
            .opacity(0)

            // 实际显示的内容
            VStack(alignment: .leading) {
                Text(quotes[safe: currentTextIndex] ?? quotes[0])
                    .font(quoteFont)
                    .contentTransition(.numericText())

                Spacer()

                HStack {
                    Spacer()

                    Text(author)
                        .font(authorFont)
                }
            }
            .foregroundStyle(foregroundStyle)
        }
        .fontDesign(fontDesign)
        .onAppear { startTextRotation() }
        .onDisappear { stopTextRotation() }
    }

    // MARK: - 辅助属性

    /// 找到最长的引用文本（用于占位）
    private var longestQuote: LocalizedStringResource {
        quotes.max { quote1, quote2 in
            String(localized: quote1).count < String(localized: quote2).count
        } ?? quotes[0]
    }

    // MARK: - Timer 管理

    private func startTextRotation() {
        // 如果只有一条文本，不需要旋转
        guard quotes.count > 1 else { return }

        // 停止之前的 timer
        textRotationTimer?.invalidate()

        textRotationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                withAnimation {
                    let maxIndex = quotes.count - 1
                    currentTextIndex = (currentTextIndex + 1) % (maxIndex + 1)
                }
            }
        }
    }

    private func stopTextRotation() {
        textRotationTimer?.invalidate()
        textRotationTimer = nil
    }
}

// MARK: - Array 安全访问扩展

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview("多条引用") {
    List {
        Section {
            slRotatingQuote(
                quotes: [
                    "Those times when you get up early, and you work hard, those times when you stay up late, and you work hard.",
                    "Those times when you don't feel like working, you're too tired, you don't want to push yourself, but you do it anyway.",
                    "That is actually the dream.\n It's not the destination, it's the journey."
                ],
                author: "Kobe Bryant"
            )
        }
        .listRowBackground(Color.clear)
    }
}

#Preview("单条引用") {
    List {
        Section {
            slRotatingQuote(
                quotes: [
                    "Stay hungry, stay foolish."
                ],
                author: "Steve Jobs",
                quoteFont: .title3,
                authorFont: .title2
            )
        }
        .listRowBackground(Color.clear)
    }
}

#Preview("自定义样式") {
    List {
        Section {
            slRotatingQuote(
                quotes: [
                    "The only way to do great work is to love what you do.",
                    "Innovation distinguishes between a leader and a follower.",
                    "Your time is limited, don't waste it living someone else's life."
                ],
                author: "Steve Jobs",
                interval: 3.0,
                quoteFont: .body,
                authorFont: .callout,
                fontDesign: .serif,
                foregroundStyle: .primary
            )
        }
        .listRowBackground(Color.clear)
    }
}
