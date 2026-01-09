//
//  slAlertManager.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/10.
//  Copyright © 2025 Signer Labs. All rights reserved.
//
//  ============================================================
//  全局 Alert 管理器
//  ============================================================
//
//  【功能说明】
//  用于在 App 任意位置显示顶部 Toast 提示，自动消失。
//  支持 String 和 LocalizedStringKey，便于国际化。
//
//  【使用步骤】
//  1. 在 App 入口添加 .slAlert() modifier:
//
//     @main
//     struct MyApp: App {
//         var body: some Scene {
//             WindowGroup {
//                 ContentView()
//                     .slAlert()  // 添加全局 Alert 支持
//             }
//         }
//     }
//
//  2. 在任意位置调用:
//
//     // 使用预设类型（推荐）
//     slAlertManager.shared.show(.success, message: "保存成功")
//     slAlertManager.shared.show(.error, message: "操作失败")
//
//     // 支持 LocalizedStringKey（推荐用于静态文本，自动提取到 String Catalog）
//     slAlertManager.shared.show(.success, message: MyAlertMessage.saveSuccess)
//
//     // 自定义样式
//     slAlertManager.shared.show(
//         icon: "star.fill",
//         message: "自定义消息",
//         textColor: .yellow,
//         duration: .seconds(3)
//     )
//
//     // 手动关闭
//     slAlertManager.shared.dismiss()
//
//  【预设类型】
//  - .info    : 信息提示（主色调）
//  - .success : 绿色成功提示
//  - .warning : 橙色警告提示
//  - .error   : 红色错误提示
//
//  【国际化最佳实践】
//  为了让 Xcode String Catalog 自动提取字符串，建议在项目中创建消息枚举：
//
//     enum MyAlertMessage {
//         static let saveSuccess: LocalizedStringKey = "保存成功"
//         static let saveFailed: LocalizedStringKey = "保存失败"
//     }
//
//     // 调用时使用枚举常量
//     slAlertManager.shared.show(.success, message: MyAlertMessage.saveSuccess)
//
//  ============================================================

import SwiftUI

@MainActor
@Observable
final class slAlertManager {
    static let shared = slAlertManager()

    // MARK: - Alert 类型

    enum AlertType {
        case info
        case success
        case warning
        case error

        var icon: String {
            switch self {
            case .info: "info.circle.fill"
            case .success: "checkmark.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .error: "xmark.circle.fill"
            }
        }

        var textColor: Color {
            switch self {
            case .info: .primary
            case .success: .green
            case .warning: .orange
            case .error: .red
            }
        }

        var backgroundStyle: AnyShapeStyle {
            AnyShapeStyle(.ultraThinMaterial)
        }

        var borderColor: Color {
            switch self {
            case .info: .secondary.opacity(0.6)
            case .success: .green.opacity(0.6)
            case .warning: .orange.opacity(0.6)
            case .error: .red.opacity(0.6)
            }
        }
    }

    // MARK: - 状态

    private(set) var isShowing = false
    private(set) var icon = AlertType.info.icon
    private(set) var message: LocalizedStringKey = ""
    private(set) var textColor = AlertType.info.textColor
    private(set) var backgroundStyle = AlertType.info.backgroundStyle
    private(set) var borderColor = AlertType.info.borderColor

    private var dismissTask: Task<Void, Never>?

    private init() {}

    // MARK: - 公开方法（LocalizedStringKey）

    /// 使用预设类型显示 Alert（LocalizedStringKey，推荐用于静态文本）
    func show(_ type: AlertType, message: LocalizedStringKey, duration: Duration = .seconds(2)) {
        showInternal(
            icon: type.icon,
            message: message,
            textColor: type.textColor,
            backgroundStyle: type.backgroundStyle,
            borderColor: type.borderColor,
            duration: duration
        )
    }

    /// 自定义样式显示 Alert（LocalizedStringKey）
    func show(
        icon: String,
        message: LocalizedStringKey,
        textColor: Color = .white,
        backgroundStyle: AnyShapeStyle = AnyShapeStyle(.black),
        borderColor: Color = .secondary,
        duration: Duration = .seconds(2)
    ) {
        showInternal(
            icon: icon,
            message: message,
            textColor: textColor,
            backgroundStyle: backgroundStyle,
            borderColor: borderColor,
            duration: duration
        )
    }

    // MARK: - 公开方法（String）

    /// 使用预设类型显示 Alert（String，用于动态文本如 API 错误）
    func show(_ type: AlertType, message: String, duration: Duration = .seconds(2)) {
        showInternal(
            icon: type.icon,
            message: LocalizedStringKey(message),
            textColor: type.textColor,
            backgroundStyle: type.backgroundStyle,
            borderColor: type.borderColor,
            duration: duration
        )
    }

    /// 自定义样式显示 Alert（String）
    func show(
        icon: String,
        message: String,
        textColor: Color = .white,
        backgroundStyle: AnyShapeStyle = AnyShapeStyle(.black),
        borderColor: Color = .secondary,
        duration: Duration = .seconds(2)
    ) {
        showInternal(
            icon: icon,
            message: LocalizedStringKey(message),
            textColor: textColor,
            backgroundStyle: backgroundStyle,
            borderColor: borderColor,
            duration: duration
        )
    }

    // MARK: - 内部方法

    private func showInternal(
        icon: String,
        message: LocalizedStringKey,
        textColor: Color,
        backgroundStyle: AnyShapeStyle,
        borderColor: Color,
        duration: Duration
    ) {
        dismissTask?.cancel()

        self.icon = icon
        self.message = message
        self.textColor = textColor
        self.backgroundStyle = backgroundStyle
        self.borderColor = borderColor

        withAnimation { isShowing = true }

        dismissTask = Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            withAnimation { isShowing = false }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation { isShowing = false }
    }
}
