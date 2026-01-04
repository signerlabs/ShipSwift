//
//  slLoadingManager.swift
//  ShipSwift
//
//  Created by Claude on 2026/1/5.
//  Copyright © 2026 Signer Labs. All rights reserved.
//
//  ============================================================
//  全局 Loading 管理器
//  ============================================================
//
//  【功能说明】
//  用于在 App 任意位置显示全屏 Loading 遮罩，覆盖 NavigationBar 和 TabBar。
//
//  【使用步骤】
//  1. 在 App 入口添加 .slLoading() modifier:
//
//     @main
//     struct MyApp: App {
//         var body: some Scene {
//             WindowGroup {
//                 ContentView()
//                     .slLoading()  // 添加全局 Loading 支持
//             }
//         }
//     }
//
//  2. 在任意位置调用:
//
//     // 显示 Loading
//     slLoadingManager.shared.show(message: "加载中...")
//
//     // 显示带图标的 Loading
//     slLoadingManager.shared.show(message: "同步中...", systemImage: "arrow.triangle.2.circlepath")
//
//     // 动态更新消息
//     slLoadingManager.shared.updateMessage("处理中...")
//
//     // 隐藏 Loading
//     slLoadingManager.shared.hide()
//
//  【典型使用场景】
//
//     func fetchData() async {
//         slLoadingManager.shared.show(message: "数据加载中...")
//         defer { slLoadingManager.shared.hide() }
//
//         do {
//             let data = try await api.fetchData()
//             // 处理数据...
//         } catch {
//             slAlertManager.shared.show(.error, message: error.localizedDescription)
//         }
//     }
//
//  ============================================================

import SwiftUI

@MainActor
@Observable
final class slLoadingManager {
    static let shared = slLoadingManager()

    // MARK: - 状态

    private(set) var isShowing = false
    private(set) var message = "加载中..."
    private(set) var systemImage: String? = nil

    private init() {}

    // MARK: - 公开方法

    /// 显示 Loading（使用系统图标）
    func show(message: String = "加载中...", systemImage: String? = nil) {
        self.message = message
        self.systemImage = systemImage
        withAnimation(.easeInOut(duration: 0.2)) {
            isShowing = true
        }
    }

    /// 更新 Loading 消息
    func updateMessage(_ message: String) {
        self.message = message
    }

    /// 隐藏 Loading
    func hide() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isShowing = false
        }
    }
}
