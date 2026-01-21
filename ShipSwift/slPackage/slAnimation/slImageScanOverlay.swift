//
//  slImageScanOverlay.swift
//  ShipSwift
//
//  扫描动画 Overlay - 可叠加在任意图片上
//
//  使用示例：
//  ```swift
//  Image(uiImage: someImage)
//      .resizable()
//      .scaledToFit()
//      .overlay {
//          slImageScanOverlay()
//      }
//  ```
//

import SwiftUI

/// 图片扫描动画 Overlay
///
/// **特性：**
/// - 动态网格（轻微流动效果）
/// - 从上到下循环扫描的光带
/// - 轻量级噪点效果
/// - 所有参数可自定义
///
/// **性能：**
/// - 使用 Canvas 绘制网格（高性能）
/// - TimelineView 驱动动画（系统优化）
/// - 无额外图片资源
///
struct slImageScanOverlay: View {
    // MARK: - 可调参数

    /// 网格不透明度（0-1）
    var gridOpacity: Double = 0.2

    /// 光带不透明度（0-1）
    var bandOpacity: Double = 0.3

    /// 光带高度占比（相对于图片高度）
    var bandHeightRatio: CGFloat = 0.2

    /// 网格间距（像素）
    var gridSpacing: CGFloat = 16

    /// 扫描速度倍率（1.0 = 正常速度）
    var speed: Double = 2.0

    // MARK: - Body

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    // 1) 动态网格（轻微"流动"）
                    Canvas { ctx, _ in
                        // 通过 phase 做轻微位移 + 波动感
                        let phase = CGFloat(t * 0.8)
                        let dx = sin(phase) * 3
                        let dy = cos(phase * 0.9) * 3

                        var path = Path()
                        let step = max(10, gridSpacing)

                        // 竖线
                        var x: CGFloat = -step
                        while x <= size.width + step {
                            let xx = x + dx + sin((x / 80) + phase) * 1.5
                            path.move(to: CGPoint(x: xx, y: 0))
                            path.addLine(to: CGPoint(x: xx, y: size.height))
                            x += step
                        }

                        // 横线
                        var y: CGFloat = -step
                        while y <= size.height + step {
                            let yy = y + dy + cos((y / 80) + phase) * 1.5
                            path.move(to: CGPoint(x: 0, y: yy))
                            path.addLine(to: CGPoint(x: size.width, y: yy))
                            y += step
                        }

                        ctx.stroke(
                            path,
                            with: .color(.white.opacity(gridOpacity)),
                            lineWidth: 1
                        )
                    }
                    .blendMode(.screen)

                    // 2) 扫描光带（从上到下循环）
                    scanBand(size: size, time: t)

                    // 3) 轻量噪点（增加真实感）
                    noiseOverlay(time: t)
                        .opacity(0.06)
                        .blendMode(.overlay)
                }
                .compositingGroup() // 让 blendMode 更稳定
            }
        }
    }

    // MARK: - Private Views

    private func scanBand(size: CGSize, time t: Double) -> some View {
        // 0...1 循环
        let p = CGFloat((t * (0.22 * speed)).truncatingRemainder(dividingBy: 1.0))
        let bandH = size.height * bandHeightRatio
        let y = -bandH + (size.height + bandH * 2) * p

        return ZStack {
            // 主光带：中间亮、上下渐隐
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .white.opacity(bandOpacity * 0.4), location: 0.25),
                            .init(color: .white.opacity(bandOpacity), location: 0.5),
                            .init(color: .white.opacity(bandOpacity * 0.4), location: 0.75),
                            .init(color: .clear, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: bandH)
                .position(x: size.width/2, y: y)
                .blendMode(.screen)

            // 细高光线：增加"扫描仪"味道
            Rectangle()
                .fill(Color.white.opacity(bandOpacity * 0.65))
                .frame(height: 2)
                .position(x: size.width/2, y: y)
                .blur(radius: 0.6)
                .blendMode(.screen)
        }
    }

    private func noiseOverlay(time t: Double) -> some View {
        // 轻量噪点：用渐变 + 相位移动模拟（非常省性能）
        LinearGradient(
            colors: [
                .white.opacity(0.0),
                .white.opacity(1.0),
                .white.opacity(0.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .scaleEffect(1.6)
        .offset(x: sin(t * 0.9) * 20, y: cos(t * 1.1) * 20)
        .blur(radius: 12)
    }
}

// MARK: - Preview

#Preview("基础用法") {
    VStack(spacing: 20) {
        // 示例 1：深色背景图
        Color.blue
            .frame(width: 300, height: 200)
            .overlay {
                slImageScanOverlay()
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

        // 示例 2：自定义参数
        Color.purple
            .frame(width: 300, height: 200)
            .overlay {
                slImageScanOverlay(
                    gridOpacity: 0.3,
                    bandOpacity: 0.5,
                    speed: 3.0
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}

#Preview("实际应用") {
    VStack(spacing: 40) {
        // AI 处理中
        VStack(spacing: 12) {
            Color.gray
                .frame(width: 320, height: 200)
                .overlay {
                    slImageScanOverlay(
                        gridOpacity: 0.2,
                        bandOpacity: 0.35,
                        speed: 2.0
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(spacing: 4) {
                ProgressView(value: 0.6)
                    .frame(width: 200)
                Text("Analyzing image...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }

        // 扫描中
        VStack(spacing: 12) {
            Color.blue.opacity(0.3)
                .frame(width: 320, height: 200)
                .overlay {
                    slImageScanOverlay(
                        gridOpacity: 0.15,
                        bandOpacity: 0.4,
                        bandHeightRatio: 0.15,
                        speed: 2.5
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("Scanning...")
                .font(.headline)
        }
    }
    .padding()
}
