//
//  SWFloatingLabels.swift
//  ShipSwift
//
//  Displays an image with animated floating capsule labels that fade in
//  and out at specified positions around the image. Useful for showcasing
//  feature callouts, AI analysis results, or point-of-interest annotations.
//
//  Usage:
//    SWFloatingLabels(
//        image: Image("myPhoto"),
//        size: 360,               // image frame size, default 360
//        cornerRadius: 24,        // default 24
//        cycleDuration: 3.0,      // animation cycle in seconds, default 3.0
//        labels: [
//            // (text, normalized position 0-1 where 0.5 is center)
//            ("Teeth mapping",   CGPoint(x: 0.3, y: 0.5)),
//            ("Plaque detection", CGPoint(x: 0.9, y: 0.6)),
//            ("Shape & balance", CGPoint(x: 0.5, y: 0.8))
//        ]
//    )
//
//  The individual SWFloatingLabel view can also be used standalone:
//
//    SWFloatingLabel(text: "Feature A")
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWFloatingLabels: View {
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
                // Image with gradient border
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

                // Cycle through labels
                ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                    let delay = Double(index) * 0.3
                    let labelCycle = (cycle - delay).truncatingRemainder(dividingBy: cycleDuration)
                    let opacity = labelCycle > 0.5 && labelCycle < (cycleDuration - 0.5) ? 1.0 : 0.0

                    SWFloatingLabel(text: label.0)
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

// MARK: - Floating Label

struct SWFloatingLabel: View {
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
    SWFloatingLabels(
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
