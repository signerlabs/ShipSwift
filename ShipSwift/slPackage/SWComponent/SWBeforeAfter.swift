//
//  SWBeforeAfter.swift
//  ShipSwift
//
//  Before/after comparison slider component
//  Automatically slides back and forth to show a comparison between two images.
//  Ideal for beauty filters, photo editing, retouching previews, etc.
//
//  Usage:
//  ```
//  SWBeforeAfter(
//      before: Image(.photoBefore),
//      after: Image(.photoAfter)
//  )
//
//  SWBeforeAfter(
//      before: Image(.photoBefore),
//      after: Image(.photoAfter),
//      width: 300,
//      aspectRatio: 16/9,
//      cornerRadius: 16,
//      speed: 1.0
//  )
//  ```
//
//  Parameters:
//  - before: Original image (bottom layer)
//  - after: Effect image (top layer, masked)
//  - width: Image width, default 360
//  - aspectRatio: Width/height ratio, default 4/3
//  - cornerRadius: Corner radius, default 24
//  - speed: Sliding speed, default 0.8
//  - showLabels: Whether to show Before/After labels, default true
//

import SwiftUI

struct SWBeforeAfter: View {
    let before: Image
    let after: Image
    var width: CGFloat = 360
    var aspectRatio: CGFloat = 4.0 / 3.0
    var cornerRadius: CGFloat = 24
    var speed: Double = 0.8
    var showLabels: Bool = true

    private var height: CGFloat { width / aspectRatio }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            // Slider oscillates between 0.2 and 0.8
            let sliderPos = 0.5 + sin(t * speed) * 0.3
            let sliderX = sliderPos * width

            ZStack {
                // Bottom layer (Before)
                before
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                // Top layer (After) - clipped by mask
                after
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: sliderX)
                            Spacer(minLength: 0)
                        }
                        .frame(width: width)
                    )

                // Divider line
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 3, height: height)
                    .offset(x: sliderX - width / 2)

                // Slider handle
                Image(systemName: "arrow.left.and.right.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(
                        .ultraThinMaterial,
                        .white.opacity(0.8)
                    )
                    .offset(x: sliderX - width / 2)

                // Before / After labels
                if showLabels {
                    HStack {
                        Text("Before")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(12)

                        Spacer()

                        Text("After")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(12)
                    }
                    .frame(width: width, height: height, alignment: .bottom)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SWBeforeAfter(
        before: Image(systemName: "photo"),
        after: Image(systemName: "photo.fill")
    )
    .padding()
    .background(Color.black)
}
