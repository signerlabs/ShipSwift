//
//  SWPlasma.swift
//  ShipSwift
//
//  Family of full-color plasma backgrounds rendered via SwiftUI Metal
//  stitchable shaders. Five hand-tuned styles share the same parameter
//  surface (5-stop palette + scale / intensity / distortion); switching
//  style swaps both the shader and the palette so the call site sees the
//  intended look in one line.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  All five shader entry points live in `SWPlasma.metal` and share the
//  same hash / value-noise / FBM / palette helpers — `SWDots` keeps each
//  style in its own file because its shader bodies diverge significantly,
//  but the plasma family is essentially "same skeleton, different mixing
//  step," so a single TU is cleaner.
//
//  Usage:
//    // Default — solar warm-orange plasma
//    ZStack {
//        SWPlasma()
//            .ignoresSafeArea()
//    }
//
//    // Pick a style — palette auto-defaults to the style's hand-tuned set
//    SWPlasma(style: .prism)
//    SWPlasma(style: .ember, intensity: 1.4)
//
//    // Override individual palette stops (others fall back to the style default)
//    SWPlasma(style: .lilac, c5: .white)
//
//    // As a section background
//    myContent
//        .background { SWPlasma(style: .spectrum) }
//
//    // Demo / debug — adds a gear button in the navigation bar that
//    // opens a sheet to tweak every parameter live. Disabled by default.
//    SWPlasma(showsControls: true)
//
//  Parameters:
//    - style: Which plasma style to render (default `.solar`).
//             Solar / Prism / Spectrum / Ember / Lilac
//    - c1…c5: Five-stop palette mixed by the shader's intensity field.
//             Default to the style's hand-tuned palette (see
//             `SWPlasmaStyle.defaultPalette`); pass nil to keep the default
//    - scale: Spatial scale multiplier (default `1.0`)
//    - intensity: Multiplier on the field value before palette mapping
//                 (default `1.0`)
//    - distortion: Strength of the noise distortion added to the sin field
//                  (default `1.0`)
//    - showsControls: When `true`, adds a gear `ToolbarItem` to the
//                     enclosing `NavigationStack` that opens a
//                     live-tuning sheet. Default `false`.
//
//  Notes:
//    - Cost is per-pixel and varies by style — Solar / Ember / Lilac each
//      run a single FBM3 (3 noise samples); Prism runs three FBM2s
//      (6 noise samples); Spectrum runs three FBM3s (9 noise samples).
//      Spectrum is the heaviest; keep to one instance.
//    - When `showsControls` is `true`, the sheet's Style picker resets
//      the five palette stops to the new style's defaults — already-tuned
//      colors will be lost on style change. This is intentional so the
//      caller can shop styles by name and see the designer's intent.
//    - The gear button is a native `ToolbarItem` — the call site must be
//      inside a `NavigationStack`.
//
//  Created by Wei Zhong on 5/20/26.
//

import SwiftUI

// MARK: - Style

enum SWPlasmaStyle: String, CaseIterable, Identifiable {
    case solar
    case prism
    case spectrum
    case ember
    case lilac

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .solar:    "Solar"
        case .prism:    "Prism"
        case .spectrum: "Spectrum"
        case .ember:    "Ember"
        case .lilac:    "Lilac"
        }
    }

    /// Metal `stitchable` function name in the default `ShaderLibrary`.
    var shaderName: String {
        switch self {
        case .solar:    "swPlasmaSolar"
        case .prism:    "swPlasmaPrism"
        case .spectrum: "swPlasmaSpectrum"
        case .ember:    "swPlasmaEmber"
        case .lilac:    "swPlasmaLilac"
        }
    }

    /// Five-stop palette hand-tuned for this style.
    var defaultPalette: [Color] {
        switch self {
        case .solar:
            return [
                Color(red: 0.102, green: 0.020, blue: 0.0),     // #1A0500
                Color(red: 0.353, green: 0.071, blue: 0.031),   // #5A1208
                Color(red: 0.769, green: 0.290, blue: 0.125),   // #C44A20
                Color(red: 0.941, green: 0.541, blue: 0.227),   // #F08A3A
                Color(red: 1.0,   green: 0.773, blue: 0.478),   // #FFC57A
            ]
        case .prism:
            return [
                Color(red: 0.102, green: 0.0,   blue: 0.2),     // #1A0033
                Color(red: 0.478, green: 0.122, blue: 0.722),   // #7A1FB8
                Color(red: 1.0,   green: 0.078, blue: 0.576),   // #FF1493
                Color(red: 1.0,   green: 0.839, blue: 0.0),     // #FFD600
                Color(red: 0.0,   green: 0.898, blue: 1.0),     // #00E5FF
            ]
        case .spectrum:
            return [
                Color(red: 0.0,   green: 0.102, blue: 0.4),     // #001A66
                Color(red: 0.231, green: 0.0,   blue: 0.510),   // #3B0082
                Color(red: 0.416, green: 0.051, blue: 0.678),   // #6A0DAD
                Color(red: 0.780, green: 0.082, blue: 0.522),   // #C71585
                Color(red: 1.0,   green: 0.549, blue: 0.180),   // #FF8C2E
            ]
        case .ember:
            return [
                Color(red: 0.020, green: 0.0,   blue: 0.0),     // #050000
                Color(red: 0.290, green: 0.055, blue: 0.0),     // #4A0E00
                Color(red: 0.769, green: 0.290, blue: 0.039),   // #C44A0A
                Color(red: 1.0,   green: 0.659, blue: 0.180),   // #FFA82E
                Color(red: 1.0,   green: 0.878, blue: 0.541),   // #FFE08A
            ]
        case .lilac:
            return [
                Color(red: 0.165, green: 0.039, blue: 0.290),   // #2A0A4A
                Color(red: 0.420, green: 0.310, blue: 0.627),   // #6B4FA0
                Color(red: 0.769, green: 0.600, blue: 0.851),   // #C499D9
                Color(red: 0.961, green: 0.776, blue: 0.878),   // #F5C6E0
                Color(red: 1.0,   green: 0.933, blue: 0.933),   // #FFEEEE
            ]
        }
    }
}

// MARK: - Main View

struct SWPlasma: View {
    var style: SWPlasmaStyle
    var c1: Color
    var c2: Color
    var c3: Color
    var c4: Color
    var c5: Color
    var scale: Float
    var intensity: Float
    var distortion: Float
    var showsControls: Bool

    /// Designated initializer. Any nil palette stop falls back to the
    /// `style`'s `defaultPalette`, so `SWPlasma(style: .prism)` renders
    /// the intended Prism look without the caller spelling out colors.
    init(
        style: SWPlasmaStyle = .solar,
        c1: Color? = nil,
        c2: Color? = nil,
        c3: Color? = nil,
        c4: Color? = nil,
        c5: Color? = nil,
        scale: Float = 1.0,
        intensity: Float = 1.0,
        distortion: Float = 1.0,
        showsControls: Bool = false
    ) {
        self.style = style
        let palette = style.defaultPalette
        self.c1 = c1 ?? palette[0]
        self.c2 = c2 ?? palette[1]
        self.c3 = c3 ?? palette[2]
        self.c4 = c4 ?? palette[3]
        self.c5 = c5 ?? palette[4]
        self.scale = scale
        self.intensity = intensity
        self.distortion = distortion
        self.showsControls = showsControls
    }

    var body: some View {
        if showsControls {
            SWPlasmaControlled(initial: self)
        } else {
            SWPlasmaRenderer(
                style: style,
                c1: c1, c2: c2, c3: c3, c4: c4, c5: c5,
                scale: scale,
                intensity: intensity,
                distortion: distortion
            )
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWPlasmaRenderer: View {
    let style: SWPlasmaStyle
    let c1: Color
    let c2: Color
    let c3: Color
    let c4: Color
    let c5: Color
    let scale: Float
    let intensity: Float
    let distortion: Float

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            // First-frame base color before the shader runs — c3 is the
            // mid-tone of every style's palette, gives a sensible look.
            c3
                .colorEffect(
                    Shader(
                        function: ShaderFunction(library: .default, name: style.shaderName),
                        arguments: [
                            .boundingRect,
                            .float(elapsed),
                            .color(c1),
                            .color(c2),
                            .color(c3),
                            .color(c4),
                            .color(c5),
                            .float(scale),
                            .float(intensity),
                            .float(distortion)
                        ]
                    )
                )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWPlasmaControlled: View {
    @State private var style: SWPlasmaStyle
    @State private var c1: Color
    @State private var c2: Color
    @State private var c3: Color
    @State private var c4: Color
    @State private var c5: Color
    @State private var scale: Float
    @State private var intensity: Float
    @State private var distortion: Float

    @State private var showSheet = false

    init(initial: SWPlasma) {
        _style      = State(initialValue: initial.style)
        _c1         = State(initialValue: initial.c1)
        _c2         = State(initialValue: initial.c2)
        _c3         = State(initialValue: initial.c3)
        _c4         = State(initialValue: initial.c4)
        _c5         = State(initialValue: initial.c5)
        _scale      = State(initialValue: initial.scale)
        _intensity  = State(initialValue: initial.intensity)
        _distortion = State(initialValue: initial.distortion)
    }

    /// Builder that produces a fresh `SWPlasma` view with the currently
    /// tweaked parameters — used by both the full-screen background and
    /// the button-ring demo so all three plasma instances animate in sync.
    private func makePlasma() -> SWPlasma {
        SWPlasma(
            style: style,
            c1: c1, c2: c2, c3: c3, c4: c4, c5: c5,
            scale: scale,
            intensity: intensity,
            distortion: distortion
        )
    }

    var body: some View {
        ZStack {
            // Full-screen plasma — shows the "use as background" case.
            SWPlasmaRenderer(
                style: style,
                c1: c1, c2: c2, c3: c3, c4: c4, c5: c5,
                scale: scale,
                intensity: intensity,
                distortion: distortion
            )
            .ignoresSafeArea()

            // Button-ring demo — shows the "use as ring border" case
            // documented in the original plasma sources. Wrapped in a
            // dark card so the rings read against the plasma background.
            VStack {
                Spacer()
                VStack(spacing: 14) {
                    Text("Plasma as button border")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                    HStack(spacing: 22) {
                        PlasmaRingCircleButton(icon: "arrow.up") { makePlasma() }
                        PlasmaRingPillButton(title: "Upgrade to Pro") { makePlasma() }
                    }
                }
                .padding(.vertical, 22)
                .padding(.horizontal, 28)
                .background(Color.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.bottom, 60)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Plasma Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWPlasmaControlsSheet(
                style: $style,
                c1: $c1, c2: $c2, c3: $c3, c4: $c4, c5: $c5,
                scale: $scale,
                intensity: $intensity,
                distortion: $distortion
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWPlasmaControlsSheet: View {
    @Binding var style: SWPlasmaStyle
    @Binding var c1: Color
    @Binding var c2: Color
    @Binding var c3: Color
    @Binding var c4: Color
    @Binding var c5: Color
    @Binding var scale: Float
    @Binding var intensity: Float
    @Binding var distortion: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Style") {
                    Picker("Style", selection: $style) {
                        ForEach(SWPlasmaStyle.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                }

                Section("Palette") {
                    ColorPicker("Color 1", selection: $c1, supportsOpacity: false)
                    ColorPicker("Color 2", selection: $c2, supportsOpacity: false)
                    ColorPicker("Color 3", selection: $c3, supportsOpacity: false)
                    ColorPicker("Color 4", selection: $c4, supportsOpacity: false)
                    ColorPicker("Color 5", selection: $c5, supportsOpacity: false)
                }

                Section("Field") {
                    SliderRow(label: "Scale",      value: $scale,      range: 0.2...3, step: 0.05)
                    SliderRow(label: "Intensity",  value: $intensity,  range: 0...2.5, step: 0.05)
                    SliderRow(label: "Distortion", value: $distortion, range: 0...3,   step: 0.05)
                }
            }
            .navigationTitle("Plasma")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            // When the style changes, reset the palette to the new style's
            // hand-tuned defaults so the caller sees the designer's intent.
            // Any previously customized colors are overwritten — intentional.
            .onChange(of: style) { _, newStyle in
                let palette = newStyle.defaultPalette
                c1 = palette[0]
                c2 = palette[1]
                c3 = palette[2]
                c4 = palette[3]
                c5 = palette[4]
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

// MARK: - Button-Ring Demo Helpers

/// Inset colors / sizes for the button-ring demo.
private let plasmaButtonInk  = Color(red: 0.07, green: 0.07, blue: 0.08)
private let plasmaRingWidth: CGFloat = 2.5

private struct PlasmaRingCircleButton<Plasma: View>: View {
    let icon: String
    @ViewBuilder let plasma: () -> Plasma

    var body: some View {
        ZStack {
            plasma()
                .clipShape(Circle())
            Circle()
                .fill(plasmaButtonInk)
                .padding(plasmaRingWidth)
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 64, height: 64)
    }
}

private struct PlasmaRingPillButton<Plasma: View>: View {
    let title: String
    @ViewBuilder let plasma: () -> Plasma

    var body: some View {
        ZStack {
            plasma()
                .clipShape(Capsule())
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 28)
        }
        .frame(height: 56)
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Preview

#Preview {
    // ToolbarItem requires an enclosing NavigationStack to render.
    NavigationStack {
        SWPlasma(showsControls: true)
    }
}
