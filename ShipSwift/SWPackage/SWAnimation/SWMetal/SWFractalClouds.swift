//
//  SWFractalClouds.swift
//  ShipSwift
//
//  Drifting fractal clouds rendered via a SwiftUI Metal stitchable shader.
//  Two-pass FBM (5-octave value noise) — the first pass warps the sample
//  position for the second, producing soft cumulus-like swirls. Sky and
//  cloud colors are mixed by the warped FBM, with an optional warm tint
//  layered on top of the unwarped pass for ambient lift.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — twilight cumulus, full-screen
//    ZStack {
//        SWFractalClouds()
//            .ignoresSafeArea()
//        // Your content here
//    }
//
//    // Recolor — daylight sky
//    SWFractalClouds(
//        skyColor: .blue.opacity(0.5),
//        cloudColor: .white,
//        warmth: 0.0
//    )
//
//    // As a section background
//    myContent
//        .background { SWFractalClouds() }
//
//    // Demo / debug — adds a gear button in the navigation bar that
//    // opens a sheet to tweak every parameter live. Disabled by default.
//    SWFractalClouds(showsControls: true)
//
//  Parameters:
//    - skyColor: Color of the open sky behind the clouds
//                (default deep twilight blue `#1A2659`)
//    - cloudColor: Color of the cloud body
//                  (default soft lilac white `#E6E6FF`)
//    - warmTint: Color added on top of the unwarped FBM for ambient lift
//                (default deep amber `#1A0D00` — barely lifts shadows)
//    - warmth: Multiplier applied to the warm tint additive layer
//              (default `0.5`)
//    - speed: Time multiplier driving drift and warp evolution
//             (default `1.0`)
//    - zoom: FBM sampling scale — higher = larger, fewer cloud features
//            (default `3.0`)
//    - driftX: Horizontal drift velocity (default `0.08`)
//    - driftY: Vertical drift velocity (default `0.04`)
//    - warp: Strength of the first FBM warping the second's sample position
//            (default `2.0`, `0.0` disables warp = pure FBM)
//    - coverage: Added to the warped FBM before clamping — positive widens
//                cloud coverage, negative opens the sky (default `0.0`)
//    - showsControls: When `true`, adds a gear `ToolbarItem` to the
//                     enclosing `NavigationStack` that opens a
//                     live-tuning sheet. Default `false`.
//
//  Notes:
//    - The shader runs two 5-octave FBM evaluations per pixel — cost is
//      higher than the SWDots family. Keep to one full-screen instance.
//    - `zoom` is clamped internally to `>= 0.0001` to avoid division-style
//      blowups in the noise lookup; setting it to 0 still renders cleanly.
//    - When `showsControls` is `true`, the gear button is registered as a
//      native `ToolbarItem`, so the call site must be inside a
//      `NavigationStack`. Bare `#Preview` wraps it with `NavigationStack { … }`.
//
//  Created by Wei Zhong on 5/20/26.
//

import SwiftUI

// MARK: - Main View

struct SWFractalClouds: View {
    /// Sky color behind the clouds.
    var skyColor: Color = Color(red: 0.102, green: 0.149, blue: 0.349)   // #1A2659

    /// Cloud body color.
    var cloudColor: Color = Color(red: 0.902, green: 0.902, blue: 1.0)   // #E6E6FF

    /// Warm tint added on top of the unwarped FBM for ambient lift.
    var warmTint: Color = Color(red: 0.102, green: 0.051, blue: 0.0)     // #1A0D00

    /// Multiplier applied to the warm tint additive layer.
    var warmth: Float = 0.5

    /// Time multiplier driving drift and warp evolution.
    var speed: Float = 1.0

    /// FBM sampling scale — higher = larger features.
    var zoom: Float = 3.0

    /// Horizontal drift velocity.
    var driftX: Float = 0.08

    /// Vertical drift velocity.
    var driftY: Float = 0.04

    /// Strength of the first FBM warping the second's sample position.
    var warp: Float = 2.0

    /// Added to the warped FBM before clamping — positive widens coverage.
    var coverage: Float = 0.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWFractalCloudsControlled(initial: self)
        } else {
            SWFractalCloudsRenderer(
                skyColor: skyColor,
                cloudColor: cloudColor,
                warmTint: warmTint,
                warmth: warmth,
                speed: speed,
                zoom: zoom,
                driftX: driftX,
                driftY: driftY,
                warp: warp,
                coverage: coverage
            )
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWFractalCloudsRenderer: View {
    let skyColor: Color
    let cloudColor: Color
    let warmTint: Color
    let warmth: Float
    let speed: Float
    let zoom: Float
    let driftX: Float
    let driftY: Float
    let warp: Float
    let coverage: Float

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            // The base layer is the cloud color — the shader fully overwrites
            // every pixel, so the choice is cosmetic, but using cloudColor
            // gives a sensible look during the first frame before TimelineView
            // ticks in.
            cloudColor
                .colorEffect(
                    ShaderLibrary.swFractalClouds(
                        .boundingRect,
                        .float(elapsed),
                        .float(speed),
                        .float(zoom),
                        .float(driftX),
                        .float(driftY),
                        .float(warp),
                        .float(coverage),
                        .color(skyColor),
                        .color(cloudColor),
                        .color(warmTint),
                        .float(warmth)
                    )
                )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWFractalCloudsControlled: View {
    @State private var skyColor: Color
    @State private var cloudColor: Color
    @State private var warmTint: Color
    @State private var warmth: Float
    @State private var speed: Float
    @State private var zoom: Float
    @State private var driftX: Float
    @State private var driftY: Float
    @State private var warp: Float
    @State private var coverage: Float

    @State private var showSheet = false

    init(initial: SWFractalClouds) {
        _skyColor   = State(initialValue: initial.skyColor)
        _cloudColor = State(initialValue: initial.cloudColor)
        _warmTint   = State(initialValue: initial.warmTint)
        _warmth     = State(initialValue: initial.warmth)
        _speed      = State(initialValue: initial.speed)
        _zoom       = State(initialValue: initial.zoom)
        _driftX     = State(initialValue: initial.driftX)
        _driftY     = State(initialValue: initial.driftY)
        _warp       = State(initialValue: initial.warp)
        _coverage   = State(initialValue: initial.coverage)
    }

    var body: some View {
        SWFractalCloudsRenderer(
            skyColor: skyColor,
            cloudColor: cloudColor,
            warmTint: warmTint,
            warmth: warmth,
            speed: speed,
            zoom: zoom,
            driftX: driftX,
            driftY: driftY,
            warp: warp,
            coverage: coverage
        )
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Fractal Clouds Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWFractalCloudsControlsSheet(
                skyColor: $skyColor,
                cloudColor: $cloudColor,
                warmTint: $warmTint,
                warmth: $warmth,
                speed: $speed,
                zoom: $zoom,
                driftX: $driftX,
                driftY: $driftY,
                warp: $warp,
                coverage: $coverage
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWFractalCloudsControlsSheet: View {
    @Binding var skyColor: Color
    @Binding var cloudColor: Color
    @Binding var warmTint: Color
    @Binding var warmth: Float
    @Binding var speed: Float
    @Binding var zoom: Float
    @Binding var driftX: Float
    @Binding var driftY: Float
    @Binding var warp: Float
    @Binding var coverage: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Colors") {
                    ColorPicker("Sky",        selection: $skyColor,   supportsOpacity: false)
                    ColorPicker("Cloud",      selection: $cloudColor, supportsOpacity: false)
                    ColorPicker("Warm Tint",  selection: $warmTint,   supportsOpacity: false)
                }

                Section("Shape") {
                    SliderRow(label: "Zoom",     value: $zoom,     range: 0.5...10, step: 0.1)
                    SliderRow(label: "Coverage", value: $coverage, range: -1...1,   step: 0.05)
                    SliderRow(label: "Warp",     value: $warp,     range: 0...5,    step: 0.05)
                    SliderRow(label: "Warmth",   value: $warmth,   range: 0...2,    step: 0.05)
                }

                Section("Motion") {
                    SliderRow(label: "Speed",   value: $speed,  range: 0...3,        step: 0.05)
                    SliderRow(label: "Drift X", value: $driftX, range: -0.5...0.5,   step: 0.01)
                    SliderRow(label: "Drift Y", value: $driftY, range: -0.5...0.5,   step: 0.01)
                }
            }
            .navigationTitle("Fractal Clouds")
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
        SWFractalClouds(showsControls: true)
    }
}
