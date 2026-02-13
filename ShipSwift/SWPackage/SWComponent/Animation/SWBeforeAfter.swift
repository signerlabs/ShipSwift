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
//        aspectRatio: 16.0 / 9.0,  // default 3/4 (portrait)
//        cornerRadius: 16,         // default 24
//        speed: 1.2,               // oscillation speed, default 0.8
//        showLabels: false,         // hide Before/After labels
//        beforeLabel: "旧",         // custom label text, default "Before"
//        afterLabel: "新"           // custom label text, default "After"
//    )
//
//    // Supports drag gesture — drag the slider to compare manually,
//    // auto-animation resumes seamlessly after release.
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWBeforeAfter: View {
    let before: Image
    let after: Image
    var width: CGFloat = 360
    var aspectRatio: CGFloat = 3.0 / 4.0
    var cornerRadius: CGFloat = 24
    var speed: Double = 0.8
    var showLabels: Bool = true
    var beforeLabel: String = "Before"
    var afterLabel: String = "After"

    private var height: CGFloat { width / aspectRatio }

    @State private var startDate = Date.now
    @State private var isDragging = false
    @State private var dragSliderPos: CGFloat = 0.5

    var body: some View {
        TimelineView(.animation(paused: isDragging)) { timeline in
            let sliderPos: CGFloat = isDragging
                ? dragSliderPos
                : 0.5 + sin(timeline.date.timeIntervalSince(startDate) * speed) * 0.3
            let sliderX = sliderPos * width

            ZStack {
                // Bottom layer (Before)
                before
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                // Top layer (After) - clipped by mask
                after
                    .resizable()
                    .scaledToFill()
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
                        .tertiary,
                        .white.opacity(0.8)
                    )
                    .offset(x: sliderX - width / 2)

                // Before / After labels
                if showLabels {
                    HStack {
                        labelTag(beforeLabel)
                            .padding(12)
                        Spacer()
                        labelTag(afterLabel)
                            .padding(12)
                    }
                    .frame(width: width, height: height, alignment: .bottom)
                }
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)
        }
    }

    private func labelTag(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging { isDragging = true }
                dragSliderPos = min(max(value.location.x / width, 0.05), 0.95)
            }
            .onEnded { _ in
                // Resume auto-animation from the current drag position
                let normalized = min(max((dragSliderPos - 0.5) / 0.3, -1.0), 1.0)
                let phase = Double(asin(normalized)) / speed
                startDate = Date.now.addingTimeInterval(-phase)
                isDragging = false
            }
    }
}

// MARK: - Preview

#Preview {
    SWBeforeAfter(
        before: Image(.smileBefore),
        after: Image(.smileAfter)
    )
    .padding()
}
