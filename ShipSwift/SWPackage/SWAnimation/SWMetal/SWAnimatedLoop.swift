//
//  SWAnimatedLoop.swift
//  ShipSwift
//
//  Pulsing rings in one of four hand-tuned styles (Shape / Diamond / Neon /
//  Warp), rendered via SwiftUI Metal stitchable shaders. The `Shape` style
//  additionally exposes a 5-way geometric selector (circle / square /
//  diamond / hexagon / star). All four styles share the same parameter
//  surface; Neon adds three angular-wobble parameters on top.
//
//  Requires iOS 18+ / macOS 15+.
//
//  Usage:
//    // Default — Shape style, circle, red/green/blue rings on black
//    ZStack {
//        SWAnimatedLoop()
//            .ignoresSafeArea()
//    }
//
//    // Switch styles — each style auto-loads its hand-tuned numeric defaults
//    SWAnimatedLoop(style: .diamond)
//    SWAnimatedLoop(style: .neon)
//    SWAnimatedLoop(style: .warp)
//
//    // Within Shape style, pick a geometric shape
//    SWAnimatedLoop(style: .shape, shape: .hexagon)
//    SWAnimatedLoop(style: .shape, shape: .star, petals: 7)
//
//    // As a section background
//    myContent
//        .background { SWAnimatedLoop(style: .neon) }
//
//    // Demo / debug — adds a gear button in the navigation bar that opens
//    // a sheet to tweak every parameter live. Disabled by default.
//    SWAnimatedLoop(showsControls: true)
//
//  Parameters:
//    - style: One of `.shape / .diamond / .neon / .warp` (default `.shape`)
//    - shape: Geometric shape, only honored when `style == .shape`
//             (default `.circle`)
//    - petals: Number of star points, only honored when
//              `style == .shape && shape == .star` (default `5`)
//    - color1, color2, color3: Three RGB channel colors (default red/green/blue)
//    - background: Color rendered behind the rings (default `.black`)
//    - speed: Time multiplier on the ring sweep (style-specific default)
//    - lineWidth: Per-ring line thickness (default `0.002`)
//    - lines: Number of concentric rings (style-specific default)
//    - spacing: Distance multiplier between rings (style-specific default)
//    - channelOffset: Phase offset between RGB channels (style-specific default)
//    - patternMod: Period of the pattern term overlaid on the rings
//                  (style-specific default)
//    - rotation: Rotation in radians (default `0`)
//    - scale: Spatial scale (default `1.0`)
//    - centerX, centerY: Ring origin offset (default `0, 0`)
//    - angularLobes, angularAmount, angularSpeed: Per-channel angular wobble
//             added by the Neon style only (defaults `3.0`, `0.08`, `0.5`)
//    - showsControls: Demo gear `ToolbarItem`. Default `false`.
//
//  Notes:
//    - When `showsControls` is `true`, the sheet's Style picker resets the
//      numeric ring parameters (`speed`, `lines`, `spacing`, `channelOffset`,
//      `patternMod`) to the new style's hand-tuned defaults — intentional,
//      so each style ships with the look its author designed.
//    - The Shape selector and Star points slider are hidden in the sheet
//      unless `style == .shape`. The Angular section appears only for
//      `style == .neon`. Parameters that don't apply to the current style
//      are still passed to the shader but ignored there.
//    - The gear button is a native `ToolbarItem` — the call site must be
//      inside a `NavigationStack`.
//
//  Created by Wei Zhong on 5/20/26.
//

import SwiftUI

// MARK: - Style

enum SWAnimatedLoopStyle: String, CaseIterable, Identifiable {
    case shape
    case diamond
    case neon
    case warp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shape:   "Shape"
        case .diamond: "Diamond"
        case .neon:    "Neon"
        case .warp:    "Warp"
        }
    }

    /// Metal `stitchable` function name in the default `ShaderLibrary`.
    var shaderName: String {
        switch self {
        case .shape:   "swAnimatedLoopShape"
        case .diamond: "swAnimatedLoopDiamond"
        case .neon:    "swAnimatedLoopNeon"
        case .warp:    "swAnimatedLoopWarp"
        }
    }

    /// Whether this style consumes the `shape` parameter (Shape style only).
    var supportsShape: Bool { self == .shape }

    /// Whether this style consumes the angular-wobble parameters (Neon only).
    var supportsAngular: Bool { self == .neon }

    /// Hand-tuned numeric defaults for this style. Loaded by `SWAnimatedLoop`'s
    /// initializer and reloaded by the controls sheet on style change.
    struct NumericDefaults {
        var speed: Float
        var lineWidth: Float
        var lines: Int
        var spacing: Float
        var channelOffset: Float
        var patternMod: Float
    }

    var numericDefaults: NumericDefaults {
        switch self {
        case .shape:
            return NumericDefaults(speed: 0.05, lineWidth: 0.002, lines: 5,
                                   spacing: 5.0, channelOffset: 0.01, patternMod: 0.2)
        case .diamond:
            return NumericDefaults(speed: 0.05, lineWidth: 0.002, lines: 6,
                                   spacing: 5.0, channelOffset: 0.01, patternMod: 0.15)
        case .neon:
            return NumericDefaults(speed: 0.06, lineWidth: 0.002, lines: 5,
                                   spacing: 5.0, channelOffset: 0.01, patternMod: 0.2)
        case .warp:
            return NumericDefaults(speed: 0.07, lineWidth: 0.002, lines: 6,
                                   spacing: 4.0, channelOffset: 0.008, patternMod: 0.3)
        }
    }
}

// MARK: - Shape

enum SWAnimatedLoopShape: Int, CaseIterable, Identifiable {
    case circle  = 0
    case square  = 1
    case diamond = 2
    case hexagon = 3
    case star    = 4

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .circle:  "Circle"
        case .square:  "Square"
        case .diamond: "Diamond"
        case .hexagon: "Hexagon"
        case .star:    "Star"
        }
    }
}

// MARK: - Main View

struct SWAnimatedLoop: View {
    var style: SWAnimatedLoopStyle
    var shape: SWAnimatedLoopShape
    var petals: Int

    var color1: Color
    var color2: Color
    var color3: Color
    var background: Color

    var speed: Float
    var lineWidth: Float
    var lines: Int
    var spacing: Float
    var channelOffset: Float
    var patternMod: Float

    var rotation: Float
    var scale: Float
    var centerX: Float
    var centerY: Float

    var angularLobes: Float
    var angularAmount: Float
    var angularSpeed: Float

    var showsControls: Bool

    /// Designated initializer. Any numeric ring parameter passed as `nil`
    /// falls back to the `style`'s `numericDefaults`, so each style is one
    /// line to render: `SWAnimatedLoop(style: .warp)` is enough.
    init(
        style: SWAnimatedLoopStyle = .shape,
        shape: SWAnimatedLoopShape = .circle,
        petals: Int = 5,
        color1: Color = .red,
        color2: Color = .green,
        color3: Color = .blue,
        background: Color = .black,
        speed: Float? = nil,
        lineWidth: Float? = nil,
        lines: Int? = nil,
        spacing: Float? = nil,
        channelOffset: Float? = nil,
        patternMod: Float? = nil,
        rotation: Float = 0.0,
        scale: Float = 1.0,
        centerX: Float = 0.0,
        centerY: Float = 0.0,
        angularLobes: Float = 3.0,
        angularAmount: Float = 0.08,
        angularSpeed: Float = 0.5,
        showsControls: Bool = false
    ) {
        let d = style.numericDefaults
        self.style          = style
        self.shape          = shape
        self.petals         = petals
        self.color1         = color1
        self.color2         = color2
        self.color3         = color3
        self.background     = background
        self.speed          = speed         ?? d.speed
        self.lineWidth      = lineWidth     ?? d.lineWidth
        self.lines          = lines         ?? d.lines
        self.spacing        = spacing       ?? d.spacing
        self.channelOffset  = channelOffset ?? d.channelOffset
        self.patternMod     = patternMod    ?? d.patternMod
        self.rotation       = rotation
        self.scale          = scale
        self.centerX        = centerX
        self.centerY        = centerY
        self.angularLobes   = angularLobes
        self.angularAmount  = angularAmount
        self.angularSpeed   = angularSpeed
        self.showsControls  = showsControls
    }

    var body: some View {
        if showsControls {
            SWAnimatedLoopControlled(initial: self)
        } else {
            SWAnimatedLoopRenderer(
                style: style,
                shape: shape,
                petals: petals,
                color1: color1,
                color2: color2,
                color3: color3,
                background: background,
                speed: speed,
                lineWidth: lineWidth,
                lines: lines,
                spacing: spacing,
                channelOffset: channelOffset,
                patternMod: patternMod,
                rotation: rotation,
                scale: scale,
                centerX: centerX,
                centerY: centerY,
                angularLobes: angularLobes,
                angularAmount: angularAmount,
                angularSpeed: angularSpeed
            )
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWAnimatedLoopRenderer: View {
    let style: SWAnimatedLoopStyle
    let shape: SWAnimatedLoopShape
    let petals: Int
    let color1: Color
    let color2: Color
    let color3: Color
    let background: Color
    let speed: Float
    let lineWidth: Float
    let lines: Int
    let spacing: Float
    let channelOffset: Float
    let patternMod: Float
    let rotation: Float
    let scale: Float
    let centerX: Float
    let centerY: Float
    let angularLobes: Float
    let angularAmount: Float
    let angularSpeed: Float

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
                            .float(lineWidth),
                            .float(Float(lines)),
                            .float(spacing),
                            .float(channelOffset),
                            .float(patternMod),
                            .float(rotation),
                            .float(scale),
                            .float2(centerX, centerY),
                            .float(Float(shape.rawValue)),
                            .float(Float(petals)),
                            .float(angularLobes),
                            .float(angularAmount),
                            .float(angularSpeed),
                            .color(color1),
                            .color(color2),
                            .color(color3),
                            .color(background)
                        ]
                    )
                )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWAnimatedLoopControlled: View {
    @State private var style: SWAnimatedLoopStyle
    @State private var shape: SWAnimatedLoopShape
    @State private var petals: Float
    @State private var color1: Color
    @State private var color2: Color
    @State private var color3: Color
    @State private var background: Color
    @State private var speed: Float
    @State private var lineWidth: Float
    @State private var lines: Float
    @State private var spacing: Float
    @State private var channelOffset: Float
    @State private var patternMod: Float
    @State private var rotation: Float
    @State private var scale: Float
    @State private var centerX: Float
    @State private var centerY: Float
    @State private var angularLobes: Float
    @State private var angularAmount: Float
    @State private var angularSpeed: Float

    @State private var showSheet = false

    init(initial: SWAnimatedLoop) {
        _style         = State(initialValue: initial.style)
        _shape         = State(initialValue: initial.shape)
        _petals        = State(initialValue: Float(initial.petals))
        _color1        = State(initialValue: initial.color1)
        _color2        = State(initialValue: initial.color2)
        _color3        = State(initialValue: initial.color3)
        _background    = State(initialValue: initial.background)
        _speed         = State(initialValue: initial.speed)
        _lineWidth     = State(initialValue: initial.lineWidth)
        _lines         = State(initialValue: Float(initial.lines))
        _spacing       = State(initialValue: initial.spacing)
        _channelOffset = State(initialValue: initial.channelOffset)
        _patternMod    = State(initialValue: initial.patternMod)
        _rotation      = State(initialValue: initial.rotation)
        _scale         = State(initialValue: initial.scale)
        _centerX       = State(initialValue: initial.centerX)
        _centerY       = State(initialValue: initial.centerY)
        _angularLobes  = State(initialValue: initial.angularLobes)
        _angularAmount = State(initialValue: initial.angularAmount)
        _angularSpeed  = State(initialValue: initial.angularSpeed)
    }

    /// Builder that produces a fresh renderer using the current
    /// live-tweaked state. Wrapped in a helper so the `body` stays short
    /// despite the renderer's 19-parameter initializer.
    private func makeRenderer() -> SWAnimatedLoopRenderer {
        SWAnimatedLoopRenderer(
            style: style,
            shape: shape,
            petals: Int(petals.rounded()),
            color1: color1,
            color2: color2,
            color3: color3,
            background: background,
            speed: speed,
            lineWidth: lineWidth,
            lines: Int(lines.rounded()),
            spacing: spacing,
            channelOffset: channelOffset,
            patternMod: patternMod,
            rotation: rotation,
            scale: scale,
            centerX: centerX,
            centerY: centerY,
            angularLobes: angularLobes,
            angularAmount: angularAmount,
            angularSpeed: angularSpeed
        )
    }

    var body: some View {
        // Style switching, parameter tweaks, and color picking all live in
        // the sheet — the body itself is just the full-screen renderer of
        // whichever style is currently selected.
        makeRenderer()
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel("Animated Loop Controls")
                }
            }
            .sheet(isPresented: $showSheet) {
            SWAnimatedLoopControlsSheet(
                style: $style,
                shape: $shape,
                petals: $petals,
                color1: $color1,
                color2: $color2,
                color3: $color3,
                background: $background,
                speed: $speed,
                lineWidth: $lineWidth,
                lines: $lines,
                spacing: $spacing,
                channelOffset: $channelOffset,
                patternMod: $patternMod,
                rotation: $rotation,
                scale: $scale,
                centerX: $centerX,
                centerY: $centerY,
                angularLobes: $angularLobes,
                angularAmount: $angularAmount,
                angularSpeed: $angularSpeed,
                applyDefaults: applyDefaults
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    /// Loads `style`'s hand-tuned numeric defaults into the live state.
    /// Invoked by the sheet's `onChange(style)` so each style ships with
    /// the ring parameters its author designed.
    private func applyDefaults(for s: SWAnimatedLoopStyle) {
        let d = s.numericDefaults
        speed         = d.speed
        lineWidth     = d.lineWidth
        lines         = Float(d.lines)
        spacing       = d.spacing
        channelOffset = d.channelOffset
        patternMod    = d.patternMod
    }
}

// MARK: - Controls Sheet

private struct SWAnimatedLoopControlsSheet: View {
    @Binding var style: SWAnimatedLoopStyle
    @Binding var shape: SWAnimatedLoopShape
    @Binding var petals: Float
    @Binding var color1: Color
    @Binding var color2: Color
    @Binding var color3: Color
    @Binding var background: Color
    @Binding var speed: Float
    @Binding var lineWidth: Float
    @Binding var lines: Float
    @Binding var spacing: Float
    @Binding var channelOffset: Float
    @Binding var patternMod: Float
    @Binding var rotation: Float
    @Binding var scale: Float
    @Binding var centerX: Float
    @Binding var centerY: Float
    @Binding var angularLobes: Float
    @Binding var angularAmount: Float
    @Binding var angularSpeed: Float

    /// Called by the sheet when `style` changes, so the parent can replace
    /// the numeric ring defaults to the new style's hand-tuned values.
    let applyDefaults: (SWAnimatedLoopStyle) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Style") {
                    Picker("Style", selection: $style) {
                        ForEach(SWAnimatedLoopStyle.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                }

                // Shape sub-picker is only meaningful for the Shape style.
                if style.supportsShape {
                    Section("Shape") {
                        Picker("Shape", selection: $shape) {
                            ForEach(SWAnimatedLoopShape.allCases) { s in
                                Text(s.displayName).tag(s)
                            }
                        }

                        if shape == .star {
                            SliderRow(label: "Petals", value: $petals, range: 3...12, step: 1)
                        }
                    }
                }

                Section("Colors") {
                    ColorPicker("Channel 1",  selection: $color1,     supportsOpacity: false)
                    ColorPicker("Channel 2",  selection: $color2,     supportsOpacity: false)
                    ColorPicker("Channel 3",  selection: $color3,     supportsOpacity: false)
                    ColorPicker("Background", selection: $background, supportsOpacity: false)
                }

                Section("Rings") {
                    SliderRow(label: "Lines",          value: $lines,         range: 1...20,        step: 1)
                    SliderRow(label: "Spacing",        value: $spacing,       range: 0.5...20,      step: 0.1)
                    SliderRow(label: "Line Width",     value: $lineWidth,     range: 0.0001...0.02, step: 0.0001)
                    SliderRow(label: "Channel Offset", value: $channelOffset, range: -0.5...0.5,    step: 0.005)
                    SliderRow(label: "Pattern Mod",    value: $patternMod,    range: 0.01...2,      step: 0.01)
                }

                Section("Transform") {
                    SliderRow(label: "Rotation", value: $rotation, range: -3.14...3.14, step: 0.05)
                    SliderRow(label: "Scale",    value: $scale,    range: 0.2...5,      step: 0.05)
                    SliderRow(label: "Center X", value: $centerX,  range: -1...1,       step: 0.05)
                    SliderRow(label: "Center Y", value: $centerY,  range: -1...1,       step: 0.05)
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...1, step: 0.01)
                }

                // Angular controls only apply to the Neon style.
                if style.supportsAngular {
                    Section("Angular (Neon)") {
                        SliderRow(label: "Lobes",  value: $angularLobes,  range: 1...12, step: 1)
                        SliderRow(label: "Amount", value: $angularAmount, range: 0...0.5, step: 0.005)
                        SliderRow(label: "Speed",  value: $angularSpeed,  range: 0...3, step: 0.05)
                    }
                }
            }
            .navigationTitle("Animated Loop")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // Style change → reload that style's hand-tuned numeric defaults
            // so each style ships with the look its author designed.
            .onChange(of: style) { _, newStyle in
                applyDefaults(newStyle)
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

    /// Integer-stepped sliders render as whole numbers; sub-thousandth
    /// steps render with four decimals; everything else gets two.
    private var formattedValue: String {
        if step >= 1 {
            return "\(Int(value.rounded()))"
        } else if step < 0.001 {
            return String(format: "%.4f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Preview

#Preview {
    // ToolbarItem requires an enclosing NavigationStack to render.
    NavigationStack {
        SWAnimatedLoop(showsControls: true)
    }
}
