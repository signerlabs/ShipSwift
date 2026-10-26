//
//  SWGrainGradient.swift
//  ShipSwift
//
//  Soft tri-color noise gradient with film grain, rendered via a SwiftUI
//  Metal stitchable shader. Two low-frequency value-noise samples drift
//  three user colors against each other; a per-frame high-frequency hash
//  adds film grain so the surface reads as designed rather than flat —
//  the 2025-era staple of Apple Music posters and Spotify hero cards.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — twilight peach / lilac gradient, full-screen
//    ZStack {
//        SWGrainGradient()
//            .ignoresSafeArea()
//        // Your content here
//    }
//
//    // Recolor — cool mint
//    SWGrainGradient(
//        color1: .teal,
//        color2: .green,
//        color3: .mint
//    )
//
//    // As a hero background
//    heroContent
//        .background { SWGrainGradient() }
//
//    // Demo / debug — adds a gear button in the navigation bar that
//    // opens a sheet to tweak every parameter live. Disabled by default.
//    SWGrainGradient(showsControls: true)
//
//  Parameters:
//    - color1: First color, dominant in low-weight regions
//              (default warm peach `#FFB380`)
//    - color2: Second color, mixed in by the first noise sample
//              (default soft lilac `#B399FF`)
//    - color3: Third color, mixed in by the second noise sample
//              (default rose `#FF8099`)
//    - speed: Multiplier on the internal drift time (default `1.0`)
//    - scale: Spatial scale of the noise field — higher = smaller,
//             more numerous color cells (default `1.2`)
//    - grain: Amplitude of the per-frame film grain. `0` = clean
//             gradient, `0.1` ≈ noticeable, `0.2` = chunky photo
//             grain (default `0.06`)
//    - contrast: Gamma exponent on the noise blend weights — higher
//                = sharper color transitions, lower = smoother
//                pastel field (default `1.0`)
//    - showsControls: When `true`, adds a gear `ToolbarItem` to the
//                     enclosing `NavigationStack` that opens a
//                     live-tuning sheet. Default `false`.
//
//  Notes:
//    - Grain is sampled at raw pixel position (independent of `scale`)
//      so the texture stays film-like at any zoom.
//    - Time is multiplied by 0.15 internally; the field is meant to
//      drift slowly. Use the speed slider to push it faster if needed.
//    - When `showsControls` is `true`, the gear button is a native
//      `ToolbarItem` — the call site must be inside a `NavigationStack`.
//
//  Created by Wei Zhong on 5/24/26.
//

import SwiftUI

// MARK: - Main View

struct SWGrainGradient: View {
    /// First color, dominant in low-weight regions.
    var color1: Color = Color(red: 1.0,   green: 0.702, blue: 0.502) // #FFB380

    /// Second color, mixed in by the first noise sample.
    var color2: Color = Color(red: 0.702, green: 0.6,   blue: 1.0)   // #B399FF

    /// Third color, mixed in by the second noise sample.
    var color3: Color = Color(red: 1.0,   green: 0.502, blue: 0.6)   // #FF8099

    /// Multiplier on the internal drift time.
    var speed: Float = 1.0

    /// Spatial scale of the noise field.
    var scale: Float = 1.2

    /// Amplitude of the per-frame film grain.
    var grain: Float = 0.06

    /// Gamma exponent on the noise blend weights.
    var contrast: Float = 1.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWGrainGradientControlled(initial: self)
        } else {
            SWGrainGradientRenderer(
                color1: color1,
                color2: color2,
                color3: color3,
                speed: speed,
                scale: scale,
                grain: grain,
                contrast: contrast
            )
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWGrainGradientRenderer: View {
    let color1: Color
    let color2: Color
    let color3: Color
    let speed: Float
    let scale: Float
    let grain: Float
    let contrast: Float

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            // Base layer is `color1` so the first frame matches the gradient
            // tone before the shader runs — avoids any black flash.
            color1
                .colorEffect(
                    ShaderLibrary.swGrainGradient(
                        .boundingRect,
                        .float(elapsed),
                        .float(speed),
                        .float(scale),
                        .float(grain),
                        .float(contrast),
                        .color(color1),
                        .color(color2),
                        .color(color3)
                    )
                )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWGrainGradientControlled: View {
    @State private var color1: Color
    @State private var color2: Color
    @State private var color3: Color
    @State private var speed: Float
    @State private var scale: Float
    @State private var grain: Float
    @State private var contrast: Float

    @State private var showSheet = false

    init(initial: SWGrainGradient) {
        _color1   = State(initialValue: initial.color1)
        _color2   = State(initialValue: initial.color2)
        _color3   = State(initialValue: initial.color3)
        _speed    = State(initialValue: initial.speed)
        _scale    = State(initialValue: initial.scale)
        _grain    = State(initialValue: initial.grain)
        _contrast = State(initialValue: initial.contrast)
    }

    var body: some View {
        SWGrainGradientRenderer(
            color1: color1,
            color2: color2,
            color3: color3,
            speed: speed,
            scale: scale,
            grain: grain,
            contrast: contrast
        )
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Grain Gradient Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWGrainGradientControlsSheet(
                color1: $color1,
                color2: $color2,
                color3: $color3,
                speed: $speed,
                scale: $scale,
                grain: $grain,
                contrast: $contrast
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWGrainGradientControlsSheet: View {
    @Binding var color1: Color
    @Binding var color2: Color
    @Binding var color3: Color
    @Binding var speed: Float
    @Binding var scale: Float
    @Binding var grain: Float
    @Binding var contrast: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Colors") {
                    ColorPicker("Color 1", selection: $color1, supportsOpacity: false)
                    ColorPicker("Color 2", selection: $color2, supportsOpacity: false)
                    ColorPicker("Color 3", selection: $color3, supportsOpacity: false)
                }

                Section("Field") {
                    SliderRow(label: "Scale",    value: $scale,    range: 0.2...5,   step: 0.05)
                    SliderRow(label: "Grain",    value: $grain,    range: 0...0.3,   step: 0.005)
                    SliderRow(label: "Contrast", value: $contrast, range: 0.1...4,   step: 0.05)
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Grain Gradient")
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
                Text(String(format: "%.3f", value))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

// MARK: - Preview

#Preview {
    // ToolbarItem requires an enclosing NavigationStack to render.
    NavigationStack {
        SWGrainGradient(showsControls: true)
    }
}
