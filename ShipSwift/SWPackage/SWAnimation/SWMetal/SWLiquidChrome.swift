//
//  SWLiquidChrome.swift
//  ShipSwift
//
//  Animated liquid chrome surface rendered via a SwiftUI Metal stitchable
//  shader. Three sequentially domain-warped value-noise samples produce a
//  fluid metallic flow; a gamma-curve plus a high-power specular glint
//  light it as polished chrome. Four user-tunable colors define the
//  shadow / silver / highlight / accent ramp.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — cool blue chrome, full-screen
//    ZStack {
//        SWLiquidChrome()
//            .ignoresSafeArea()
//        // Your content here
//    }
//
//    // Recolor — warm gold chrome
//    SWLiquidChrome(
//        shadow: .brown,
//        silver: .yellow.opacity(0.4),
//        highlight: .white,
//        tint: .orange
//    )
//
//    // As a section background
//    myContent
//        .background { SWLiquidChrome() }
//
//    // Demo / debug — adds a gear button in the navigation bar that
//    // opens a sheet to tweak every parameter live. Disabled by default.
//    SWLiquidChrome(showsControls: true)
//
//  Parameters:
//    - shadow: Color of the chrome shadow valleys (default near-black `#05030D`)
//    - silver: Mid-tone metallic color (default cool grey `#333340`)
//    - highlight: Color of the brightest reflections (default lit silver `#808099`)
//    - tint: Subtle accent layered in via the first warp sample
//            (default deep blue `#263366`)
//    - speed: Multiplier on the internal time evolution (default `0.3`)
//    - scale: Spatial scale of the noise field — higher = finer detail
//             (default `2.0`)
//    - warp: Strength of the inter-sample domain warp (default `1.5`)
//    - contrast: Gamma exponent on the chrome curve — higher = steeper
//                shadow falloff (default `0.6`)
//    - specPower: Exponent of the specular power-curve — higher = tighter,
//                 sharper glints (default `12`)
//    - specStrength: Multiplier on the specular additive layer (default `0.3`)
//    - tintStrength: Multiplier on the tint additive layer (default `0.15`)
//    - showsControls: When `true`, adds a gear `ToolbarItem` to the
//                     enclosing `NavigationStack` that opens a
//                     live-tuning sheet. Default `false`.
//
//  Notes:
//    - The specular highlight is biased with a baked-in cool tint
//      `(0.6, 0.6, 0.8)` so glints always read as polished metal even when
//      the user colors are warm. Hard-coded by design.
//    - The shader runs three sequential value-noise samples per pixel —
//      cheaper than the FBM-based clouds (no octave loop) but the chain
//      dependency limits parallelism. Keep to one full-screen instance.
//    - When `showsControls` is `true`, the gear button is a native
//      `ToolbarItem` — the call site must be inside a `NavigationStack`.
//
//  Created by Wei Zhong on 5/20/26.
//

import SwiftUI

// MARK: - Main View

struct SWLiquidChrome: View {
    /// Color of the chrome shadow valleys.
    var shadow: Color = Color(red: 0.020, green: 0.012, blue: 0.051)   // #05030D

    /// Mid-tone metallic color.
    var silver: Color = Color(red: 0.2,   green: 0.2,   blue: 0.251)   // #333340

    /// Color of the brightest reflections.
    var highlight: Color = Color(red: 0.502, green: 0.502, blue: 0.6)  // #808099

    /// Subtle accent layered in via the first warp sample.
    var tint: Color = Color(red: 0.149, green: 0.2,   blue: 0.4)       // #263366

    /// Multiplier on the internal time evolution.
    var speed: Float = 0.3

    /// Spatial scale of the noise field.
    var scale: Float = 2.0

    /// Strength of the inter-sample domain warp.
    var warp: Float = 1.5

    /// Gamma exponent on the chrome curve.
    var contrast: Float = 0.6

    /// Exponent of the specular power-curve — higher = tighter glints.
    var specPower: Float = 12

    /// Multiplier on the specular additive layer.
    var specStrength: Float = 0.3

    /// Multiplier on the tint additive layer.
    var tintStrength: Float = 0.15

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWLiquidChromeControlled(initial: self)
        } else {
            SWLiquidChromeRenderer(
                shadow: shadow,
                silver: silver,
                highlight: highlight,
                tint: tint,
                speed: speed,
                scale: scale,
                warp: warp,
                contrast: contrast,
                specPower: specPower,
                specStrength: specStrength,
                tintStrength: tintStrength
            )
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWLiquidChromeRenderer: View {
    let shadow: Color
    let silver: Color
    let highlight: Color
    let tint: Color
    let speed: Float
    let scale: Float
    let warp: Float
    let contrast: Float
    let specPower: Float
    let specStrength: Float
    let tintStrength: Float

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            // First-frame base color before the shader runs — using `silver`
            // (mid-tone metallic) avoids a black flash on initial layout.
            silver
                .colorEffect(
                    ShaderLibrary.swLiquidChrome(
                        .boundingRect,
                        .float(elapsed),
                        .float(speed),
                        .float(scale),
                        .float(warp),
                        .float(contrast),
                        .float(specPower),
                        .float(specStrength),
                        .float(tintStrength),
                        .color(shadow),
                        .color(silver),
                        .color(highlight),
                        .color(tint)
                    )
                )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWLiquidChromeControlled: View {
    @State private var shadow: Color
    @State private var silver: Color
    @State private var highlight: Color
    @State private var tint: Color
    @State private var speed: Float
    @State private var scale: Float
    @State private var warp: Float
    @State private var contrast: Float
    @State private var specPower: Float
    @State private var specStrength: Float
    @State private var tintStrength: Float

    @State private var showSheet = false

    init(initial: SWLiquidChrome) {
        _shadow       = State(initialValue: initial.shadow)
        _silver       = State(initialValue: initial.silver)
        _highlight    = State(initialValue: initial.highlight)
        _tint         = State(initialValue: initial.tint)
        _speed        = State(initialValue: initial.speed)
        _scale        = State(initialValue: initial.scale)
        _warp         = State(initialValue: initial.warp)
        _contrast     = State(initialValue: initial.contrast)
        _specPower    = State(initialValue: initial.specPower)
        _specStrength = State(initialValue: initial.specStrength)
        _tintStrength = State(initialValue: initial.tintStrength)
    }

    var body: some View {
        SWLiquidChromeRenderer(
            shadow: shadow,
            silver: silver,
            highlight: highlight,
            tint: tint,
            speed: speed,
            scale: scale,
            warp: warp,
            contrast: contrast,
            specPower: specPower,
            specStrength: specStrength,
            tintStrength: tintStrength
        )
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Liquid Chrome Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWLiquidChromeControlsSheet(
                shadow: $shadow,
                silver: $silver,
                highlight: $highlight,
                tint: $tint,
                speed: $speed,
                scale: $scale,
                warp: $warp,
                contrast: $contrast,
                specPower: $specPower,
                specStrength: $specStrength,
                tintStrength: $tintStrength
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWLiquidChromeControlsSheet: View {
    @Binding var shadow: Color
    @Binding var silver: Color
    @Binding var highlight: Color
    @Binding var tint: Color
    @Binding var speed: Float
    @Binding var scale: Float
    @Binding var warp: Float
    @Binding var contrast: Float
    @Binding var specPower: Float
    @Binding var specStrength: Float
    @Binding var tintStrength: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Colors") {
                    ColorPicker("Shadow",    selection: $shadow,    supportsOpacity: false)
                    ColorPicker("Silver",    selection: $silver,    supportsOpacity: false)
                    ColorPicker("Highlight", selection: $highlight, supportsOpacity: false)
                    ColorPicker("Tint",      selection: $tint,      supportsOpacity: false)
                }

                Section("Surface") {
                    SliderRow(label: "Scale",    value: $scale,    range: 0.2...5, step: 0.05)
                    SliderRow(label: "Warp",     value: $warp,     range: 0...5,   step: 0.05)
                    SliderRow(label: "Contrast", value: $contrast, range: 0.1...3, step: 0.05)
                }

                Section("Lighting") {
                    SliderRow(label: "Spec Power",    value: $specPower,    range: 1...50, step: 0.5)
                    SliderRow(label: "Spec Strength", value: $specStrength, range: 0...2,  step: 0.05)
                    SliderRow(label: "Tint Strength", value: $tintStrength, range: 0...2,  step: 0.05)
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Liquid Chrome")
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

#Preview {
    // ToolbarItem requires an enclosing NavigationStack to render.
    NavigationStack {
        SWLiquidChrome(showsControls: true)
    }
}
