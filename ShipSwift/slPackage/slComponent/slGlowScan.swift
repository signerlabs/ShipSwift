//
//  slGlowScan.swift
//  ShipSwift
//
//  发光扫描效果 Modifier
//  为视图添加从左到右扫过的发光带动画效果，光带会"穿过"内容本身。
//  与 shimmer 不同，这个效果更强烈，适合需要强调的文字或图标。
//
//  使用示例:
//  ```
//  // 基本用法
//  Text("Start Scan")
//      .glowScan()
//
//  // 自定义参数
//  Text("Analyzing...")
//      .glowScan(baseColor: .blue, duration: 1.5, bandWidth: 100)
//
//  // 应用于图片
//  Image(systemName: "waveform")
//      .glowScan()
//  ```
//
//  参数说明:
//  - baseColor: 基础颜色（非高光部分），默认 `.gray`
//  - glowColor: 高光颜色，默认 `.white`
//  - duration: 光带扫过的时间（秒），默认 2.0
//  - bandWidth: 光带宽度，默认 150
//

import SwiftUI

// MARK: - slGlowScanModifier

struct slGlowScanModifier: ViewModifier {
    @State private var animate = false

    let baseColor: Color
    let glowColor: Color
    let duration: Double
    let bandWidth: CGFloat

    init(
        baseColor: Color = .gray,
        glowColor: Color = .white,
        duration: Double = 2.0,
        bandWidth: CGFloat = 150
    ) {
        self.baseColor = baseColor
        self.glowColor = glowColor
        self.duration = duration
        self.bandWidth = bandWidth
    }

    func body(content: Content) -> some View {
        content
            .hidden()
            .overlay {
                GeometryReader { geo in
                    let totalWidth = geo.size.width

                    Rectangle()
                        .fill(baseColor)
                        .overlay {
                            LinearGradient(
                                colors: [.clear, glowColor, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: bandWidth)
                            .offset(x: animate ? totalWidth / 2 + bandWidth : -totalWidth / 2 - bandWidth)
                        }
                        .animation(
                            .linear(duration: duration)
                            .repeatForever(autoreverses: false),
                            value: animate
                        )
                        .mask { content }
                }
            }
            .onAppear {
                animate = true
            }
    }
}

// MARK: - View Extension

extension View {
    /// 发光扫描效果
    /// - Parameters:
    ///   - baseColor: 基础颜色，默认 `.gray`
    ///   - glowColor: 高光颜色，默认 `.white`
    ///   - duration: 扫描周期（秒），默认 2.0
    ///   - bandWidth: 光带宽度，默认 150
    func glowScan(
        baseColor: Color = .gray,
        glowColor: Color = .white,
        duration: Double = 2.0,
        bandWidth: CGFloat = 150
    ) -> some View {
        modifier(slGlowScanModifier(
            baseColor: baseColor,
            glowColor: glowColor,
            duration: duration,
            bandWidth: bandWidth
        ))
    }
}

// MARK: - Preview

#Preview("Text") {
    Text("Start Scan Today")
        .font(.largeTitle.bold())
        .glowScan()
}

#Preview("Icon") {
    Image(systemName: "waveform.circle.fill")
        .font(.system(size: 80))
        .glowScan(baseColor: .blue.opacity(0.6), glowColor: .cyan)
}

#Preview("Custom Colors") {
    VStack(spacing: 20) {
        Text("Analyzing...")
            .font(.title2.bold())
            .glowScan(baseColor: .accentColor, glowColor: .white, duration: 1.5)

        Text("Processing")
            .font(.headline)
            .glowScan(baseColor: .green.opacity(0.7), glowColor: .mint)
    }
}
