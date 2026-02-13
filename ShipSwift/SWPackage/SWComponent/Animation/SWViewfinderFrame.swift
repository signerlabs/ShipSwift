//
//  SWViewfinderFrame.swift
//  ShipSwift
//
//  Camera viewfinder View wrapper that draws a rounded crop frame with a
//  semi-transparent mask on top of the provided content. The mask covers the
//  full area and cuts out a transparent window for the scan area.
//
//  Usage:
//    // Default size (300x180) overlaid on content
//    SWViewfinderFrame {
//        CameraPreviewView()
//    }
//
//    // Custom square viewfinder frame
//    SWViewfinderFrame(
//        width: 280,
//        height: 280,
//        cornerRadius: 16
//    ) {
//        CameraPreviewView()
//    }
//
//    // Fully custom style
//    SWViewfinderFrame(
//        width: 250,
//        height: 250,
//        cornerRadius: 20,
//        borderColor: .yellow,
//        borderWidth: 4,
//        maskColor: .black.opacity(0.6),
//        verticalOffset: -50
//    ) {
//        CameraPreviewView()
//    }
//
//  Parameters:
//    - width: CGFloat           — Viewfinder frame width (default 300)
//    - height: CGFloat          — Viewfinder frame height (default 180)
//    - cornerRadius: CGFloat    — Corner radius (default 40)
//    - borderColor: Color       — Border color (default white semi-transparent)
//    - borderWidth: CGFloat     — Border width (default 3)
//    - maskColor: Color         — Mask color (default black 0.8 opacity)
//    - verticalOffset: CGFloat  — Vertical offset, negative moves up (default 0)
//    - content: @ViewBuilder    — View content to overlay the viewfinder on
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

/// Viewfinder frame component
/// Wraps content and overlays a rounded crop frame with a semi-transparent mask around it
struct SWViewfinderFrame<Content: View>: View {
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

    /// Content to overlay the viewfinder on
    @ViewBuilder let content: () -> Content

    init(
        width: CGFloat = 300,
        height: CGFloat = 180,
        cornerRadius: CGFloat = 40,
        borderColor: Color = .white.opacity(0.6),
        borderWidth: CGFloat = 3,
        maskColor: Color = .black.opacity(0.8),
        verticalOffset: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.maskColor = maskColor
        self.verticalOffset = verticalOffset
        self.content = content
    }

    var body: some View {
        content()
            .overlay {
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
}

// MARK: - Preview

#Preview("Default") {
    SWViewfinderFrame {
        Color.gray
    }
}

#Preview("Custom Size") {
    SWViewfinderFrame(
        width: 250,
        height: 250,
        cornerRadius: 20,
        borderColor: .yellow,
        borderWidth: 4
    ) {
        Color.gray
    }
}

#Preview("Square") {
    SWViewfinderFrame(
        width: 280,
        height: 280,
        cornerRadius: 16
    ) {
        Color.gray
    }
}
