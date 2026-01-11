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
//    content.slSmallCard(strokeColor: .gray, background: .white)
//    content.slBigCard(strokeColor: .gray, background: .white)
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
//   Text("内容").slSmallCard()
//   Text("内容").slBigCard()

extension View {
    /// 小卡片样式 (cornerRadius: 16, padding: 16, strokeWidth: 1)
    func slSmallCard(strokeColor: Color, background: Color) -> some View {
        self
            .safeAreaPadding()
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [strokeColor, strokeColor, strokeColor, strokeColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
    }

    /// 大卡片样式
    func slBigCard(strokeColor: Color, background: Color) -> some View {
        self
            .safeAreaPadding()
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                strokeColor,
                                strokeColor,
                                strokeColor,
                                strokeColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}
