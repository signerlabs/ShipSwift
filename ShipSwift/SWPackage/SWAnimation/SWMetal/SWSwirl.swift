//
//  SWSwirl.swift
//  ShipSwift
//
//  Animated bands of color twisting and bending into spirals, arcs, and
//  flowing circular patterns, rendered via a SwiftUI Metal `colorEffect`.
//
//  Algorithm: polar-coordinate angle multiplied by `bandCount` and
//  spun by time; a `pow(length, -twist)` radial term bends straight
//  sectoral bands into spirals; folded to a triangular wave so each
//  band gets two symmetric edges; optionally distorted with simplex
//  noise; finally mapped across 1...10 palette colors with
//  `fwidth()`-based anti-aliased band edges.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`, `colorEffect`,
//  Metal `stitchable`).
//
//  Usage:
//    // Default — magenta/blue/cyan swirl on a deep navy back, full-screen
//    SWSwirl()
//        .ignoresSafeArea()
//
//    // Recolor — sunset on white
//    SWSwirl(
//        colors: [.orange, .pink, .purple],
//        colorBack: .white
//    )
//
//    // As a section background
//    myContent.background { SWSwirl() }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    SWSwirl(showsControls: true)
//
//  Parameters:
//    - colors:         1–10 swirl band colors (default magenta /
//                      blue / cyan / white).
//    - colorBack:      Background color (default near-black `#0A0F1A`).
//    - bandCount:      Number of color bands in 0...15 (default 4;
//                      0 = concentric ripples).
//    - twist:          Vortex power in 0...1 (default 0.5;
//                      0 = straight sectoral shapes).
//    - center:         How far from the center the colors begin
//                      in 0...1 (default 0.5).
//    - proportion:     Blend point between colors in 0...1
//                      (default 0.5; 0.5 = equal distribution).
//    - softness:       Color transition sharpness in 0...1
//                      (default 0.5; 0 = hard, 1 = smooth).
//    - noise:          Strength of noise distortion in 0...1
//                      (default 0; no effect if `noiseFrequency` is 0).
//    - noiseFrequency: Noise frequency in 0...1 (default 0.3).
//    - scale:          Overall zoom in 0.05...4 (default 1.0).
//    - speed:          Multiplier on the internal animation time
//                      (default 1.0).
//    - showsControls:  Attach a gear `ToolbarItem` that opens a
//                      live-tuning sheet (default `false`).
//

import SwiftUI

// MARK: - Main View

struct SWSwirl: View {
    /// 1–10 swirl band colors. Extra entries beyond 10 are dropped.
    var colors: [Color] = [
        Color(red: 0.95, green: 0.30, blue: 0.70),  // magenta
        Color(red: 0.30, green: 0.40, blue: 0.95),  // blue
        Color(red: 0.30, green: 0.85, blue: 0.95),  // cyan
        Color.white
    ]

    /// Background color.
    var colorBack: Color = Color(red: 0.04, green: 0.06, blue: 0.10)  // #0A0F1A

    /// Number of color bands in 0...15.
    /// 0 = concentric ripples (no angular bands).
    var bandCount: Float = 6

    /// Vortex power in 0...1. 0 = straight sectoral shapes, 1 = tight spiral.
    /// Larger values also enlarge the empty hole at the center.
    var twist: Float = 0.2

    /// How far from the center the colors begin to appear, 0...1.
    var center: Float = 0.2

    /// Blend point between colors in 0...1. 0.5 = equal distribution.
    var proportion: Float = 0.5

    /// Color transition sharpness in 0...1. 0 = hard edges (default,
    /// `fwidth()` still applies pixel-level AA), 1 = soft blur.
    var softness: Float = 0.0

    /// Strength of noise distortion in 0...1 (no effect if `noiseFrequency` is 0).
    /// Default 0.5 gives the bands a hand-warped silhouette while they spin.
    var noise: Float = 0.2

    /// Noise frequency in 0...1.
    var noiseFrequency: Float = 0.4

    /// Overall zoom in 0.05...4.
    var scale: Float = 1.0

    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a
    /// live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWSwirlControlled(initial: self)
        } else {
            SWSwirlRenderer(
                colors: colors,
                colorBack: colorBack,
                bandCount: bandCount,
                twist: twist,
                center: center,
                proportion: proportion,
                softness: softness,
                noise: noise,
                noiseFrequency: noiseFrequency,
                scale: scale,
                speed: speed
            )
        }
    }
}

// MARK: - Renderer

private struct SWSwirlRenderer: View {
    let colors: [Color]
    let colorBack: Color
    let bandCount: Float
    let twist: Float
    let center: Float
    let proportion: Float
    let softness: Float
    let noise: Float
    let noiseFrequency: Float
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
                    ShaderLibrary.swSwirl(
                        .boundingRect,
                        .float(elapsed),
                        .float(scale),
                        .float(colorsCount),
                        .float(bandCount),
                        .float(twist),
                        .float(center),
                        .float(proportion),
                        .float(softness),
                        .float(noise),
                        .float(noiseFrequency),
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

private struct SWSwirlControlled: View {
    @State private var colors: [Color]
    @State private var colorBack: Color
    @State private var bandCount: Float
    @State private var twist: Float
    @State private var center: Float
    @State private var proportion: Float
    @State private var softness: Float
    @State private var noise: Float
    @State private var noiseFrequency: Float
    @State private var scale: Float
    @State private var speed: Float

    @State private var showSheet = false

    init(initial: SWSwirl) {
        let trimmed = Array(initial.colors.prefix(10))
        _colors         = State(initialValue: trimmed.isEmpty ? [.white] : trimmed)
        _colorBack      = State(initialValue: initial.colorBack)
        _bandCount      = State(initialValue: initial.bandCount)
        _twist          = State(initialValue: initial.twist)
        _center         = State(initialValue: initial.center)
        _proportion     = State(initialValue: initial.proportion)
        _softness       = State(initialValue: initial.softness)
        _noise          = State(initialValue: initial.noise)
        _noiseFrequency = State(initialValue: initial.noiseFrequency)
        _scale          = State(initialValue: initial.scale)
        _speed          = State(initialValue: initial.speed)
    }

    var body: some View {
        SWSwirlRenderer(
            colors: colors,
            colorBack: colorBack,
            bandCount: bandCount,
            twist: twist,
            center: center,
            proportion: proportion,
            softness: softness,
            noise: noise,
            noiseFrequency: noiseFrequency,
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
                .accessibilityLabel("Swirl Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWSwirlControlsSheet(
                colors: $colors,
                colorBack: $colorBack,
                bandCount: $bandCount,
                twist: $twist,
                center: $center,
                proportion: $proportion,
                softness: $softness,
                noise: $noise,
                noiseFrequency: $noiseFrequency,
                scale: $scale,
                speed: $speed
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWSwirlControlsSheet: View {
    @Binding var colors: [Color]
    @Binding var colorBack: Color
    @Binding var bandCount: Float
    @Binding var twist: Float
    @Binding var center: Float
    @Binding var proportion: Float
    @Binding var softness: Float
    @Binding var noise: Float
    @Binding var noiseFrequency: Float
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

                Section("Shape") {
                    SliderRow(label: "Bands",       value: $bandCount,  range: 0...15,    step: 1)
                    SliderRow(label: "Twist",       value: $twist,      range: 0...1,     step: 0.01)
                    SliderRow(label: "Center",      value: $center,     range: 0...1,     step: 0.01)
                    SliderRow(label: "Proportion",  value: $proportion, range: 0...1,     step: 0.01)
                    SliderRow(label: "Softness",    value: $softness,   range: 0...1,     step: 0.01)
                    SliderRow(label: "Scale",       value: $scale,      range: 0.05...4,  step: 0.05)
                }

                Section("Noise") {
                    SliderRow(label: "Strength",    value: $noise,          range: 0...1, step: 0.01)
                    SliderRow(label: "Frequency",   value: $noiseFrequency, range: 0...1, step: 0.01)
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Swirl")
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
        SWSwirl(showsControls: true)
    }
}

#Preview("Sunset on white") {
    SWSwirl(
        colors: [.orange, .pink, .purple],
        colorBack: .white
    )
    .ignoresSafeArea()
}
