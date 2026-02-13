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
//            // Normalized position 0-1 where 0.5 is center
//            .init(text: "Teeth mapping",    position: CGPoint(x: 0.3, y: 0.5)),
//            .init(text: "Plaque detection", position: CGPoint(x: 0.9, y: 0.6)),
//            .init(text: "Shape & balance",  position: CGPoint(x: 0.5, y: 0.8))
//        ]
//    )
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWFloatingLabels: View {

    // MARK: - Nested Types

    /// Data model for a single floating label
    struct LabelItem: Identifiable {
        let id = UUID()
        let text: String
        let position: CGPoint
    }

    // MARK: - Configuration

    let image: Image
    var size: CGFloat = 360
    var cornerRadius: CGFloat = 24
    var cycleDuration: Double = 3.0
    var labels: [LabelItem] = []

    // MARK: - Body

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
                ForEach(Array(labels.enumerated()), id: \.element.id) { index, label in
                    let delay = Double(index) * 0.3
                    let labelCycle = (cycle - delay).truncatingRemainder(dividingBy: cycleDuration)
                    let opacity = labelCycle > 0.5 && labelCycle < (cycleDuration - 0.5) ? 1.0 : 0.0

                    FloatingLabel(text: label.text)
                        .offset(
                            x: (label.position.x - 0.5) * (size * 0.78),
                            y: (label.position.y - 0.5) * (size * 0.78)
                        )
                        .opacity(opacity)
                        .scaleEffect(opacity > 0 ? 1 : 0.8)
                        .animation(.easeInOut(duration: 0.3), value: opacity)
                }
            }
        }
    }

    // MARK: - Floating Label (Internal)

    /// Capsule-style label used as an internal implementation detail
    private struct FloatingLabel: View {
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
}

// MARK: - Preview

#Preview {
    SWFloatingLabels(
        image: Image(.facePicture),
        labels: [
            .init(text: "Teeth mapping",    position: CGPoint(x: 0.3, y: 0.5)),
            .init(text: "Plaque detection", position: CGPoint(x: 0.9, y: 0.6)),
            .init(text: "Shape & balance",  position: CGPoint(x: 0.5, y: 0.8))
        ]
    )
}
