//
//  SWDotSphere.swift
//  ShipSwift
//
//  Rotating 3D dot-sphere animation: N dots arranged via the classic
//  spherical Fibonacci / Vogel-spiral distribution, optionally morphing
//  between an even sphere and a random 3D point cloud. Rendered with a
//  single SwiftUI `Canvas` per frame (not N independent views) so 800+
//  dots stay at 60fps on iPhone.
//
//  Algorithms used (both well-known graphics primitives):
//    - Spherical Fibonacci point set:
//        y = 1 − 2i / (N − 1)
//        θ = i · π(3 − √5)
//        (x, z) = √(1 − y²) · (cos θ, sin θ)
//    - One-axis perspective projection:
//        screen = world · (focal / (focal + z))
//    - Color wave fade: each dot's transition is delayed by its
//      vertical position so the palette appears to wash up the sphere.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `TimelineView`, `Canvas`).
//
//  Usage:
//    // Default — 800 dots, 5-color palette cycle on black
//    SWDotSphere()
//        .ignoresSafeArea()
//
//    // Recolor + denser
//    SWDotSphere(
//        dotCount: 1200,
//        colors: [.cyan, .indigo, .pink],
//        background: .black
//    )
//
//    // Morph between chaos and sphere
//    SWDotSphere(morphAmount: 0.4)
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    SWDotSphere(showsControls: true)
//
//  Parameters:
//    - dotCount:       Number of dots, 50...3000 (default 800).
//    - colors:         Palette to cycle through (default 5 stops).
//    - background:     Background fill (default `.black`).
//    - morphAmount:    0 = random 3D cloud, 1 = perfect sphere
//                      (default 1.0).
//    - rotationSpeed:  Radians per second around the Y axis
//                      (default 0.5).
//    - fadeSeconds:    Seconds per color cross-fade (default 5.5).
//    - waitSeconds:    Pause between fades (default 5.0).
//    - dotSize:        Base dot diameter in points (default 3).
//    - showsControls:  Attach a gear `ToolbarItem` that opens a
//                      live-tuning sheet (default `false`).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Main View

struct SWDotSphere: View {
    var dotCount: Int = 800
    var colors: [Color] = [.blue, .green, .purple, .pink, .orange]
    var background: Color = .black
    var morphAmount: Double = 1.0
    var rotationSpeed: Double = 0.5
    var fadeSeconds: Double = 5.5
    var waitSeconds: Double = 5.0
    var dotSize: Double = 3
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWDotSphereControlled(initial: self)
        } else {
            SWDotSphereRenderer(
                dotCount: dotCount,
                colors: colors,
                background: background,
                morphAmount: morphAmount,
                rotationSpeed: rotationSpeed,
                fadeSeconds: fadeSeconds,
                waitSeconds: waitSeconds,
                dotSize: dotSize
            )
        }
    }
}

// MARK: - Renderer

/// Pre-computed random offsets per dot; resampled when `dotCount` changes.
private struct SWDotSphereCloud {
    let randomXYZ: [SIMD3<Double>]
    let yNormalized: [Double]  // dot's Y in [0, 1], used for color-wave delay

    init(dotCount: Int) {
        var random: [SIMD3<Double>] = []
        random.reserveCapacity(dotCount)
        var sortable: [(Int, Double)] = []
        sortable.reserveCapacity(dotCount)
        for i in 0..<dotCount {
            // Uniform point inside the unit ball: pick a direction
            // uniformly on the sphere, then pull cube-root of a uniform
            // radius (so the volume distribution is uniform).
            let u = Double.random(in: 0...1)
            let v = Double.random(in: 0...1)
            let theta = u * 2 * .pi
            let phi = acos(2 * v - 1)
            let r = pow(Double.random(in: 0...1), 1.0 / 3.0)
            let x = r * sin(phi) * cos(theta)
            let y = r * sin(phi) * sin(theta)
            let z = r * cos(phi)
            random.append(SIMD3(x, y, z))

            // Pre-compute the deterministic sphere Y so the color wave
            // delay can be hashed once per dot.
            let sphereY = (dotCount > 1)
                ? 1 - (Double(i) / Double(dotCount - 1)) * 2
                : 0
            sortable.append((i, sphereY))
        }
        self.randomXYZ = random

        let minY = sortable.map { $0.1 }.min() ?? -1
        let maxY = sortable.map { $0.1 }.max() ??  1
        let span = max(1e-6, maxY - minY)
        var norm = Array(repeating: 0.0, count: dotCount)
        for (i, y) in sortable {
            norm[i] = (y - minY) / span
        }
        self.yNormalized = norm
    }
}

private struct SWDotSphereRenderer: View {
    let dotCount: Int
    let colors: [Color]
    let background: Color
    let morphAmount: Double
    let rotationSpeed: Double
    let fadeSeconds: Double
    let waitSeconds: Double
    let dotSize: Double

    @State private var cloud: SWDotSphereCloud = .init(dotCount: 800)
    @State private var start: Date = .now
    @State private var lastCount: Int = 800

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = ctx.date.timeIntervalSince(start)
            let rotation = elapsed * rotationSpeed
            let totalCycle = max(0.001, fadeSeconds + waitSeconds)
            let timeInCycle = elapsed.truncatingRemainder(dividingBy: totalCycle)
            let baseIdx = Int(floor(elapsed / totalCycle)) % max(1, colors.count)
            let nextIdx = (baseIdx + 1) % max(1, colors.count)
            let baseRGB = rgbComponents(colors[baseIdx])
            let nextRGB = rgbComponents(colors[nextIdx])
            let cosR = cos(rotation)
            let sinR = sin(rotation)
            let count = cloud.randomXYZ.count
            let tMorph = max(0.0, min(1.0, morphAmount))
            let chaosScale = 250.0 * (1 - tMorph) + 100.0 * tMorph
            let goldenAngle = .pi * (3 - sqrt(5.0))

            Canvas { gc, size in
                let centerX = size.width / 2
                let centerY = size.height / 2

                for i in 0..<count {
                    // Sphere position via Vogel spiral.
                    let sphereY: Double = (count > 1)
                        ? 1 - (Double(i) / Double(count - 1)) * 2
                        : 0
                    let radiusAtY = sqrt(max(0, 1 - sphereY * sphereY))
                    let theta = goldenAngle * Double(i)
                    let sphereX = radiusAtY * cos(theta)
                    let sphereZ = radiusAtY * sin(theta)

                    // Morph: lerp between random cloud and sphere.
                    let rnd = cloud.randomXYZ[i]
                    let wx = (rnd.x * (1 - tMorph) + sphereX * tMorph) * chaosScale
                    let wy = (rnd.y * (1 - tMorph) + sphereY * tMorph) * chaosScale
                    let wz = (rnd.z * (1 - tMorph) + sphereZ * tMorph) * chaosScale

                    // Rotate around Y, then 1-axis perspective.
                    let rx = wx * cosR - wz * sinR
                    let rz = wx * sinR + wz * cosR
                    let focal = 300.0
                    let p = focal / (focal + rz)
                    let sx = rx * p
                    let sy = wy * p
                    let dot = max(1.0, dotSize * p)

                    // Per-dot color-wave delay so the fade rolls upward.
                    let delay = cloud.yNormalized[i] * fadeSeconds
                    let progress = max(0.0, min(1.0, (timeInCycle - delay) / fadeSeconds))
                    let r = baseRGB.r * (1 - progress) + nextRGB.r * progress
                    let g = baseRGB.g * (1 - progress) + nextRGB.g * progress
                    let b = baseRGB.b * (1 - progress) + nextRGB.b * progress
                    let rect = CGRect(
                        x: centerX + sx - dot / 2,
                        y: centerY + sy - dot / 2,
                        width: dot,
                        height: dot
                    )
                    gc.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color(red: r, green: g, blue: b, opacity: 0.85))
                    )
                }
            }
        }
        .background(background)
        .onAppear { ensureCloud() }
        .onChange(of: dotCount) { _, _ in ensureCloud() }
    }

    private func ensureCloud() {
        let target = max(50, min(3000, dotCount))
        if target != lastCount || cloud.randomXYZ.count != target {
            cloud = SWDotSphereCloud(dotCount: target)
            lastCount = target
        }
    }

    private func rgbComponents(_ color: Color) -> (r: Double, g: Double, b: Double) {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #else
        let resolved = color.resolve(in: EnvironmentValues())
        return (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
        #endif
    }
}

// MARK: - Controlled Wrapper

private struct SWDotSphereControlled: View {
    @State private var dotCount: Int
    @State private var colors: [Color]
    @State private var background: Color
    @State private var morphAmount: Double
    @State private var rotationSpeed: Double
    @State private var fadeSeconds: Double
    @State private var waitSeconds: Double
    @State private var dotSize: Double

    @State private var showSheet = false

    init(initial: SWDotSphere) {
        _dotCount      = State(initialValue: initial.dotCount)
        _colors        = State(initialValue: initial.colors)
        _background    = State(initialValue: initial.background)
        _morphAmount   = State(initialValue: initial.morphAmount)
        _rotationSpeed = State(initialValue: initial.rotationSpeed)
        _fadeSeconds   = State(initialValue: initial.fadeSeconds)
        _waitSeconds   = State(initialValue: initial.waitSeconds)
        _dotSize       = State(initialValue: initial.dotSize)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SWDotSphereRenderer(
                dotCount: dotCount,
                colors: colors,
                background: background,
                morphAmount: morphAmount,
                rotationSpeed: rotationSpeed,
                fadeSeconds: fadeSeconds,
                waitSeconds: waitSeconds,
                dotSize: dotSize
            )
            .ignoresSafeArea()

            Slider(value: $morphAmount, in: 0...1)
                .padding(60)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showSheet = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Dot Sphere Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWDotSphereControlsSheet(
                dotCount: $dotCount,
                colors: $colors,
                background: $background,
                morphAmount: $morphAmount,
                rotationSpeed: $rotationSpeed,
                fadeSeconds: $fadeSeconds,
                waitSeconds: $waitSeconds,
                dotSize: $dotSize
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWDotSphereControlsSheet: View {
    @Binding var dotCount: Int
    @Binding var colors: [Color]
    @Binding var background: Color
    @Binding var morphAmount: Double
    @Binding var rotationSpeed: Double
    @Binding var fadeSeconds: Double
    @Binding var waitSeconds: Double
    @Binding var dotSize: Double

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(colors.indices, id: \.self) { i in
                        ColorPicker("Color \(i + 1)",
                                    selection: $colors[i],
                                    supportsOpacity: false)
                    }
                    ColorPicker("Background",
                                selection: $background,
                                supportsOpacity: false)
                } header: {
                    HStack {
                        Text("Palette (\(colors.count))")
                        Spacer()
                        Button {
                            if colors.count > 1 { colors.removeLast() }
                        } label: { Image(systemName: "minus.circle") }
                            .disabled(colors.count <= 1)
                        Button {
                            colors.append(colors.last ?? .white)
                        } label: { Image(systemName: "plus.circle") }
                    }
                }

                Section("Geometry") {
                    StepperRow(label: "Dot Count", value: $dotCount,    range: 50...3000, step: 50)
                    DoubleSliderRow(label: "Morph",    value: $morphAmount,   range: 0...1,   step: 0.01)
                    DoubleSliderRow(label: "Dot Size", value: $dotSize,      range: 1...10,  step: 0.5)
                }

                Section("Motion") {
                    DoubleSliderRow(label: "Rotation", value: $rotationSpeed, range: 0...3,   step: 0.05)
                    DoubleSliderRow(label: "Fade s",   value: $fadeSeconds,   range: 0.5...20, step: 0.25)
                    DoubleSliderRow(label: "Wait s",   value: $waitSeconds,   range: 0...20,   step: 0.25)
                }
            }
            .navigationTitle("Dot Sphere")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

}

private struct DoubleSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

private struct StepperRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SWDotSphere(showsControls: true)
    }
}
