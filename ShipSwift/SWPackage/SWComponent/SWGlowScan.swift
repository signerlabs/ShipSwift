//
//  SWGlowScan.swift
//  ShipSwift
//
//  Glow scan effect modifier.
//  Adds a glowing light band animation sweeping from left to right across the view.
//  Unlike shimmer, this effect is more pronounced and suitable for emphasized text or icons.
//
//  Usage:
//  ```
//  // Basic usage
//  Text("Start Scan")
//      .glowScan()
//
//  // Custom parameters
//  Text("Analyzing...")
//      .glowScan(baseColor: .blue, duration: 1.5, bandWidth: 100)
//
//  // Apply to images
//  Image(systemName: "waveform")
//      .glowScan()
//  ```
//
//  Parameters:
//  - baseColor: Base color (non-highlight portion), default `.gray`
//  - glowColor: Highlight color, default `.white`
//  - duration: Time for the light band to sweep across (seconds), default 2.0
//  - bandWidth: Light band width, default 150
//

import SwiftUI

// MARK: - SWGlowScanModifier

struct SWGlowScanModifier: ViewModifier {
    @State private var animate = false

    let baseColor: Color
    let glowColor: Color
    let duration: Double
    let bandWidth: CGFloat

    init(
        baseColor: Color = .gray,
        glowColor: Color = .white,
        duration: Double = 2.0,
        bandWidth: CGFloat = 150
    ) {
        self.baseColor = baseColor
        self.glowColor = glowColor
        self.duration = duration
        self.bandWidth = bandWidth
    }

    func body(content: Content) -> some View {
        content
            .hidden()
            .overlay {
                GeometryReader { geo in
                    let totalWidth = geo.size.width

                    Rectangle()
                        .fill(baseColor)
                        .overlay {
                            LinearGradient(
                                colors: [.clear, glowColor, .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: bandWidth)
                            .offset(x: animate ? totalWidth / 2 + bandWidth : -totalWidth / 2 - bandWidth)
                        }
                        .animation(
                            .linear(duration: duration)
                            .repeatForever(autoreverses: false),
                            value: animate
                        )
                        .mask { content }
                }
            }
            .onAppear {
                animate = true
            }
    }
}

// MARK: - View Extension

extension View {
    /// Glow scan effect
    /// - Parameters:
    ///   - baseColor: Base color, default `.gray`
    ///   - glowColor: Highlight color, default `.white`
    ///   - duration: Scan cycle (seconds), default 2.0
    ///   - bandWidth: Light band width, default 150
    func glowScan(
        baseColor: Color = .gray,
        glowColor: Color = .white,
        duration: Double = 2.0,
        bandWidth: CGFloat = 150
    ) -> some View {
        modifier(SWGlowScanModifier(
            baseColor: baseColor,
            glowColor: glowColor,
            duration: duration,
            bandWidth: bandWidth
        ))
    }
}

// MARK: - Preview

#Preview("Text") {
    Text("Start Scan Today")
        .font(.largeTitle.bold())
        .glowScan()
}

#Preview("Icon") {
    Image(systemName: "waveform.circle.fill")
        .font(.system(size: 80))
        .glowScan(baseColor: .blue.opacity(0.6), glowColor: .cyan)
}

#Preview("Custom Colors") {
    VStack(spacing: 20) {
        Text("Analyzing...")
            .font(.title2.bold())
            .glowScan(baseColor: .accentColor, glowColor: .white, duration: 1.5)

        Text("Processing")
            .font(.headline)
            .glowScan(baseColor: .green.opacity(0.7), glowColor: .mint)
    }
}
