//
//  slAlert.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/10.
//  Copyright © 2025 Signer Labs. All rights reserved.
//
//  ============================================================
//  全局 Alert 视图组件
//  ============================================================
//
//  【说明】
//  此文件包含 Alert 的视图实现和 View Extension。
//  管理器位于 slAlertManager.swift，请参考该文件了解完整使用方法。
//
//  【快速使用】
//  1. App 入口添加 modifier:
//     ContentView().slAlert()
//
//  2. 显示 Alert:
//     slAlertManager.shared.show(.success, message: "保存成功")
//     slAlertManager.shared.show(.error, message: error.localizedDescription)
//
//  3. 手动关闭:
//     slAlertManager.shared.dismiss()
//
//  【国际化】
//  支持 LocalizedStringKey，配合消息枚举使用可自动提取到 String Catalog：
//
//     enum MyAlertMessage {
//         static let saveSuccess: LocalizedStringKey = "保存成功"
//     }
//     slAlertManager.shared.show(.success, message: MyAlertMessage.saveSuccess)
//
//  ============================================================

import SwiftUI

// MARK: - Alert View

private struct slAlertView: View {
    let alertManager = slAlertManager.shared

    var body: some View {
        if alertManager.isShowing {
            HStack(spacing: 8) {
                Image(systemName: alertManager.icon)
                Text(alertManager.message)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(alertManager.textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(alertManager.backgroundStyle)
                    .strokeBorder(alertManager.borderColor, lineWidth: 0.5)
            }
            .transition(.scale.combined(with: .opacity))
            .onTapGesture { alertManager.dismiss() }
        }
    }
}

// MARK: - View Modifier

private struct slAlertModifier: ViewModifier {
    let alertManager = slAlertManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                slAlertView()
                    .padding(.top, 40)
            }
            .animation(.spring(duration: 0.3), value: alertManager.isShowing)
    }
}

// MARK: - View Extension

extension View {
    /// 添加全局 Alert 支持
    ///
    /// 在 App 入口处使用：
    /// ```swift
    /// @main
    /// struct MyApp: App {
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///                 .slAlert()
    ///         }
    ///     }
    /// }
    /// ```
    func slAlert() -> some View {
        modifier(slAlertModifier())
    }
}

// MARK: - Preview

#Preview("Info") {
    Color.gray
        .ignoresSafeArea()
        .slAlert()
        .onAppear {
            slAlertManager.shared.show(.info, message: "这是一条提示信息")
        }
}

#Preview("Success") {
    Color.gray
        .ignoresSafeArea()
        .slAlert()
        .onAppear {
            slAlertManager.shared.show(.success, message: "保存成功")
        }
}

#Preview("Warning") {
    Color.gray
        .ignoresSafeArea()
        .slAlert()
        .onAppear {
            slAlertManager.shared.show(.warning, message: "请先选择一个选项")
        }
}

#Preview("Error") {
    Color.gray
        .ignoresSafeArea()
        .slAlert()
        .onAppear {
            slAlertManager.shared.show(.error, message: "操作失败，请重试")
        }
}
