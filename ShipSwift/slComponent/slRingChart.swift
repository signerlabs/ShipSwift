//
//  slRingChart.swift
//  full-pack
//
//  Created by 仲炜 on 2025/12/14.
//  Copyright © 2025 Signer Labs. All rights reserved.
//

import SwiftUI
import Charts

struct slRingChart: View {
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
            // 嵌套圆环
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
                    
                    // 背景圆环（浅色）
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
            
            // 图例
            HStack(spacing: 20) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 6) {
                        slBulletPointText(bulletColor: item.color) {
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
    slRingChart(data: [
        RingData(label: "伴侣", value: 80, color: .accentColor),
        RingData(label: "家庭", value: 91, color: .green),
        RingData(label: "社交", value: 63, color: .orange)
    ])
    .padding()
}

struct RingData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}
