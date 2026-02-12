//
//  SWShimmer.swift
//  ShipSwift
//
//  Shimmer highlight effect modifier
//  Adds a left-to-right sweeping white light band animation.
//  Commonly used on buttons, cards, or other elements to draw user attention.
//
//  Usage:
//  ```swift
//  // Basic usage
//  Button("Scan Today") { }
//      .shimmer()
//
//  // Custom parameters
//  Button("Scan Today") { }
//      .shimmer(duration: 1.5, delay: 2.0)
//  ```
//
//  Parameters:
//  - duration: Time for the band to sweep across (seconds), default 2.0
//  - delay: Interval between sweeps (seconds), default 1.0
//
//  Notes:
//  - Best used after `.clipShape()` to ensure the band is properly clipped
//  - The band automatically adapts to the view's width
//  - The animation loops infinitely
//

import SwiftUI

// MARK: - SWShimmerModifier

struct SWShimmerModifier: ViewModifier {
    @State private var animate = false

    let duration: Double
    let delay: Double

    init(duration: Double = 2.0, delay: Double = 1.0) {
        self.duration = duration
        self.delay = delay
    }

    // White light band gradient
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [
                .clear,
                .clear,
                .white.opacity(0.2),
                .clear,
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let bandWidth = geo.size.width * 0.5
                    gradient
                        .frame(width: bandWidth)
                        // Start fully off-screen left, end fully off-screen right
                        .offset(x: animate ? geo.size.width + bandWidth : -bandWidth * 1.5)
                        .animation(
                            .linear(duration: duration)
                            .delay(delay)
                            .repeatForever(autoreverses: false),
                            value: animate
                        )
                }
                .clipped()
            }
            .task {
                // Delay one frame to ensure the view is fully loaded
                try? await Task.sleep(nanoseconds: 100_000_000)
                animate = true
            }
    }
}

// MARK: - View Extension

extension View {
    /// Add a shimmer highlight effect
    ///
    /// - Parameters:
    ///   - duration: Time for the band to sweep across (seconds), default 2.0
    ///   - delay: Interval between sweeps (seconds), default 1.0
    /// - Returns: View with shimmer effect applied
    func shimmer(duration: Double = 2.0, delay: Double = 1.0) -> some View {
        modifier(SWShimmerModifier(duration: duration, delay: delay))
    }
}

// MARK: - Preview

#Preview("Button with Shimmer") {
    VStack(spacing: 20) {
        Text("Scan Today")
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background {
                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            .clipShape(.capsule)
            .shimmer(duration: 1.5, delay: 2.0)
    }
    .padding(40)
    .background(Color.gray.opacity(0.2))
}
