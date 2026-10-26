//
//  SWSmokeRing.swift
//  ShipSwift
//
//  A radial multi-colored gradient distorted by layered noise into a soft
//  smoky ring, rendered via a SwiftUI Metal `colorEffect`.
//
//  Algorithm: ring shape is built in polar coordinates from `length` +
//  `atan2`; two phase-shifted FBM noise layers (1...8 octaves of
//  procedural value noise) cross-fade over a 3-second cycle so the
//  smoke perpetually re-rolls without visible looping; the noise
//  warps the polar UV so the ring's silhouette billows.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`, `colorEffect`,
//  Metal `stitchable`).
//
//  Usage:
//    // Default — warm 4-color smoke on a near-black background
//    SWSmokeRing()
//        .ignoresSafeArea()
//
//    // Recolor — cool palette on white
//    SWSmokeRing(
//        colors: [.cyan, .indigo, .purple, .white],
//        colorBack: .white
//    )
//
//    // As a section background
//    myContent.background { SWSmokeRing() }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    SWSmokeRing(showsControls: true)
//
//  Parameters:
//    - colors:           1–10 ring gradient colors (default warm
//                        red / orange / yellow / white).
//    - colorBack:        Background color (default near-black `#0A0612`).
//    - thickness:        Ring thickness in 0.01...1 (default 0.4).
//    - radius:           Ring radius in 0...1 (default 0.4).
//    - innerShape:       Inner-fill amount in 0...4 (default 2.0;
//                        cubed before use).
//    - noiseScale:       Noise frequency in 0.01...5 (default 1.4).
//    - noiseIterations:  FBM octave count in 1...8 (default 6).
//    - scale:            Overall zoom in 0.05...4 (default 1.0).
//    - speed:            Multiplier on the internal animation time
//                        (default 1.0).
//    - showsControls:    Attach a gear `ToolbarItem` that opens a
//                        live-tuning sheet (default `false`).
//

import SwiftUI

// MARK: - Main View

struct SWSmokeRing: View {
    /// 1–10 ring gradient colors. Extra entries beyond 10 are dropped.
    var colors: [Color] = [
        .white,
        .white
    ]

    /// Background color.
    var colorBack: Color = Color(red: 0.04, green: 0.025, blue: 0.07)  // #0A0612

    /// Ring thickness in 0.01...1.
    var thickness: Float = 0.4

    /// Ring radius in 0...1.
    var radius: Float = 0.4

    /// Inner-fill amount in 0...4 (cubed before use). 1.0 ≈ centered hole
    /// (default), 0 = solid disc, 2+ = the ring overflows inward and the
    /// hole disappears.
    var innerShape: Float = 1.0

    /// Noise frequency in 0.01...5. Higher = finer grain, more chaotic
    /// silhouette.
    var noiseScale: Float = 2.8

    /// FBM octave count in 1...8. Higher = more layered detail.
    var noiseIterations: Float = 8

    /// Overall zoom in 0.05...4.
    var scale: Float = 0.8

    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a
    /// live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWSmokeRingControlled(initial: self)
        } else {
            SWSmokeRingRenderer(
                colors: colors,
                colorBack: colorBack,
                thickness: thickness,
                radius: radius,
                innerShape: innerShape,
                noiseScale: noiseScale,
                noiseIterations: noiseIterations,
                scale: scale,
                speed: speed
            )
        }
    }
}

// MARK: - Renderer

private struct SWSmokeRingRenderer: View {
    let colors: [Color]
    let colorBack: Color
    let thickness: Float
    let radius: Float
    let innerShape: Float
    let noiseScale: Float
    let noiseIterations: Float
    let scale: Float
    let speed: Float

    @State private var start: Date = .now

    var body: some View {
        let slots = paddedSlots(colors)
        let colorsCount = Float(max(min(colors.count, 10), 1))

        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start)) * speed
            // Base layer must be opaque — `colorBack` doubles as the
            // first-frame fallback before the shader is invoked.
            colorBack
                .colorEffect(
                    ShaderLibrary.swSmokeRing(
                        .boundingRect,
                        .float(elapsed),
                        .float(scale),
                        .float(colorsCount),
                        .float(thickness),
                        .float(radius),
                        .float(innerShape),
                        .float(noiseScale),
                        .float(noiseIterations),
                        .color(colorBack),
                        .color(slots[0]),
                        .color(slots[1]),
                        .color(slots[2]),
                        .color(slots[3]),
                        .color(slots[4]),
                        .color(slots[5]),
                        .color(slots[6]),
                        .color(slots[7]),
                        .color(slots[8]),
                        .color(slots[9])
                    )
                )
        }
    }

    /// Pad palette to exactly 10 entries by repeating the tail color.
    /// Slots beyond `colorsCount` are not used by the shader; padding
    /// just keeps the parameter list well-formed.
    private func paddedSlots(_ src: [Color]) -> [Color] {
        var out = Array(src.prefix(10))
        let tail = out.last ?? .black
        while out.count < 10 { out.append(tail) }
        return out
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWSmokeRingControlled: View {
    @State private var colors: [Color]
    @State private var colorBack: Color
    @State private var thickness: Float
    @State private var radius: Float
    @State private var innerShape: Float
    @State private var noiseScale: Float
    @State private var noiseIterations: Float
    @State private var scale: Float
    @State private var speed: Float

    @State private var showSheet = false

    init(initial: SWSmokeRing) {
        let trimmed = Array(initial.colors.prefix(10))
        _colors          = State(initialValue: trimmed.isEmpty ? [.white] : trimmed)
        _colorBack       = State(initialValue: initial.colorBack)
        _thickness       = State(initialValue: initial.thickness)
        _radius          = State(initialValue: initial.radius)
        _innerShape      = State(initialValue: initial.innerShape)
        _noiseScale      = State(initialValue: initial.noiseScale)
        _noiseIterations = State(initialValue: initial.noiseIterations)
        _scale           = State(initialValue: initial.scale)
        _speed           = State(initialValue: initial.speed)
    }

    var body: some View {
        SWSmokeRingRenderer(
            colors: colors,
            colorBack: colorBack,
            thickness: thickness,
            radius: radius,
            innerShape: innerShape,
            noiseScale: noiseScale,
            noiseIterations: noiseIterations,
            scale: scale,
            speed: speed
        )
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Smoke Ring Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWSmokeRingControlsSheet(
                colors: $colors,
                colorBack: $colorBack,
                thickness: $thickness,
                radius: $radius,
                innerShape: $innerShape,
                noiseScale: $noiseScale,
                noiseIterations: $noiseIterations,
                scale: $scale,
                speed: $speed
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWSmokeRingControlsSheet: View {
    @Binding var colors: [Color]
    @Binding var colorBack: Color
    @Binding var thickness: Float
    @Binding var radius: Float
    @Binding var innerShape: Float
    @Binding var noiseScale: Float
    @Binding var noiseIterations: Float
    @Binding var scale: Float
    @Binding var speed: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(colors.indices, id: \.self) { i in
                        ColorPicker("Color \(i + 1)",
                                    selection: $colors[i],
                                    supportsOpacity: true)
                    }
                    ColorPicker("Background",
                                selection: $colorBack,
                                supportsOpacity: false)
                } header: {
                    HStack {
                        Text("Palette (\(colors.count) / 10)")
                        Spacer()
                        Button {
                            if colors.count > 1 { colors.removeLast() }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .disabled(colors.count <= 1)
                        Button {
                            if colors.count < 10 {
                                colors.append(colors.last ?? .white)
                            }
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .disabled(colors.count >= 10)
                    }
                }

                Section("Ring") {
                    SliderRow(label: "Radius",     value: $radius,     range: 0...1,     step: 0.01)
                    SliderRow(label: "Thickness",  value: $thickness,  range: 0.01...1,  step: 0.01)
                    SliderRow(label: "Inner Fill", value: $innerShape, range: 0...4,     step: 0.05)
                    SliderRow(label: "Scale",      value: $scale,      range: 0.05...4,  step: 0.05)
                }

                Section("Noise") {
                    SliderRow(label: "Noise Scale", value: $noiseScale,      range: 0.01...5, step: 0.01)
                    SliderRow(label: "Iterations",  value: $noiseIterations, range: 1...8,    step: 1)
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Smoke Ring")
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

private struct SliderRow: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float

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

// MARK: - Preview

#Preview("Default") {
    NavigationStack {
        SWSmokeRing(showsControls: true)
    }
}

#Preview("Cool palette on white") {
    SWSmokeRing(
        colors: [.cyan, .indigo, .purple, .white],
        colorBack: .white
    )
    .ignoresSafeArea()
}
