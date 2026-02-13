//
//  SWGlowSweep.swift
//  ShipSwift
//
//  View wrapper that replaces the content's appearance with a base color and sweeps
//  a glowing highlight band across it. The original content shape is used as a mask,
//  making it ideal for text, icons, and SF Symbols.
//
//  Usage:
//    // Default gray base with white glow sweep effect
//    SWGlowSweep {
//        Text("Start Scan Today")
//            .font(.largeTitle.bold())
//    }
//
//    // Custom colors and speed
//    SWGlowSweep(baseColor: .blue.opacity(0.6), glowColor: .cyan) {
//        Image(systemName: "waveform.circle.fill")
//            .font(.system(size: 80))
//    }
//
//    // Fully custom parameters
//    SWGlowSweep(
//        baseColor: .accentColor,
//        glowColor: .white,
//        duration: 1.5,
//        bandWidth: 200
//    ) {
//        Text("Analyzing...")
//            .font(.title2.bold())
//    }
//
//  Parameters:
//    - baseColor: Color     — Base fill color (default .gray)
//    - glowColor: Color     — Highlight glow color (default .white)
//    - duration: Double     — Single sweep cycle in seconds (default 2.0)
//    - bandWidth: CGFloat   — Light band width in points (default 150)
//    - content: @ViewBuilder — View content to apply the effect on
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

// MARK: - SWGlowSweep

struct SWGlowSweep<Content: View>: View {
    @State private var animate = false

    var baseColor: Color = .gray
    var glowColor: Color = .white
    var duration: Double = 2.0
    var bandWidth: CGFloat = 150

    @ViewBuilder let content: () -> Content

    init(
        baseColor: Color = .gray,
        glowColor: Color = .white,
        duration: Double = 2.0,
        bandWidth: CGFloat = 150,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.baseColor = baseColor
        self.glowColor = glowColor
        self.duration = duration
        self.bandWidth = bandWidth
        self.content = content
    }

    var body: some View {
        let inner = content()
        inner
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
                        .mask { inner }
                }
            }
            .onAppear {
                animate = true
            }
    }
}

// MARK: - Preview

#Preview("Default") {
    SWGlowSweep {
        Text("Start Scan Today")
            .font(.largeTitle.bold())
    }
}

#Preview("Custom Colors") {
    VStack(spacing: 20) {
        SWGlowSweep(baseColor: .accentColor, glowColor: .white, duration: 1.5) {
            Text("Analyzing...")
                .font(.title2.bold())
        }

        SWGlowSweep(baseColor: .green.opacity(0.7), glowColor: .black) {
            Text("Processing")
                .font(.headline)
        }
    }
}
