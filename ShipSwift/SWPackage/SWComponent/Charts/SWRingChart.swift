//
//  SWRingChart.swift
//  ShipSwift
//
//  Nested concentric ring progress chart (Apple Watch Activity Rings style).
//  Each ring animates from 0 to its target value on appear. Includes a bottom legend
//  with colored bullet points using SWBulletPointText.
//
//  Usage:
//    SWRingChart(data: [
//        RingData(label: "Partner", value: 80, color: .accentColor),
//        RingData(label: "Family", value: 91, color: .green),
//        RingData(label: "Social", value: 63, color: .orange)
//    ])
//    .padding()
//
//  Data Model (defined at bottom of file):
//    struct RingData: Identifiable {
//        let label: String   // Legend label
//        let value: Double   // Progress value (0-100)
//        let color: Color    // Ring color
//    }
//
//  Parameters:
//    - data: [RingData] — Array of ring data (first element is the outermost ring)
//
//  Notes:
//    - maxValue is fixed at 100, value represents percentage progress
//    - Ring size (size: 250), width (ringWidth: 25), spacing (spacing: 10) are internal constants
//    - Appear animation is easeOut 1.2 seconds, triggered after a 0.2 second delay
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI
import Charts

struct SWRingChart: View {
    let data: [RingData]
    let maxValue: Double = 100
    let size: CGFloat = 250
    let ringWidth: CGFloat = 25
    let spacing: CGFloat = 10
    @State private var animatedValues: [Double]

    init(data: [RingData]) {
        self.data = data
        self._animatedValues = State(initialValue: Array(repeating: 0, count: data.count))
    }

    var body: some View {
        VStack {
            // Nested rings
            ZStack {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    let ringIndex = CGFloat(data.count - 1 - index)

                    Circle()
                        .trim(from: 0, to: animatedValues[index] / maxValue)
                        .stroke(
                            item.color,
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: size - ringIndex * (ringWidth + spacing) * 2,
                               height: size - ringIndex * (ringWidth + spacing) * 2)

                    // Background ring (light color)
                    Circle()
                        .stroke(
                            item.color.opacity(0.15),
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .frame(width: size - ringIndex * (ringWidth + spacing) * 2,
                               height: size - ringIndex * (ringWidth + spacing) * 2)
                }

                Text("Demo")
            }

            // Legend
            HStack(spacing: 20) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 6) {
                        SWBulletPointText(bulletColor: item.color) {
                            Text(item.label)
                                .font(.subheadline)

                            Text("\(Int(item.value))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
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
}

#Preview {
    SWRingChart(data: [
        RingData(label: "Partner", value: 80, color: .accentColor),
        RingData(label: "Family", value: 91, color: .green),
        RingData(label: "Social", value: 63, color: .orange)
    ])
    .padding()
}

struct RingData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}
