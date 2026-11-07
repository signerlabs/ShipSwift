//
//  SWConfetti.swift
//  ShipSwift
//
//  Celebration confetti burst overlay. When `isActive` flips to `true`,
//  a shower of colourful shapes (rectangles, circles, triangles, strips)
//  erupts from the bottom of the frame, arcs under gravity, spins, and
//  fades out. Rendered with a single SwiftUI `Canvas` per frame so
//  hundreds of particles stay at 60fps.
//
//  Usage:
//    // Basic — toggle triggers one burst
//    SWConfetti(isActive: $celebrate) {
//        Text("🎉 You did it!")
//    }
//
//    // As an overlay on any view
//    myView.swConfetti(isActive: $showConfetti)
//
//    // Custom colors and intensity
//    SWConfetti(
//        isActive: $celebrate,
//        particleCount: 120,
//        colors: [.red, .orange, .yellow, .green, .blue, .purple],
//        spread: .wide,
//        duration: 4.0
//    ) {
//        myContent
//    }
//
//    // Fire-and-forget (auto-resets isActive after burst finishes)
//    SWConfetti(isActive: $celebrate, autoReset: true) {
//        Button("Celebrate") { celebrate = true }
//    }
//
//  Parameters:
//    - isActive:       Binding<Bool> — set to true to fire one burst
//    - particleCount:  Number of particles per burst (default 80)
//    - colors:         Colour palette randomly assigned to particles
//                      (default: rainbow six)
//    - shapes:         Which shapes to include (default: all four)
//    - spread:         .narrow (30°), .medium (60°), .wide (90°)
//                      launch cone (default .medium)
//    - duration:       Seconds until particles fully fade (default 3.0)
//    - gravity:        Downward acceleration in pts/s² (default 500)
//    - autoReset:      Flip isActive back to false when the burst
//                      finishes (default false)
//    - content:        @ViewBuilder — the view underneath the confetti
//
//  Created by Wei Zhong on 6/8/26.
//

import SwiftUI

// MARK: - Public API

struct SWConfetti<Content: View>: View {
    @Binding var isActive: Bool
    var particleCount: Int = 80
    var colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
    var shapes: [SWConfettiShape] = SWConfettiShape.allCases
    var spread: SWConfettiSpread = .medium
    var duration: Double = 3.0
    var gravity: Double = 500
    var autoReset: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .overlay {
                SWConfettiCanvas(
                    isActive: $isActive,
                    particleCount: particleCount,
                    colors: colors,
                    shapes: shapes,
                    spread: spread,
                    duration: duration,
                    gravity: gravity,
                    autoReset: autoReset
                )
                .allowsHitTesting(false)
            }
    }
}

// MARK: - Shape & Spread

enum SWConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
    case strip
}

enum SWConfettiSpread {
    case narrow
    case medium
    case wide

    var halfAngle: Double {
        switch self {
        case .narrow: .pi / 6
        case .medium: .pi / 3
        case .wide:   .pi / 2
        }
    }
}

// MARK: - View Modifier

extension View {
    func swConfetti(
        isActive: Binding<Bool>,
        particleCount: Int = 80,
        colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple],
        shapes: [SWConfettiShape] = SWConfettiShape.allCases,
        spread: SWConfettiSpread = .medium,
        duration: Double = 3.0,
        autoReset: Bool = false
    ) -> some View {
        overlay {
            SWConfettiCanvas(
                isActive: isActive,
                particleCount: particleCount,
                colors: colors,
                shapes: shapes,
                spread: spread,
                duration: duration,
                gravity: 500,
                autoReset: autoReset
            )
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Particle

private struct SWConfettiParticle {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var angle: Double
    var angularVelocity: Double
    var scaleX: Double
    var wobbleSpeed: Double
    var wobblePhase: Double
    let color: Color
    let shape: SWConfettiShape
    let width: Double
    let height: Double
}

// MARK: - Canvas Renderer

private struct SWConfettiCanvas: View {
    @Binding var isActive: Bool
    let particleCount: Int
    let colors: [Color]
    let shapes: [SWConfettiShape]
    let spread: SWConfettiSpread
    let duration: Double
    let gravity: Double
    let autoReset: Bool

    @State private var particles: [SWConfettiParticle] = []
    @State private var startTime: Date?

    var body: some View {
        TimelineView(.animation(paused: startTime == nil)) { ctx in
            Canvas { gc, size in
                guard let start = startTime else { return }
                let elapsed = ctx.date.timeIntervalSince(start)
                if elapsed > duration { return }

                let progress = elapsed / duration
                let opacity = progress < 0.7 ? 1.0 : max(0, 1 - (progress - 0.7) / 0.3)

                for p in particles {
                    let t = elapsed
                    let px = size.width / 2 + p.x + p.vx * t
                    let py = size.height + p.y + p.vy * t + 0.5 * gravity * t * t
                    let angle = Angle.degrees(p.angle + p.angularVelocity * t)
                    let wobble = cos(p.wobbleSpeed * t + p.wobblePhase)
                    let currentScaleX = p.scaleX * wobble
                    guard abs(currentScaleX) > 0.001 else { continue }

                    guard px > -50 && px < size.width + 50 else { continue }
                    guard py > -50 && py < size.height + 200 else { continue }

                    gc.opacity = opacity
                    gc.translateBy(x: px, y: py)
                    gc.rotate(by: angle)
                    gc.scaleBy(x: currentScaleX, y: 1.0)

                    let rect = CGRect(
                        x: -p.width / 2,
                        y: -p.height / 2,
                        width: p.width,
                        height: p.height
                    )

                    switch p.shape {
                    case .rectangle:
                        gc.fill(Path(rect), with: .color(p.color))
                    case .circle:
                        gc.fill(Path(ellipseIn: rect), with: .color(p.color))
                    case .triangle:
                        var tri = Path()
                        tri.move(to: CGPoint(x: 0, y: -p.height / 2))
                        tri.addLine(to: CGPoint(x: p.width / 2, y: p.height / 2))
                        tri.addLine(to: CGPoint(x: -p.width / 2, y: p.height / 2))
                        tri.closeSubpath()
                        gc.fill(tri, with: .color(p.color))
                    case .strip:
                        let stripRect = CGRect(
                            x: -p.width / 2,
                            y: -p.height / 2,
                            width: p.width,
                            height: p.height
                        )
                        gc.fill(
                            Path(roundedRect: stripRect, cornerRadius: p.width / 2),
                            with: .color(p.color)
                        )
                    }

                    gc.scaleBy(x: 1.0 / currentScaleX, y: 1.0)
                    gc.rotate(by: .zero - angle)
                    gc.translateBy(x: -px, y: -py)
                    gc.opacity = 1.0
                }
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                spawnBurst()
            }
        }
        .task {
            if isActive {
                spawnBurst()
            }
        }
        .task(id: startTime) {
            // Pause the frame clock once the burst has fully faded.
            guard startTime != nil else { return }
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            startTime = nil
            particles = []
        }
    }

    private func spawnBurst() {
        guard !colors.isEmpty, !shapes.isEmpty else { return }

        var newParticles: [SWConfettiParticle] = []
        newParticles.reserveCapacity(particleCount)

        for _ in 0..<particleCount {
            let angle = -.pi / 2 + Double.random(in: -spread.halfAngle...spread.halfAngle)
            let speed = Double.random(in: 400...900)
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed

            let shape = shapes.randomElement()!
            let isStrip = shape == .strip
            let w = isStrip ? Double.random(in: 3...5) : Double.random(in: 6...12)
            let h = isStrip ? Double.random(in: 14...28) : Double.random(in: 6...12)

            newParticles.append(SWConfettiParticle(
                x: Double.random(in: -20...20),
                y: 0,
                vx: vx,
                vy: vy,
                angle: Double.random(in: 0...360),
                angularVelocity: Double.random(in: -400...400),
                scaleX: Double.random(in: 0.6...1.0),
                wobbleSpeed: Double.random(in: 4...10),
                wobblePhase: Double.random(in: 0...(.pi * 2)),
                color: colors.randomElement()!,
                shape: shape,
                width: w,
                height: h
            ))
        }

        particles = newParticles
        startTime = .now

        if autoReset {
            Task {
                try? await Task.sleep(for: .seconds(duration))
                isActive = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Tap to celebrate") {
    struct DemoView: View {
        @State private var celebrate = false

        var body: some View {
            SWConfetti(isActive: $celebrate, autoReset: true) {
                VStack(spacing: 20) {
                    Text("🎉")
                        .font(.system(size: 60))
                    Button("Celebrate!") {
                        celebrate = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    return DemoView()
}
