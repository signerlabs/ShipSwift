//
//  SWScanImage.swift
//  ShipSwift
//
//  Image component with scan line animation effect.
//  Suitable for image analysis, loading, and similar scenarios.
//  Displays a light band sweeping from left to right.
//
//  Usage:
//  ```
//  SWScanImage {
//      Image(.myImage)
//          .resizable()
//          .scaledToFit()
//  }
//
//  SWScanImage(lineWidth: 100, duration: 2.0) {
//      AsyncImage(url: imageURL)
//  }
//  ```
//
//  Parameters:
//  - content: The image view to display
//  - lineWidth: Scan line width, default 80
//  - duration: Scan cycle (seconds), default 1.5
//  - lineColor: Scan line color, default .white.opacity(0.6)
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
