//
//  slFloatingLabels.swift
//  ShipSwift
//
//  图片浮动标签组件
//  在图片上循环浮现标签，带渐变边框动效，适用于 AI 分析、扫描结果展示等场景
//
//  使用示例:
//  ```
//  slFloatingLabels(
//      image: Image(.photo),
//      labels: [
//          ("Teeth mapping", CGPoint(x: 0.3, y: 0.5)),
//          ("Plaque detection", CGPoint(x: 0.7, y: 0.6))
//      ]
//  )
//
//  slFloatingLabels(
//      image: Image(.photo),
//      size: 300,
//      cornerRadius: 16,
//      cycleDuration: 4.0,
//      labels: [("Label", CGPoint(x: 0.5, y: 0.5))]
//  )
//  ```
//
//  参数说明:
//  - image: 要显示的图片
//  - size: 图片尺寸，默认 360
//  - cornerRadius: 圆角半径，默认 24
//  - cycleDuration: 动画循环周期（秒），默认 3.0
//  - labels: 标签数组，每个标签包含文字和相对位置 (0-1)
//

import SwiftUI

struct slFloatingLabels: View {
    let image: Image
    var size: CGFloat = 360
    var cornerRadius: CGFloat = 24
    var cycleDuration: Double = 3.0
    var labels: [(String, CGPoint)] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let cycle = t.truncatingRemainder(dividingBy: cycleDuration)

            ZStack {
                // 图片 + 渐变边框
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.8), .blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .opacity(cycle < 0.5 ? cycle * 2 : 1)
                    )

                // 循环显示标签
                ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                    let delay = Double(index) * 0.3
                    let labelCycle = (cycle - delay).truncatingRemainder(dividingBy: cycleDuration)
                    let opacity = labelCycle > 0.5 && labelCycle < (cycleDuration - 0.5) ? 1.0 : 0.0

                    slFloatingLabel(text: label.0)
                        .offset(
                            x: (label.1.x - 0.5) * (size * 0.78),
                            y: (label.1.y - 0.5) * (size * 0.78)
                        )
                        .opacity(opacity)
                        .scaleEffect(opacity > 0 ? 1 : 0.8)
                        .animation(.easeInOut(duration: 0.3), value: opacity)
                }
            }
        }
    }
}

// MARK: - 浮动标签

struct slFloatingLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
    }
}

// MARK: - Preview

#Preview {
    slFloatingLabels(
        image: Image(systemName: "face.smiling"),
        labels: [
            ("Teeth mapping", CGPoint(x: 0.3, y: 0.5)),
            ("Plaque detection", CGPoint(x: 0.9, y: 0.6)),
            ("Shape & balance", CGPoint(x: 0.5, y: 0.8))
        ]
    )
    .padding()
    .background(Color.black)
}
