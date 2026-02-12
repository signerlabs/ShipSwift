//
//  SWRadarChart.swift
//  ShipSwift
//
//  Copyright © 2025 Signer Labs. All rights reserved.
//

import SwiftUI

struct SWRadarChart: View {
    // MARK: - Built-in Data Models

    /// Radar chart data point
    struct DataPoint: Identifiable {
        let id: UUID
        let label: String
        let value: Double

        init(id: UUID = UUID(), label: String, value: Double) {
            self.id = id
            self.label = label
            self.value = value
        }
    }

    /// Radar chart shape
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

    /// Text label with bullet point
    private struct BulletPointText<Content: View>: View {
        var bulletColor: Color
        @ViewBuilder var content: Content

        var body: some View {
            HStack(spacing: 4) {
                Capsule()
                    .fill(bulletColor)
                    .frame(width: 3, height: 10)

                content
                    .font(.caption)
            }
        }
    }

    // MARK: - Properties

    let data: [DataPoint]
    let maxValue: Double
    let showLabels: Bool

    @State private var progress: Double = 0

    // MARK: - Initializer

    init(data: [DataPoint], maxValue: Double = 100, showLabels: Bool = true) {
        self.data = data
        self.maxValue = maxValue
        self.showLabels = showLabels
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            // When showLabels is true, shrink the chart so labels (1.3x) stay within bounds:
            // 0.55 * 1.3 = 0.715, leaving space for text within the radius range
            let radiusFactor: CGFloat = showLabels ? 0.55 : 0.8
            let radius = size / 2 * radiusFactor
            let step = 2 * .pi / Double(data.count)

            ZStack {
                // Draw background ring lines
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

                // Draw radial lines from center to corners
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

                // Draw data polygon
                RadarShape(data: data, progress: progress, maxValue: maxValue, center: center, radius: radius, step: step)
                    .stroke(Color.accentColor, lineWidth: 2)

                RadarShape(data: data, progress: progress, maxValue: maxValue, center: center, radius: radius, step: step)
                    .fill(Color.accentColor.opacity(0.2))

                // Labels
                if showLabels {
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                        let angle = step * Double(index) - .pi / 2
                        let x = center.x + cos(angle) * radius * 1.3
                        let y = center.y + sin(angle) * radius * 1.3

                        VStack {
                            BulletPointText(bulletColor: .secondary) {
                                Text(point.label)
                            }

                            Text(point.value, format: .number.precision(.fractionLength(0)))
                                .fontWeight(.semibold)
                                .font(.footnote)
                        }
                        .position(x: x, y: y)
                    }
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
    SWRadarChart(data: [
        .init(label: "Tolerance", value: 75),
        .init(label: "Ambition", value: 50),
        .init(label: "Acuity", value: 50),
        .init(label: "Creativity", value: 85),
        .init(label: "Stability", value: 85)
    ])
    .padding(100)
}
