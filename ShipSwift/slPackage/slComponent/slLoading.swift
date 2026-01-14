//
//  slLoading.swift
//  ShipSwift
//
//  Created by Claude on 2026/1/5.
//  Copyright © 2026 Signer Labs. All rights reserved.
//
//  ============================================================
//  全局 Loading 视图组件 - 全屏毛玻璃覆盖样式
//  ============================================================
//
//  【说明】
//  此文件包含 Loading 的视图实现和 View Extension。
//  管理器位于 slLoadingManager.swift，请参考该文件了解完整使用方法。
//
//  【快速使用】
//  1. App 入口: .slLoading()
//  2. 显示: slLoadingManager.shared.show(message: "...", systemImage: "...")
//  3. 隐藏: slLoadingManager.shared.hide()
//
//  ============================================================

import SwiftUI

// MARK: - Loading View

private struct slLoadingView: View {
    let loadingManager = slLoadingManager.shared

    var body: some View {
        if loadingManager.isShowing {
            // 全屏毛玻璃覆盖
            VStack(spacing: 24) {
                // Icon
                if let systemImage = loadingManager.systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.primary.opacity(0.8))
                        .symbolEffect(.pulse, options: .repeating)
                }

                // 文案 + 加载指示器
                VStack(spacing: 12) {
                    Text(loadingManager.message)
                        .font(.headline)
                        .foregroundStyle(.primary.opacity(0.9))
                        .multilineTextAlignment(.center)

                    ProgressView()
                        .tint(.primary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThinMaterial)
            .ignoresSafeArea(.all)
            .transition(.opacity)
        }
    }
}

// MARK: - View Modifier

private struct slLoadingModifier: ViewModifier {
    let loadingManager = slLoadingManager.shared

    func body(content: Content) -> some View {
        content
            .overlay {
                slLoadingView()
            }
            .animation(.easeInOut(duration: 0.25), value: loadingManager.isShowing)
    }
}

// MARK: - View Extension

extension View {
    /// 添加全局 Loading 支持（全屏毛玻璃覆盖）
    func slLoading() -> some View {
        modifier(slLoadingModifier())
    }
}

// MARK: - Preview

#Preview("Loading - 全屏毛玻璃") {
    ZStack {
        // 模拟页面内容
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        VStack {
            Text("页面内容")
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
    }
    .slLoading()
    .onAppear {
        slLoadingManager.shared.show(
            message: "数据加载中...",
            systemImage: "arrow.down.circle"
        )
    }
}

#Preview("Loading - 同步数据") {
    ZStack {
        Color.gray.opacity(0.2)
        Text("Content")
    }
    .slLoading()
    .onAppear {
        slLoadingManager.shared.show(
            message: "正在同步数据，请稍候",
            systemImage: "arrow.triangle.2.circlepath"
        )
    }
}

#Preview("Loading - AI 分析") {
    ZStack {
        Color.gray.opacity(0.2)
        Text("Content")
    }
    .slLoading()
    .onAppear {
        slLoadingManager.shared.show(
            message: "AI 分析中...",
            systemImage: "sparkles"
        )
    }
}
