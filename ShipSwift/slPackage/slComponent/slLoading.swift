//
//  slLoading.swift
//  ShipSwift
//
//  Created by Claude on 2026/1/5.
//  Copyright © 2026 Signer Labs. All rights reserved.
//
//  ============================================================
//  全局 Loading 视图组件
//  ============================================================
//
//  【说明】
//  此文件包含 Loading 的视图实现和 View Extension。
//  管理器位于 slLoadingManager.swift，请参考该文件了解完整使用方法。
//
//  【快速使用】
//  1. App 入口: .slLoading()
//  2. 显示: slLoadingManager.shared.show(message: "...")
//  3. 隐藏: slLoadingManager.shared.hide()
//
//  ============================================================

import SwiftUI

// MARK: - Loading View

private struct slLoadingView: View {
    let loadingManager = slLoadingManager.shared

    var body: some View {
        if loadingManager.isShowing {
            ZStack {
                // 背景遮罩
                Color.black.opacity(0.3)
                    .ignoresSafeArea(.all)

                // Loading 内容
                VStack(spacing: 16) {
                    if let systemImage = loadingManager.systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                    }

                    ProgressView()
                        .scaleEffect(1.2)

                    Text(loadingManager.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
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
            .animation(.easeInOut(duration: 0.2), value: loadingManager.isShowing)
    }
}

// MARK: - View Extension

extension View {
    /// 添加全局 Loading 支持
    func slLoading() -> some View {
        modifier(slLoadingModifier())
    }
}

// MARK: - Preview

#Preview("Loading") {
    Text("Content")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.2))
        .slLoading()
        .onAppear {
            slLoadingManager.shared.show(message: "数据加载中，请稍等...")
        }
}

#Preview("Loading with Icon") {
    Text("Content")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.2))
        .slLoading()
        .onAppear {
            slLoadingManager.shared.show(
                message: "正在同步数据...",
                systemImage: "arrow.triangle.2.circlepath"
            )
        }
}
