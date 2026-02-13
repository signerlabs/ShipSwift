//
//  SWRingChart.swift
//  ShipSwift
//
//  Nested concentric ring progress chart (Apple Watch Activity Rings style).
//  Each ring animates from 0 to its target value on appear. Includes a bottom legend
//  with colored bullet points. Supports optional center content via generic ViewBuilder.
//
//  Usage:
//    // Basic usage (no center content)
//    SWRingChart(data: [
//        .init(label: "Partner", value: 80, color: .accentColor),
//        .init(label: "Family", value: 91, color: .green),
//        .init(label: "Social", value: 63, color: .orange)
//    ])
//    .padding()
//
//    // With custom center content
//    SWRingChart(data: [
//        .init(label: "Move", value: 75, color: .red),
//        .init(label: "Exercise", value: 50, color: .green),
//        .init(label: "Stand", value: 90, color: .cyan)
//    ]) {
//        VStack {
//            Image(systemName: "flame.fill")
//            Text("Activity")
//        }
//    }
//
//    // Custom dimensions
//    SWRingChart(
//        data: ringData,
//        maxValue: 200,
//        size: 300,
//        ringWidth: 30,
//        spacing: 12
//    )
//
//  Data Model (built-in):
//    SWRingChart.DataPoint
//      - label: String    // Legend label
//      - value: Double    // Progress value (0 to maxValue)
//      - color: Color     // Ring color
//
//  Parameters:
//    - data: [DataPoint]              -- Array of ring data (first element is the outermost ring)
//    - maxValue: Double               -- Maximum value for the ring scale (default 100)
//    - size: CGFloat                  -- Overall chart size (default 250)
//    - ringWidth: CGFloat             -- Width of each ring stroke (default 25)
//    - spacing: CGFloat               -- Spacing between concentric rings (default 10)
//    - center: () -> Center           -- Optional center content (default EmptyView)
//
//  Notes:
//    - Appear animation is easeOut 1.2 seconds, triggered after a 0.2 second delay
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWRingChart<Center: View>: View {
    // MARK: - Built-in Data Model

    /// Ring data point
    struct DataPoint: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let color: Color
    }

    // MARK: - Properties

    /// Array of ring data (first element is the outermost ring)
    let data: [DataPoint]

    /// Maximum value for the ring scale
    var maxValue: Double = 100

    /// Overall chart size
    var size: CGFloat = 250

    /// Width of each ring stroke
    var ringWidth: CGFloat = 25

    /// Spacing between concentric rings
    var spacing: CGFloat = 10

    /// Optional center content
    @ViewBuilder let center: () -> Center

    @State private var animatedValues: [Double]

    // MARK: - Initializer

    /// Create a ring chart with optional center content
    /// - Parameters:
    ///   - data: Array of ring data points
    ///   - maxValue: Maximum value for ring scale (default 100)
    ///   - size: Overall chart size (default 250)
    ///   - ringWidth: Width of each ring stroke (default 25)
    ///   - spacing: Spacing between rings (default 10)
    ///   - center: ViewBuilder closure for center content
    init(
        data: [DataPoint],
        maxValue: Double = 100,
        size: CGFloat = 250,
        ringWidth: CGFloat = 25,
        spacing: CGFloat = 10,
        @ViewBuilder center: @escaping () -> Center
    ) {
        self.data = data
        self.maxValue = maxValue
        self.size = size
        self.ringWidth = ringWidth
        self.spacing = spacing
        self.center = center
        self._animatedValues = State(initialValue: Array(repeating: 0, count: data.count))
    }

    // MARK: - Body

    var body: some View {
        VStack {
            // Nested rings
            ZStack {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    let ringIndex = CGFloat(data.count - 1 - index)
                    let ringSize = size - ringIndex * (ringWidth + spacing) * 2

                    // Background ring (light color)
                    Circle()
                        .stroke(
                            item.color.opacity(0.15),
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .frame(width: ringSize, height: ringSize)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: animatedValues[index] / maxValue)
                        .stroke(
                            item.color,
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: ringSize, height: ringSize)
                }

                center()
            }

            // Legend
            HStack(spacing: 20) {
                ForEach(data) { item in
                    BulletPointText(bulletColor: item.color) {
                        Text(item.label)

                        Text("\(Int(item.value))")
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.top)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                for i in data.indices {
                    animatedValues[i] = data[i].value
                }
            }
        }
    }

    // MARK: - Private Components

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
}

// MARK: - Convenience Initializer (No Center Content)

extension SWRingChart where Center == EmptyView {
    /// Create a ring chart without center content
    /// - Parameters:
    ///   - data: Array of ring data points
    ///   - maxValue: Maximum value for ring scale (default 100)
    ///   - size: Overall chart size (default 250)
    ///   - ringWidth: Width of each ring stroke (default 25)
    ///   - spacing: Spacing between rings (default 10)
    init(
        data: [DataPoint],
        maxValue: Double = 100,
        size: CGFloat = 250,
        ringWidth: CGFloat = 25,
        spacing: CGFloat = 10
    ) {
        self.init(
            data: data,
            maxValue: maxValue,
            size: size,
            ringWidth: ringWidth,
            spacing: spacing
        ) {
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Example 1: With center content
        SWRingChart(data: [
            .init(label: "Move", value: 75, color: .red),
            .init(label: "Exercise", value: 50, color: .green),
            .init(label: "Stand", value: 90, color: .cyan)
        ]) {
            VStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
                Text("Activity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Divider()

        // Example 2: Without center content, custom dimensions
        SWRingChart(
            data: [
                .init(label: "Partner", value: 80, color: .accentColor),
                .init(label: "Family", value: 91, color: .green),
                .init(label: "Social", value: 63, color: .orange)
            ],
            size: 200,
            ringWidth: 20,
            spacing: 8
        )
    }
    .padding()
}
