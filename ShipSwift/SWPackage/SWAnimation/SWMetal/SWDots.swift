//
//  SWDots.swift
//  ShipSwift
//
//  Family of perspective dot-grid backgrounds rendered via SwiftUI Metal
//  stitchable shaders. Switch between visual styles (wavy / mountains / …)
//  with a single enum and reuse the same 11-parameter knob set across all
//  variants. Optionally render an in-place control panel for live tuning.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Each style is implemented in its own `.metal` file under `SWMetal/`,
//  exporting a stitchable function named `swDots<Style>` (e.g. `swDotsWavy`,
//  `swDotsMountains`). Add a new style by:
//    1. Dropping `SWDots<Style>.metal` next to this file.
//    2. Adding a case to `SWDotsStyle`.
//    3. Mapping the case to its shader name in `shaderName`.
//
//  Usage:
//    // Default — wavy, white dots on black, full-screen
//    ZStack {
//        SWDots()
//            .ignoresSafeArea()
//        // Your content here
//    }
//
//    // Pick a style and recolor
//    SWDots(style: .mountains, tint: .cyan, amplitude: 1.4)
//
//    // As a section background
//    myContent
//        .background { SWDots(style: .wavy) }
//
//    // Demo / debug — adds a gear button at the top-right that opens a
//    // sheet to tweak every parameter live. Disabled by default.
//    SWDots(style: .wavy, showsControls: true)
//
//  Parameters:
//    - style: Which dot-field style to render (default `.wavy`)
//    - tint: Color of dots and their halos (default `.white`)
//    - background: Color rendered below the horizon and behind the dots
//                  (default `.black`)
//    - speed: Time multiplier driving wave motion (default `1.0`)
//    - brightness: Multiplier applied to the tint color before mixing
//                  (default `1.0`)
//    - dotSize: Per-dot pixel radius multiplier (default `1.0`)
//    - gridDensity: Grid density multiplier (default `1.0`)
//    - patternScale: Spatial frequency multiplier (default `1.0`)
//    - amplitude: Wave height multiplier (default `1.0`)
//    - depthFade: Per-dot depth attenuation strength (default `1.0`)
//    - vignette: Screen-edge vignette darkening (default `1.0`, `0.0` disables)
//    - horizon: Horizon line position in screen-aspect units, negative
//               raises the horizon (default `-0.45`)
//    - showsControls: When `true`, overlays a gear button that opens a
//                     parameter-tweaking sheet. Use only for demos /
//                     prototyping. Default `false`.
//
//  Notes:
//    - The dot field only renders below the horizon line. Place legible
//      foreground content above the horizon or use strong contrast.
//    - Cost scales with view area and `gridDensity`. Keep one instance
//      per screen.
//    - When `showsControls` is `true`, the values passed via the
//      initializer become the *initial* values of the live-tweakable
//      state; subsequent changes from the parent are ignored.
//    - When `showsControls` is `true`, the gear button is registered as
//      a native `ToolbarItem` (placement `.primaryAction`). It therefore
//      requires the host view to be inside a `NavigationStack`. When
//      shown without one (e.g. a bare `#Preview`), wrap the call site:
//          NavigationStack { SWDots(showsControls: true) }
//
//  Created by Wei Zhong on 5/20/26.
//

import SwiftUI

// MARK: - Style

enum SWDotsStyle: String, CaseIterable, Identifiable {
    // 3D perspective styles — dots sit on a wave-displaced ground plane.
    case wavy
    case mountains
    case ocean
    case standing

    // Flat-grid styles — dots tile the screen without perspective.
    case flow
    case plasma
    case snake

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wavy:      "Wavy"
        case .mountains: "Mountains"
        case .ocean:     "Ocean"
        case .standing:  "Standing"
        case .flow:      "Flow"
        case .plasma:    "Plasma"
        case .snake:     "Snake"
        }
    }

    /// Metal `stitchable` function name in the default `ShaderLibrary`.
    var shaderName: String {
        switch self {
        case .wavy:      "swDotsWavy"
        case .mountains: "swDotsMountains"
        case .ocean:     "swDotsOcean"
        case .standing:  "swDotsStanding"
        case .flow:      "swDotsFlow"
        case .plasma:    "swDotsPlasma"
        case .snake:     "swDotsSnake"
        }
    }

    /// Whether this style projects dots in 3D perspective onto a ground
    /// plane. 3D styles consume the `horizon`, `amplitude`, and `depthFade`
    /// parameters; flat-grid styles ignore them (the shader signature still
    /// accepts them for a unified call site, but the values do nothing).
    var is3D: Bool {
        switch self {
        case .wavy, .mountains, .ocean, .standing: true
        case .flow, .plasma, .snake:               false
        }
    }
}

// MARK: - Main View

struct SWDots: View {
    /// Which dot-field style to render.
    var style: SWDotsStyle = .wavy

    /// Color of dots and their halos.
    var tint: Color = .white

    /// Color rendered below the horizon and behind the dots.
    var background: Color = .black

    /// Time multiplier driving wave motion.
    var speed: Float = 1.0

    /// Multiplier applied to the tint color before mixing.
    var brightness: Float = 1.0

    /// Per-dot pixel radius multiplier.
    var dotSize: Float = 1.0

    /// Grid density multiplier.
    var gridDensity: Float = 1.0

    /// Spatial frequency multiplier for the wave pattern.
    var patternScale: Float = 1.0

    /// Wave height multiplier.
    var amplitude: Float = 1.0

    /// Strength of the per-dot depth attenuation.
    var depthFade: Float = 1.0

    /// Strength of the screen-edge vignette darkening.
    var vignette: Float = 1.0

    /// Vertical horizon position in screen-aspect units.
    var horizon: Float = -0.45

    /// When `true`, overlays a gear button that opens a live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWDotsControlled(initial: self)
        } else {
            SWDotsRenderer(
                style: style,
                tint: tint,
                background: background,
                speed: speed,
                brightness: brightness,
                dotSize: dotSize,
                gridDensity: gridDensity,
                patternScale: patternScale,
                amplitude: amplitude,
                depthFade: depthFade,
                vignette: vignette,
                horizon: horizon
            )
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWDotsRenderer: View {
    let style: SWDotsStyle
    let tint: Color
    let background: Color
    let speed: Float
    let brightness: Float
    let dotSize: Float
    let gridDensity: Float
    let patternScale: Float
    let amplitude: Float
    let depthFade: Float
    let vignette: Float
    let horizon: Float

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            background
                .colorEffect(
                    Shader(
                        function: ShaderFunction(library: .default, name: style.shaderName),
                        arguments: [
                            .boundingRect,
                            .float(elapsed),
                            .float(speed),
                            .float(brightness),
                            .color(tint),
                            .color(background),
                            .float(dotSize),
                            .float(gridDensity),
                            .float(patternScale),
                            .float(vignette),
                            .float(horizon),
                            .float(amplitude),
                            .float(depthFade)
                        ]
                    )
                )
        }
    }
}

// MARK: - Controlled Wrapper (gear button + live sheet)

private struct SWDotsControlled: View {
    @State private var style: SWDotsStyle
    @State private var tint: Color
    @State private var background: Color
    @State private var speed: Float
    @State private var brightness: Float
    @State private var dotSize: Float
    @State private var gridDensity: Float
    @State private var patternScale: Float
    @State private var amplitude: Float
    @State private var depthFade: Float
    @State private var vignette: Float
    @State private var horizon: Float

    @State private var showSheet = false

    init(initial: SWDots) {
        _style        = State(initialValue: initial.style)
        _tint         = State(initialValue: initial.tint)
        _background   = State(initialValue: initial.background)
        _speed        = State(initialValue: initial.speed)
        _brightness   = State(initialValue: initial.brightness)
        _dotSize      = State(initialValue: initial.dotSize)
        _gridDensity  = State(initialValue: initial.gridDensity)
        _patternScale = State(initialValue: initial.patternScale)
        _amplitude    = State(initialValue: initial.amplitude)
        _depthFade    = State(initialValue: initial.depthFade)
        _vignette     = State(initialValue: initial.vignette)
        _horizon      = State(initialValue: initial.horizon)
    }

    var body: some View {
        SWDotsRenderer(
            style: style,
            tint: tint,
            background: background,
            speed: speed,
            brightness: brightness,
            dotSize: dotSize,
            gridDensity: gridDensity,
            patternScale: patternScale,
            amplitude: amplitude,
            depthFade: depthFade,
            vignette: vignette,
            horizon: horizon
        )
        .ignoresSafeArea()
        .toolbar {
            // Native toolbar item — sits in the navigation bar of the
            // enclosing `NavigationStack`, so hit-testing is handled by
            // UIKit/AppKit and the button is never occluded by the bar.
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Dots Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWDotsControlsSheet(
                style: $style,
                tint: $tint,
                background: $background,
                speed: $speed,
                brightness: $brightness,
                dotSize: $dotSize,
                gridDensity: $gridDensity,
                patternScale: $patternScale,
                amplitude: $amplitude,
                depthFade: $depthFade,
                vignette: $vignette,
                horizon: $horizon
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWDotsControlsSheet: View {
    @Binding var style: SWDotsStyle
    @Binding var tint: Color
    @Binding var background: Color
    @Binding var speed: Float
    @Binding var brightness: Float
    @Binding var dotSize: Float
    @Binding var gridDensity: Float
    @Binding var patternScale: Float
    @Binding var amplitude: Float
    @Binding var depthFade: Float
    @Binding var vignette: Float
    @Binding var horizon: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Style") {
                    Picker("Style", selection: $style) {
                        ForEach(SWDotsStyle.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                }

                Section("Colors") {
                    ColorPicker("Dot Color", selection: $tint, supportsOpacity: false)
                    ColorPicker("Background", selection: $background, supportsOpacity: false)
                }

                Section("Sliders") {
                    SliderRow(label: "Speed",         value: $speed,        range: 0...3,   step: 0.05)
                    SliderRow(label: "Brightness",    value: $brightness,   range: 0...3,   step: 0.05)
                    SliderRow(label: "Dot Size",      value: $dotSize,      range: 0.2...3, step: 0.05)
                    SliderRow(label: "Grid Density",  value: $gridDensity,  range: 0.3...3, step: 0.05)
                    SliderRow(label: "Pattern Scale", value: $patternScale, range: 0.2...3, step: 0.05)
                    SliderRow(label: "Vignette",      value: $vignette,     range: 0...3,   step: 0.05)

                    // Hidden for flat-grid styles whose shaders ignore these.
                    if style.is3D {
                        SliderRow(label: "Wave Amplitude", value: $amplitude, range: 0...3,      step: 0.05)
                        SliderRow(label: "Depth Fade",     value: $depthFade, range: 0...3,      step: 0.05)
                        SliderRow(label: "Horizon",        value: $horizon,   range: -1.0...0.4, step: 0.01)
                    }
                }
            }
            .navigationTitle("Dots Controls")
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
        SWDots(showsControls: true)
    }
}
