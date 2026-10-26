//
//  SWNeuroNoise.swift
//  ShipSwift
//
//  A glowing web-like structure of fluid lines and soft intersections —
//  atmospheric, organic-yet-futuristic — rendered via a SwiftUI Metal
//  `colorEffect`.
//
//  Algorithm: 15 iterations of rotated UV + scale-doubling sine/cosine
//  accumulation.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — cyan glow on near-black, full-screen
//    SWNeuroNoise()
//        .ignoresSafeArea()
//
//    // Recolor — magenta web
//    SWNeuroNoise(
//        colorFront: .white,
//        colorMid:   .purple,
//        colorBack:  .black
//    )
//
//    // As a section background
//    myContent.background { SWNeuroNoise() }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWNeuroNoise(showsControls: true)
//
//  Parameters:
//    - colorFront: Highlight color of the brightest crossings
//                  (default `.white`).
//    - colorMid: Main web color (default cyan `#56CDE3`).
//    - colorBack: Background color (default near-black `#050519`).
//    - speed: Multiplier on the internal animation time (default `1.0`).
//    - brightness: Luminosity of the crossing points in `0...1`
//                  (default `0.5`).
//    - contrast: Sharpness of the bright-dark transition in `0...1`
//                (default `0.5`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a
//                     live-tuning sheet (default `false`).
//
//  Created by Wei Zhong on 5/25/26.
//

import SwiftUI

// MARK: - Main View

struct SWNeuroNoise: View {
    /// Highlight color of the brightest crossings.
    var colorFront: Color = .white

    /// Main web color.
    var colorMid: Color = Color(red: 0.337, green: 0.804, blue: 0.890) // #56CDE3 cyan

    /// Background color.
    var colorBack: Color = Color(red: 0.02, green: 0.02, blue: 0.10)   // #050519 near-black

    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// Luminosity of the crossing points in 0...1.
    var brightness: Float = 0.5

    /// Sharpness of the bright-dark transition in 0...1.
    var contrast: Float = 0.5

    /// Pattern zoom in 0.05...1 — small = features fill the screen
    /// (zoomed-in), large = more cycles per pixel (zoomed-out).
    var scale: Float = 0.8

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWNeuroNoiseControlled(initial: self)
        } else {
            SWNeuroNoiseRenderer(
                colorFront: colorFront,
                colorMid: colorMid,
                colorBack: colorBack,
                speed: speed,
                brightness: brightness,
                contrast: contrast,
                scale: scale
            )
        }
    }
}

// MARK: - Renderer

private struct SWNeuroNoiseRenderer: View {
    let colorFront: Color
    let colorMid: Color
    let colorBack: Color
    let speed: Float
    let brightness: Float
    let contrast: Float
    let scale: Float

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            // Base layer is `colorBack` so the first frame looks right
            // before TimelineView starts ticking.
            colorBack
                .colorEffect(
                    ShaderLibrary.swNeuroNoise(
                        .boundingRect,
                        .float(elapsed),
                        .float(speed),
                        .float(brightness),
                        .float(contrast),
                        .float(scale),
                        .color(colorFront),
                        .color(colorMid),
                        .color(colorBack)
                    )
                )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWNeuroNoiseControlled: View {
    @State private var colorFront: Color
    @State private var colorMid: Color
    @State private var colorBack: Color
    @State private var speed: Float
    @State private var brightness: Float
    @State private var contrast: Float
    @State private var scale: Float

    @State private var showSheet = false

    init(initial: SWNeuroNoise) {
        _colorFront = State(initialValue: initial.colorFront)
        _colorMid   = State(initialValue: initial.colorMid)
        _colorBack  = State(initialValue: initial.colorBack)
        _speed      = State(initialValue: initial.speed)
        _brightness = State(initialValue: initial.brightness)
        _contrast   = State(initialValue: initial.contrast)
        _scale      = State(initialValue: initial.scale)
    }

    var body: some View {
        SWNeuroNoiseRenderer(
            colorFront: colorFront,
            colorMid: colorMid,
            colorBack: colorBack,
            speed: speed,
            brightness: brightness,
            contrast: contrast,
            scale: scale
        )
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Neuro Noise Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWNeuroNoiseControlsSheet(
                colorFront: $colorFront,
                colorMid: $colorMid,
                colorBack: $colorBack,
                speed: $speed,
                brightness: $brightness,
                contrast: $contrast,
                scale: $scale
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWNeuroNoiseControlsSheet: View {
    @Binding var colorFront: Color
    @Binding var colorMid: Color
    @Binding var colorBack: Color
    @Binding var speed: Float
    @Binding var brightness: Float
    @Binding var contrast: Float
    @Binding var scale: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Colors") {
                    ColorPicker("Front",     selection: $colorFront, supportsOpacity: false)
                    ColorPicker("Mid (web)", selection: $colorMid,   supportsOpacity: false)
                    ColorPicker("Back",      selection: $colorBack,  supportsOpacity: false)
                }

                Section("Field") {
                    SliderRow(label: "Scale",      value: $scale,      range: 0.05...1, step: 0.01)
                    SliderRow(label: "Brightness", value: $brightness, range: 0...1,    step: 0.01)
                    SliderRow(label: "Contrast",   value: $contrast,   range: 0...1,    step: 0.01)
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Neuro Noise")
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
        SWNeuroNoise(showsControls: true)
    }
}

#Preview("Magenta web") {
    SWNeuroNoise(
        colorFront: .white,
        colorMid: .purple,
        colorBack: .black
    )
    .ignoresSafeArea()
}
