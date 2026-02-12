//
//  SWViewfinderOverlay.swift
//  ShipSwift
//
//  Viewfinder overlay component - used for camera capture, scanning, and similar scenarios.
//  Displays a rounded crop frame with a semi-transparent mask around it.
//
//  Usage:
//  ```
//  SWViewfinderOverlay()  // Use default parameters
//
//  SWViewfinderOverlay(
//      width: 280,
//      height: 280,
//      cornerRadius: 20,
//      borderColor: .yellow,
//      maskColor: .black.opacity(0.6),
//      verticalOffset: -40  // Shift upward
//  )
//  ```
//

import SwiftUI

/// Viewfinder overlay component
/// Displays a rounded crop frame with a semi-transparent mask around it
struct SWViewfinderOverlay: View {
    /// Crop frame width
    var width: CGFloat = 300
    /// Crop frame height
    var height: CGFloat = 180
    /// Corner radius
    var cornerRadius: CGFloat = 40
    /// Border color
    var borderColor: Color = .white.opacity(0.6)
    /// Border width
    var borderWidth: CGFloat = 3
    /// Mask color
    var maskColor: Color = .black.opacity(0.8)
    /// Vertical offset (negative shifts up, default is centered)
    var verticalOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2 + verticalOffset

            ZStack {
                // Gray mask (only exposing the center crop area)
                Canvas { context, canvasSize in
                    // Draw full-screen mask
                    context.fill(
                        Path(CGRect(origin: .zero, size: canvasSize)),
                        with: .color(maskColor)
                    )

                    // Cut out the center area
                    let cropRect = CGRect(
                        x: centerX - width / 2,
                        y: centerY - height / 2,
                        width: width,
                        height: height
                    )
                    let cropPath = Path(roundedRect: cropRect, cornerRadius: cornerRadius)
                    context.blendMode = .destinationOut
                    context.fill(cropPath, with: .color(.white))
                }
                .compositingGroup()

                // Crop frame border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
                    .frame(width: width, height: height)
                    .position(x: centerX, y: centerY)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview("Default") {
    ZStack {
        Color.gray
        SWViewfinderOverlay()
    }
}

#Preview("Custom Size") {
    ZStack {
        Color.gray
        SWViewfinderOverlay(
            width: 250,
            height: 250,
            cornerRadius: 20,
            borderColor: .yellow,
            borderWidth: 4
        )
    }
}

#Preview("Square") {
    ZStack {
        Color.gray
        SWViewfinderOverlay(
            width: 280,
            height: 280,
            cornerRadius: 16
        )
    }
}
