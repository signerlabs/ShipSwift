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
//     slAlertManager.shared.show(.info, message: "这是一条提示")
//     slAlertManager.shared.show(.success, message: "保存成功")
//     slAlertManager.shared.show(.warning, message: "请注意")
//     slAlertManager.shared.show(.error, message: "操作失败")
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
//  - .info    : 蓝色信息提示
//  - .success : 绿色成功提示
//  - .warning : 橙色警告提示
//  - .error   : 红色错误提示
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
            switch self {
            case .info, .success: AnyShapeStyle(.ultraThinMaterial)
            case .warning: AnyShapeStyle(.ultraThinMaterial)
            case .error: AnyShapeStyle(.ultraThinMaterial)
            }
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
    private(set) var message = ""
    private(set) var textColor = AlertType.info.textColor
    private(set) var backgroundStyle = AlertType.info.backgroundStyle
    private(set) var borderColor = AlertType.info.borderColor
    
    private var dismissTask: Task<Void, Never>?
    
    private init() {}
    
    // MARK: - 公开方法
    
    /// 使用预设类型显示 Alert
    func show(_ type: AlertType, message: String, duration: Duration = .seconds(2)) {
        show(
            icon: type.icon,
            message: message,
            textColor: type.textColor,
            backgroundStyle: type.backgroundStyle,
            borderColor: type.borderColor,
            duration: duration
        )
    }
    
    /// 自定义样式显示 Alert
    func show(
        icon: String,
        message: String,
        textColor: Color = .white,
        backgroundStyle: AnyShapeStyle = AnyShapeStyle(.black),
        borderColor: Color = .secondary,
        duration: Duration = .seconds(2)
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
