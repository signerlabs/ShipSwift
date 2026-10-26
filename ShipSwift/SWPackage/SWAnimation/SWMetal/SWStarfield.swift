//
//  SWStarfield.swift
//  ShipSwift
//
//  Multi-layer twinkling starfield rendered via a SwiftUI Metal stitchable
//  shader. Each layer is a hashed grid of stars sliding downward at its
//  own parallax speed; back layers are finer-grained and dimmer.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — white stars on black, full-screen
//    ZStack {
//        SWStarfield()
//            .ignoresSafeArea()
//        // Your content here
//    }
//
//    // Custom color and denser field
//    SWStarfield(starColor: .yellow, density: 0.5, layers: 6)
//
//    // As a section background
//    myContent
//        .background { SWStarfield() }
//
//    // Demo / debug — adds a gear button in the navigation bar that
//    // opens a sheet to tweak every parameter live. Disabled by default.
//    SWStarfield(showsControls: true)
//
//  Parameters:
//    - starColor: Color of stars (default `.white`)
//    - background: Color rendered behind the stars (default `.black`)
//    - speed: Multiplier applied to the per-layer parallax scroll
//             (default `1.0`)
//    - layers: Number of parallax layers, clamped to 1–8
//              (default `4`)
//    - baseScale: Cell grid resolution of the front layer — higher
//                 produces smaller, more numerous stars (default `60`)
//    - scaleStep: Cell grid increment per layer behind the front
//                 (default `30`)
//    - density: Fraction of cells that contain a star, 0–1
//               (default `0.3`)
//    - starSize: Star radius in cell-space, 0–1 (default `0.4`)
//    - twinkleSpeed: Angular frequency of the per-star twinkle
//                    (default `3.0`)
//    - twinkleAmount: Twinkle amplitude, 0 = steady, 1 = full blink
//                     (default `0.3`)
//    - showsControls: When `true`, adds a gear `ToolbarItem` to the
//                     enclosing `NavigationStack` that opens a
//                     live-tuning sheet. Default `false`.
//
//  Notes:
//    - The shader caps `layers` at 8 so the loop bound stays static; values
//      above 8 are silently truncated.
//    - Cost is per-pixel × layers. Defaults are tuned for full-screen on
//      iPhone-class GPUs; raise `baseScale` and `layers` cautiously on
//      lower-end devices.
//    - When `showsControls` is `true`, the gear button is registered as a
//      native `ToolbarItem`, so the call site must be inside a
//      `NavigationStack`. Bare `#Preview` shows it via `NavigationStack { … }`.
//
//  Created by Wei Zhong on 5/20/26.
//

import SwiftUI

// MARK: - Main View

struct SWStarfield: View {
    /// Color of stars.
    var starColor: Color = .white

    /// Color rendered behind the stars.
    var background: Color = .black

    /// Multiplier applied to the per-layer parallax scroll.
    var speed: Float = 1.0

    /// Number of parallax layers (clamped to 1–8 by the shader).
    var layers: Int = 4

    /// Cell grid resolution of the front layer.
    var baseScale: Float = 60

    /// Cell grid increment per layer behind the front.
    var scaleStep: Float = 30

    /// Fraction of cells that contain a star (0–1).
    var density: Float = 0.3

    /// Star radius in cell-space (0–1).
    var starSize: Float = 0.4

    /// Angular frequency of the per-star twinkle.
    var twinkleSpeed: Float = 3.0

    /// Twinkle amplitude — 0 = steady, 1 = full blink.
    var twinkleAmount: Float = 0.3

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWStarfieldControlled(initial: self)
        } else {
            SWStarfieldRenderer(
                starColor: starColor,
                background: background,
                speed: speed,
                layers: layers,
                baseScale: baseScale,
                scaleStep: scaleStep,
                density: density,
                starSize: starSize,
                twinkleSpeed: twinkleSpeed,
                twinkleAmount: twinkleAmount
            )
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWStarfieldRenderer: View {
    let starColor: Color
    let background: Color
    let speed: Float
    let layers: Int
    let baseScale: Float
    let scaleStep: Float
    let density: Float
    let starSize: Float
    let twinkleSpeed: Float
    let twinkleAmount: Float

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            background
                .colorEffect(
                    ShaderLibrary.swStarfield(
                        .boundingRect,
                        .float(elapsed),
                        .float(speed),
                        .float(Float(layers)),
                        .float(baseScale),
                        .float(scaleStep),
                        .float(density),
                        .float(starSize),
                        .float(twinkleSpeed),
                        .float(twinkleAmount),
                        .color(starColor),
                        .color(background)
                    )
                )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWStarfieldControlled: View {
    @State private var starColor: Color
    @State private var background: Color
    @State private var speed: Float
    @State private var layers: Float        // Float-backed so it can drive a Slider
    @State private var baseScale: Float
    @State private var scaleStep: Float
    @State private var density: Float
    @State private var starSize: Float
    @State private var twinkleSpeed: Float
    @State private var twinkleAmount: Float

    @State private var showSheet = false

    init(initial: SWStarfield) {
        _starColor     = State(initialValue: initial.starColor)
        _background    = State(initialValue: initial.background)
        _speed         = State(initialValue: initial.speed)
        _layers        = State(initialValue: Float(initial.layers))
        _baseScale     = State(initialValue: initial.baseScale)
        _scaleStep     = State(initialValue: initial.scaleStep)
        _density       = State(initialValue: initial.density)
        _starSize      = State(initialValue: initial.starSize)
        _twinkleSpeed  = State(initialValue: initial.twinkleSpeed)
        _twinkleAmount = State(initialValue: initial.twinkleAmount)
    }

    var body: some View {
        SWStarfieldRenderer(
            starColor: starColor,
            background: background,
            speed: speed,
            layers: Int(layers.rounded()),
            baseScale: baseScale,
            scaleStep: scaleStep,
            density: density,
            starSize: starSize,
            twinkleSpeed: twinkleSpeed,
            twinkleAmount: twinkleAmount
        )
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Starfield Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWStarfieldControlsSheet(
                starColor: $starColor,
                background: $background,
                speed: $speed,
                layers: $layers,
                baseScale: $baseScale,
                scaleStep: $scaleStep,
                density: $density,
                starSize: $starSize,
                twinkleSpeed: $twinkleSpeed,
                twinkleAmount: $twinkleAmount
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWStarfieldControlsSheet: View {
    @Binding var starColor: Color
    @Binding var background: Color
    @Binding var speed: Float
    @Binding var layers: Float
    @Binding var baseScale: Float
    @Binding var scaleStep: Float
    @Binding var density: Float
    @Binding var starSize: Float
    @Binding var twinkleSpeed: Float
    @Binding var twinkleAmount: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Colors") {
                    ColorPicker("Star Color", selection: $starColor, supportsOpacity: false)
                    ColorPicker("Background", selection: $background, supportsOpacity: false)
                }

                Section("Field") {
                    SliderRow(label: "Layers",     value: $layers,    range: 1...8,    step: 1)
                    SliderRow(label: "Base Scale", value: $baseScale, range: 5...200,  step: 1)
                    SliderRow(label: "Scale Step", value: $scaleStep, range: 0...100,  step: 1)
                    SliderRow(label: "Density",    value: $density,   range: 0...1,    step: 0.01)
                    SliderRow(label: "Star Size",  value: $starSize,  range: 0.05...2, step: 0.05)
                }

                Section("Motion") {
                    SliderRow(label: "Speed",          value: $speed,         range: 0...3,  step: 0.05)
                    SliderRow(label: "Twinkle Speed",  value: $twinkleSpeed,  range: 0...10, step: 0.1)
                    SliderRow(label: "Twinkle Amount", value: $twinkleAmount, range: 0...1,  step: 0.01)
                }
            }
            .navigationTitle("Starfield Controls")
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
                Text(formattedValue)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }

    /// Integer-stepped sliders look cleaner as whole numbers.
    private var formattedValue: String {
        step >= 1
            ? "\(Int(value.rounded()))"
            : String(format: "%.2f", value)
    }
}

// MARK: - Preview

#Preview {
    // ToolbarItem requires an enclosing NavigationStack to render.
    NavigationStack {
        SWStarfield(showsControls: true)
    }
}
