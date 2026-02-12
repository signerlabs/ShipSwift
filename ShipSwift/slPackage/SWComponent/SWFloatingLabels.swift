//
//  SWFloatingLabels.swift
//  ShipSwift
//
//  Floating labels overlay for images
//  Cycles through labels appearing over an image with gradient border animation.
//  Ideal for AI analysis results, scan results display, etc.
//
//  Usage:
//  ```
//  SWFloatingLabels(
//      image: Image(.photo),
//      labels: [
//          ("Teeth mapping", CGPoint(x: 0.3, y: 0.5)),
//          ("Plaque detection", CGPoint(x: 0.7, y: 0.6))
//      ]
//  )
//
//  SWFloatingLabels(
//      image: Image(.photo),
//      size: 300,
//      cornerRadius: 16,
//      cycleDuration: 4.0,
//      labels: [("Label", CGPoint(x: 0.5, y: 0.5))]
//  )
//  ```
//
//  Parameters:
//  - image: The image to display
//  - size: Image size, default 360
//  - cornerRadius: Corner radius, default 24
//  - cycleDuration: Animation cycle duration (seconds), default 3.0
//  - labels: Array of labels, each with text and relative position (0-1)
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
