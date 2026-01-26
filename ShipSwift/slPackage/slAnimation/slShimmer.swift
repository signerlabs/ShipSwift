//
//  slShimmer.swift
//  ShipSwift
//
//  Created by Claude on 1/16/26.
//

import SwiftUI

// MARK: - slShimmer
/// 高光闪烁效果 Modifier
///
/// 为视图添加从左到右扫过的白色光带动画效果，常用于按钮、卡片等需要吸引用户注意的元素。
///
/// ## 使用方法
///
/// ```swift
/// // 基本用法
/// Button("Scan Today") { }
///     .shimmer()
///
/// // 自定义参数
/// Button("Scan Today") { }
///     .shimmer(duration: 1.5, delay: 2.0)
///
/// // 完整示例
/// Text("Scan Today")
///     .font(.headline)
///     .padding(.horizontal, 24)
///     .padding(.vertical, 12)
///     .foregroundStyle(.white)
///     .background {
///         LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
///     }
///     .clipShape(.capsule)
///     .shimmer(duration: 1.5, delay: 2.0)
/// ```
///
/// ## 参数说明
/// - `duration`: 光带扫过的时间（秒），默认 2.0
/// - `delay`: 每次循环之间的间隔（秒），默认 1.0
///
/// ## 注意事项
/// - 建议在 `.clipShape()` 之后使用，确保光带被正确裁剪
/// - 光带会自动适应视图宽度
/// - 动画会无限循环播放

struct slShimmerModifier: ViewModifier {
    @State private var animate = false

    let duration: Double
    let delay: Double

    init(duration: Double = 2.0, delay: Double = 1.0) {
        self.duration = duration
        self.delay = delay
    }

    // 白色光带渐变
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [
                .clear,
                .clear,
                .white.opacity(0.2),
                .clear,
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let bandWidth = geo.size.width * 0.5
                    gradient
                        .frame(width: bandWidth)
                        // 从左侧完全离开视图开始，到右侧完全离开视图结束
                        .offset(x: animate ? geo.size.width + bandWidth : -bandWidth * 1.5)
                        .animation(
                            .linear(duration: duration)
                            .delay(delay)
                            .repeatForever(autoreverses: false),
                            value: animate
                        )
                }
                .clipped()
            }
            .task {
                // 延迟一帧确保视图完全加载
                try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒
                animate = true
            }
    }
}

// MARK: - View Extension

extension View {
    /// 添加高光闪烁效果
    ///
    /// - Parameters:
    ///   - duration: 光带扫过的时间（秒），默认 2.0
    ///   - delay: 每次循环之间的间隔（秒），默认 1.0
    /// - Returns: 带有闪烁效果的视图
    func shimmer(duration: Double = 2.0, delay: Double = 1.0) -> some View {
        modifier(slShimmerModifier(duration: duration, delay: delay))
    }
}

// MARK: - Preview

#Preview("Button with Shimmer") {
    VStack(spacing: 20) {
        Text("Scan Today")
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background {
                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            .clipShape(.capsule)
            .shimmer(duration: 1.5, delay: 2.0)
    }
    .padding(40)
    .background(Color.gray.opacity(0.2))
}

#Preview("Card with Shimmer") {
    VStack {
        Text("Premium Feature")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
    }
    .frame(width: 200, height: 100)
    .background(Color.indigo)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shimmer(duration: 2.0, delay: 3.0)
    .padding()
}
