//
//  slRadarChart.swift
//  full-pack
//
//  Created by 仲炜 on 2025/12/14.
//  Copyright © 2025 Signer Labs. All rights reserved.
//

import SwiftUI

struct slRadarChart: View {
    // MARK: - 内置数据模型

    /// 雷达图数据点
    struct DataPoint: Identifiable {
        let id: UUID
        let label: String
        let value: Double

        init(id: UUID = UUID(), label: String, value: Double) {
            self.id = id
            self.label = label
            self.value = value
        }

        var remark: String {
            switch value {
            case 80...: return "很好"
            case 60..<80: return "较好"
            default: return "一般"
            }
        }
    }

    /// 雷达图形状
    private struct RadarShape: Shape {
        let data: [DataPoint]
        var progress: Double
        let maxValue: Double
        let center: CGPoint
        let radius: CGFloat
        let step: Double

        var animatableData: Double {
            get { progress }
            set { progress = newValue }
        }

        func path(in rect: CGRect) -> Path {
            var path = Path()

            for i in data.indices {
                let ratio = (data[i].value / maxValue) * progress
                let angle = step * Double(i) - .pi / 2
                let x = center.x + cos(angle) * radius * ratio
                let y = center.y + sin(angle) * radius * ratio

                if i == data.startIndex {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()

            return path
        }
    }

    /// 带圆点的文本标签
    private struct BulletPointText<Content: View>: View {
        var bulletColor: Color
        @ViewBuilder var content: Content

        var body: some View {
            HStack(spacing: 6) {
                Capsule()
                    .fill(bulletColor)
                    .frame(width: 4, height: 12)

                content
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Properties

    let data: [DataPoint]
    let maxValue: Double

    @State private var progress: Double = 0

    // MARK: - Initializer

    init(data: [DataPoint], maxValue: Double = 100) {
        self.data = data
        self.maxValue = maxValue
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2 * 0.8
            let step = 2 * .pi / Double(data.count)

            ZStack {
                // 绘制背景圆环线
                ForEach([20, 40, 60, 80, 100], id: \.self) { level in
                    Path { path in
                        for i in data.indices {
                            let ratio = Double(level) / maxValue
                            let angle = step * Double(i) - .pi / 2
                            let x = center.x + cos(angle) * radius * ratio
                            let y = center.y + sin(angle) * radius * ratio

                            if i == data.startIndex {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.closeSubpath()
                    }
                    .stroke(
                        Color.secondary.opacity(0.3),
                        style: StrokeStyle(
                            lineWidth: level == 100 ? 1.5 : 1,
                            dash: level == 100 ? [] : [4, 4]
                        )
                    )
                }

                // 绘制从圆心到边角的辐射线
                ForEach(data.indices, id: \.self) { index in
                    Path { path in
                        let angle = step * Double(index) - .pi / 2
                        let endX = center.x + cos(angle) * radius
                        let endY = center.y + sin(angle) * radius

                        path.move(to: center)
                        path.addLine(to: CGPoint(x: endX, y: endY))
                    }
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                }

                // 绘制数据多边形
                RadarShape(data: data, progress: progress, maxValue: maxValue, center: center, radius: radius, step: step)
                    .stroke(Color.accentColor, lineWidth: 2)

                RadarShape(data: data, progress: progress, maxValue: maxValue, center: center, radius: radius, step: step)
                    .fill(Color.accentColor.opacity(0.2))

                // 标签
                ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                    let angle = step * Double(index) - .pi / 2
                    let x = center.x + cos(angle) * radius * 1.3
                    let y = center.y + sin(angle) * radius * 1.3

                    VStack {
                        BulletPointText(bulletColor: .secondary) {
                            Text(point.label)
                        }

                        HStack(spacing: 4) {
                            Text(point.remark)
                                .foregroundStyle(.secondary)
                            Text(point.value, format: .number.precision(.fractionLength(0)))
                                .fontWeight(.semibold)
                        }
                        .font(.footnote)
                    }
                    .position(x: x, y: y)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                progress = 0
                withAnimation(.easeOut(duration: 1.2)) {
                    progress = 1
                }
            }
        }
    }
}

#Preview {
    slRadarChart(data: [
        .init(label: "包容心", value: 75),
        .init(label: "进取心", value: 50),
        .init(label: "敏锐度", value: 50),
        .init(label: "创造力", value: 85),
        .init(label: "稳定性", value: 85)
    ])
    .padding(100)
}
