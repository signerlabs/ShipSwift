//
//  SWScanImage.swift
//  ShipSwift
//
//  Animated scan-line overlay that sweeps a gradient light band across any content.
//  The content is clipped to a rounded rectangle and the light band loops indefinitely.
//
//  Usage:
//    // Add scan glow effect to any view
//    SWScanImage {
//        Image("photo")
//            .resizable()
//            .frame(width: 300, height: 200)
//    }
//
//    // Custom light band width, speed, and color
//    SWScanImage(lineWidth: 120, duration: 2.0, lineColor: .blue.opacity(0.4)) {
//        Rectangle()
//            .fill(.gray)
//            .frame(width: 300, height: 200)
//    }
//
//  Parameters:
//    - lineWidth: CGFloat  — Scan light band width (default 80)
//    - duration: Double    — Single scan duration in seconds (default 1.5)
//    - lineColor: Color    — Light band color (default white semi-transparent)
//    - content: @ViewBuilder — View content to be scanned
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWScanImage<Content: View>: View {
    @State private var animate = false

    let content: Content
    var lineWidth: CGFloat
    var duration: Double
    var lineColor: Color

    init(
        lineWidth: CGFloat = 80,
        duration: Double = 1.5,
        lineColor: Color = .white.opacity(0.6),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.lineWidth = lineWidth
        self.duration = duration
        self.lineColor = lineColor
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, lineColor, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: lineWidth)
                    .offset(x: animate ? geo.size.width : -lineWidth)
                    .animation(
                        .linear(duration: duration).repeatForever(autoreverses: false),
                        value: animate
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .onAppear {
                animate = true
            }
    }
}

// MARK: - Preview

#Preview {
    SWScanImage {
        Rectangle()
            .fill(.gray)
            .frame(width: 300, height: 200)
    }
    .padding()
}
