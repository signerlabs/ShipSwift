//
//  slViewExtension.swift
//  ShipSwift
//
//  视图样式扩展
//
//  Button Style:
//    Button("确认") { }.buttonStyle(.slPrimary)
//    Button("取消") { }.buttonStyle(.slSecondary)
//
//  Card Style:
//    content.slCardStyle()
//    content.slCardStyle(strokeColor: .cyan, cornerRadius: 20, padding: 16)
//

import SwiftUI

// MARK: - Button Style

struct slButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
    }
    
    @Environment(\.isEnabled) private var isEnabled
    
    let variant: Variant
    var showBorder: Bool = false
    var cornerRadius: CGFloat = 16
    
    private var backgroundColor: Color {
        switch variant {
        case .primary: .accent
        case .secondary: .accent.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary: .white
        case .secondary: .primary.opacity(0.8)
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .primary: .primary
        case .secondary: .secondary.opacity(0.8)
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
            .foregroundStyle(foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        showBorder ? borderColor : .clear,
                        lineWidth: 1.5
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.5)
    }
}

extension ButtonStyle where Self == slButtonStyle {
    /// 主要按钮样式（确认/保存等）
    static var slPrimary: slButtonStyle { .init(variant: .primary) }
    /// 次要按钮样式（取消/关闭等）
    static var slSecondary: slButtonStyle { .init(variant: .secondary) }
    
    static func slPrimary(showBorder: Bool = true, cornerRadius: CGFloat = 12) -> slButtonStyle {
        .init(variant: .primary, showBorder: showBorder, cornerRadius: cornerRadius)
    }
    
    static func slSecondary(showBorder: Bool = true, cornerRadius: CGFloat = 12) -> slButtonStyle {
        .init(variant: .secondary, showBorder: showBorder, cornerRadius: cornerRadius)
    }
}

// MARK: - Card Style
// 使用方式:
//   Text("内容").slCardStyle()
//   Text("内容").slCardStyle(strokeColor: .cyan, cornerRadius: 20)

extension View {
    /// 卡片样式
    /// - Parameters:
    ///   - strokeColor: 边框渐变起始颜色
    ///   - background: 背景颜色
    ///   - cornerRadius: 圆角半径
    ///   - padding: 内边距
    ///   - strokeWidth: 边框宽度
    func slCardStyle(
        strokeColor: Color = .accentColor,
        background: Color = .white.opacity(0.1),
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        strokeWidth: CGFloat = 0.6
    ) -> some View {
        self
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                strokeColor,
                                strokeColor.opacity(0.6),
                                strokeColor.opacity(0.3),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: strokeWidth
                    )
            )
    }
}

// MARK: - Preview

#Preview("Button Styles") {
    VStack(spacing: 20) {
        Button("Primary Button") { }
            .buttonStyle(.slPrimary)

        Button("Secondary Button") { }
            .buttonStyle(.slSecondary)

        Button("Disabled") { }
            .buttonStyle(.slPrimary)
            .disabled(true)
    }
    .padding()
}

#Preview("Card Styles") {
    VStack(spacing: 20) {
        VStack {
            ForEach(0..<3, id: \.self) { _ in
                Text("Default Card")
            }
        }
        .frame(maxWidth: .infinity)
        .slCardStyle()

        VStack {
            ForEach(0..<3, id: \.self) { _ in
                Text("Custom Card")
            }
        }
        .frame(maxWidth: .infinity)
        .slCardStyle(strokeColor: .cyan, cornerRadius: 24, padding: 24)
    }
    .padding()
}
