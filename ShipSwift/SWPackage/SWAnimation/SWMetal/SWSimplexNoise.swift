//
//  SWSimplexNoise.swift
//  ShipSwift
//
//  A multi-color gradient mapped into smooth animated curves built from
//  two layered 2D simplex noises, rendered via a SwiftUI Metal
//  `colorEffect`.
//
//  Algorithm: two snoise samples (one at base UV scale, one at 2× scale)
//  are added into a 0..1 shape value, then mapped across up to 10 base
//  colors with stepped smooth transitions and wrap-around on either
//  side of the gradient.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`, `colorEffect`,
//  Metal `stitchable`).
//
//  Usage:
//    // Default — orange / red / teal / blue 4-color gradient, full-screen
//    SWSimplexNoise()
//        .ignoresSafeArea()
//
//    // Custom palette (1...10 colors)
//    SWSimplexNoise(colors: [.indigo, .purple, .pink, .orange])
//
//    // As a section background
//    myContent.background { SWSimplexNoise() }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    SWSimplexNoise(showsControls: true)
//
//  Parameters:
//    - colors:        1–10 palette colors (default orange / red /
//                     teal / blue).
//    - scale:         Pattern zoom in 0.05...4 (default 1.0).
//    - stepsPerColor: Extra banded transitions per color pair in 1...10
//                     (default 1).
//    - softness:      Sharpness of band-to-band transitions in 0...1
//                     (default 1.0; 0 = hard edges).
//    - speed:         Multiplier on the internal animation time
//                     (default 1.0).
//    - showsControls: Attach a gear `ToolbarItem` that opens a
//                     live-tuning sheet (default `false`).
//

import SwiftUI

// MARK: - Main View

struct SWSimplexNoise: View {
    /// 1–10 palette colors. Extra entries beyond 10 are dropped.
    var colors: [Color] = [
        .red,
        .blue,
        .yellow,
        .black,
        .brown,
        .cyan
    ]

    /// Pattern zoom in 0.05...4 — small = features fill the screen
    /// (zoomed-in), large = more cycles per pixel (zoomed-out).
    var scale: Float = 0.05

    /// Extra banded transitions per color pair, 1...10.
    var stepsPerColor: Float = 1

    /// Sharpness of band-to-band transitions in 0...1.
    /// 0 = hard edges, 1 = smooth gradient.
    var softness: Float = 0

    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a
    /// live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWSimplexNoiseControlled(initial: self)
        } else {
            SWSimplexNoiseRenderer(
                colors: colors,
                scale: scale,
                stepsPerColor: stepsPerColor,
                softness: softness,
                speed: speed
            )
        }
    }
}

// MARK: - Renderer

private struct SWSimplexNoiseRenderer: View {
    let colors: [Color]
    let scale: Float
    let stepsPerColor: Float
    let softness: Float
    let speed: Float

    @State private var start: Date = .now

    var body: some View {
        let slots = paddedSlots(colors)
        let colorsCount = Float(max(min(colors.count, 10), 1))

        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start)) * speed
            // Base layer must be opaque — `Color.clear` skips rendering
            // and the shader never gets called. Use the first palette
            // entry so the first frame looks right before the timeline
            // starts ticking.
            (colors.first ?? .black)
                .colorEffect(
                    ShaderLibrary.swSimplexNoise(
                        .boundingRect,
                        .float(elapsed),
                        .float(scale),
                        .float(colorsCount),
                        .float(stepsPerColor),
                        .float(softness),
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

private struct SWSimplexNoiseControlled: View {
    @State private var colors: [Color]
    @State private var scale: Float
    @State private var stepsPerColor: Float
    @State private var softness: Float
    @State private var speed: Float

    @State private var showSheet = false

    init(initial: SWSimplexNoise) {
        let trimmed = Array(initial.colors.prefix(10))
        _colors        = State(initialValue: trimmed.isEmpty ? [.white] : trimmed)
        _scale         = State(initialValue: initial.scale)
        _stepsPerColor = State(initialValue: initial.stepsPerColor)
        _softness      = State(initialValue: initial.softness)
        _speed         = State(initialValue: initial.speed)
    }

    var body: some View {
        SWSimplexNoiseRenderer(
            colors: colors,
            scale: scale,
            stepsPerColor: stepsPerColor,
            softness: softness,
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
                .accessibilityLabel("Simplex Noise Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWSimplexNoiseControlsSheet(
                colors: $colors,
                scale: $scale,
                stepsPerColor: $stepsPerColor,
                softness: $softness,
                speed: $speed
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWSimplexNoiseControlsSheet: View {
    @Binding var colors: [Color]
    @Binding var scale: Float
    @Binding var stepsPerColor: Float
    @Binding var softness: Float
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

                Section("Gradient") {
                    SliderRow(label: "Scale",          value: $scale,         range: 0.05...4, step: 0.05)
                    SliderRow(label: "Steps / Color",  value: $stepsPerColor, range: 1...10,   step: 1)
                    SliderRow(label: "Softness",       value: $softness,      range: 0...1,    step: 0.01)
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Simplex Noise")
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
        SWSimplexNoise(showsControls: true)
    }
}

#Preview("Indigo / purple / pink") {
    SWSimplexNoise(colors: [.indigo, .purple, .pink, .orange])
        .ignoresSafeArea()
}
