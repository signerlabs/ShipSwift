//
//  SWBeforeAfter.swift
//  ShipSwift
//
//  Before/after image comparison view with an auto-oscillating slider
//  divider. The slider sweeps back and forth to reveal the "before" and
//  "after" images, with optional Before/After labels.
//
//  Usage:
//    // Basic usage with two images
//    SWBeforeAfter(
//        before: Image("photo_before"),
//        after: Image("photo_after")
//    )
//
//    // Customized size, aspect ratio, and animation speed
//    SWBeforeAfter(
//        before: Image("old"),
//        after: Image("new"),
//        width: 300,               // default 360
//        aspectRatio: 16.0 / 9.0,  // default 4/3
//        cornerRadius: 16,         // default 24
//        speed: 1.2,               // oscillation speed, default 0.8
//        showLabels: false          // hide Before/After labels
//    )
//
//  Created by Wei Zhong on 3/1/26.
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
