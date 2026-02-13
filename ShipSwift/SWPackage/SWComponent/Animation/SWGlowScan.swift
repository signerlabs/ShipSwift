//
//  SWGlowScan.swift
//  ShipSwift
//
//  View modifier that replaces the view's appearance with a base color and sweeps
//  a glowing highlight band across it. The original view shape is used as a mask,
//  making it ideal for text, icons, and SF Symbols.
//
//  Usage:
//    // Default gray base with white glow scan effect
//    Text("Start Scan Today")
//        .font(.largeTitle.bold())
//        .glowScan()
//
//    // Custom colors and speed
//    Image(systemName: "waveform.circle.fill")
//        .font(.system(size: 80))
//        .glowScan(baseColor: .blue.opacity(0.6), glowColor: .cyan)
//
//    // Fully custom parameters
//    Text("Analyzing...")
//        .font(.title2.bold())
//        .glowScan(
//            baseColor: .accentColor,
//            glowColor: .white,
//            duration: 1.5,
//            bandWidth: 200
//        )
//
//  Modifier Parameters:
//    - baseColor: Color     — Base fill color (default .gray)
//    - glowColor: Color     — Highlight glow color (default .white)
//    - duration: Double     — Single scan cycle in seconds (default 2.0)
//    - bandWidth: CGFloat   — Light band width (default 150)
//
//  Created by Wei Zhong on 3/1/26.
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
