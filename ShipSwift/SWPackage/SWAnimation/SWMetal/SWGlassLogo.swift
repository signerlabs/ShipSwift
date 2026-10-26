//
//  SWGlassLogo.swift
//  ShipSwift
//
//  A multi-layer composited "frosted glass logo": an SF Symbol (default
//  `apple.logo`) rendered as a sheet of frosted, refractive glass that glows on
//  a near-black canvas with flowing colored light trapped inside it.
//
//  The look is built by stacking four passes in a `ZStack`, each a cheap
//  SwiftUI primitive rather than one monolithic shader:
//
//    1. Canvas      — a near-black background (#0a0a0a).
//    2. Flowing light — a slowly rotating tri-color `MeshGradient` (cool-blue /
//                       orange / blue) with a few faint diagonal stripes drifting
//                       across it. This is the light the glass will refract.
//    3. Glass logo  — pass 2, masked to the silhouette of the SF Symbol, then
//                     run through the `swGlassLogo` Metal `layerEffect`: an
//                     alpha-gradient surface normal drives a subtle refraction +
//                     frosted blur + a cool Fresnel rim, all clipped to the
//                     symbol shape (transparent outside).
//    4. Bloom       — two stacked `.shadow` halos (one wide soft, one tight)
//                     that breathe slowly, giving the logo an outer cool glow.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary` / `Shader` /
//  `layerEffect`, Metal `stitchable`, `MeshGradient`, `TimelineView`).
//
//  Usage:
//    // Default — frosted-glass Apple logo on black
//    SWGlassLogo()
//
//    // A different symbol, larger
//    SWGlassLogo(symbolName: "swift", symbolSize: 360)
//
//    // Demo / debug — gear button opens a live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWGlassLogo(showsControls: true)
//
//  This is a first-pass approximation: it leans on frost + a cool rim + a soft
//  bloom over flowing color, and intentionally leaves thin-film iridescence,
//  twirl distortion and exact SDF shaping for later refinement.
//
//  Created by Wei Zhong on 6/2/26.
//

import SwiftUI

// MARK: - Main View

struct SWGlassLogo: View {
    /// SF Symbol name used as the glass silhouette.
    var symbolName: String = "apple.logo"

    /// Point size of the rendered symbol.
    var symbolSize: CGFloat = 300

    /// Master strength of the refractive bend at the glass edge (0...1).
    var refraction: Float = 0.35

    /// Frosted-blur disk radius in pixels-ish (0 = sharp).
    var frost: Float = 9

    /// Apparent glass thickness; widens the hard-bending edge band (0...2).
    var thickness: Float = 0.6

    /// Width of the soft alpha-contour band the rim rides on (0.2...1.5).
    var edgeSoftness: Float = 0.6

    /// Strength of the cool Fresnel rim hugging the contour (0...1).
    var fresnel: Float = 0.08

    /// How far in from the contour the rim reaches (0.1...1).
    var fresnelSoftness: Float = 0.57

    /// Base animation speed of the flowing light + bloom breath.
    var flowSpeed: Double = 0.18

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWGlassLogoControlled(initial: self)
        } else {
            SWGlassLogoRenderer(initial: self)
        }
    }
}

// MARK: - Palette & Tuning
// Every magic color / number for the four passes lives here in one place so the
// look can be re-tuned without hunting through the view body.
private enum SWGlassLogoStyle {
    // --- Flowing-light palette (the color trapped inside the glass) ----------
    /// Cool blue highlight (#b3bcff).
    static let coolBlue = Color(red: 0.702, green: 0.737, blue: 1.0)
    /// Warm orange (#fc8323).
    static let orange   = Color(red: 0.988, green: 0.514, blue: 0.137)
    /// Deep blue (#0856ff).
    static let deepBlue = Color(red: 0.031, green: 0.337, blue: 1.0)
    /// Faint diagonal stripe color (#def1ff), kept low-opacity.
    static let stripe   = Color(red: 0.871, green: 0.945, blue: 1.0)

    // --- Glass tint + rim ----------------------------------------------------
    /// What the glass nudges the refracted light toward (a cool blue).
    static let tint: (r: Float, g: Float, b: Float) = (0.55, 0.70, 1.0)
    static let tintIntensity: Float = 0.18
    /// Cool Fresnel rim color (#b3e5ff).
    static let fresnelColor: (r: Float, g: Float, b: Float) = (0.702, 0.898, 1.0)

    // --- Canvas --------------------------------------------------------------
    /// Near-black background (#0a0a0a).
    static let canvas = Color(red: 0.04, green: 0.04, blue: 0.04)

    // --- Diagonal stripes ----------------------------------------------------
    /// Stripe sweep angle (degrees) — the brief's ~-139°.
    static let stripeAngle: Double = -139
    /// Number of stripes drawn across the flowing-light layer.
    static let stripeCount: Int = 3

    // --- Bloom (outer glow) --------------------------------------------------
    /// Cool-white bloom tint.
    static let bloom = Color(red: 0.80, green: 0.90, blue: 1.0)
    static let bloomInnerRadius: CGFloat = 14
    static let bloomOuterRadiusBase: CGFloat = 46
    static let bloomOuterRadiusRange: CGFloat = 16
    static let bloomInnerOpacityBase: Double = 0.45
    static let bloomInnerOpacityRange: Double = 0.18
    static let bloomOuterOpacityBase: Double = 0.22
    static let bloomOuterOpacityRange: Double = 0.14
}

// MARK: - Flowing Light Layer
// A slowly rotating tri-color MeshGradient with a few drifting diagonal
// stripes. This is the cool/warm clash of light the glass refracts.
private struct SWGlassLogoFlow: View {
    let phase: Double

    var body: some View {
        ZStack {
            meshGradient
            stripes
        }
    }

    // Tri-color mesh whose interior control points orbit slowly, so the
    // cool-blue / orange / deep-blue zones swirl into one another over time.
    private var meshGradient: some View {
        // Orbit the four interior points on slow circles of different phase so
        // the color field never reads as a static gradient.
        let a = phase
        func orbit(_ base: SIMD2<Float>, _ off: Double, _ amp: Float) -> SIMD2<Float> {
            SIMD2<Float>(
                base.x + amp * Float(cos(a + off)),
                base.y + amp * Float(sin(a * 0.8 + off))
            )
        }

        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                .init(0, 0),                                  .init(0.5, 0),                                .init(1, 0),
                orbit(.init(0, 0.5), 0.0, 0.10), orbit(.init(0.5, 0.5), 2.1, 0.16), orbit(.init(1, 0.5), 4.2, 0.10),
                .init(0, 1),                                  .init(0.5, 1),                                .init(1, 1)
            ],
            colors: [
                SWGlassLogoStyle.deepBlue, SWGlassLogoStyle.coolBlue, SWGlassLogoStyle.deepBlue,
                SWGlassLogoStyle.coolBlue, SWGlassLogoStyle.orange,   SWGlassLogoStyle.coolBlue,
                SWGlassLogoStyle.deepBlue, SWGlassLogoStyle.coolBlue, SWGlassLogoStyle.deepBlue
            ]
        )
    }

    // A handful of faint, wide diagonal stripes drifting along the sweep angle.
    private var stripes: some View {
        GeometryReader { geo in
            let diag = hypot(geo.size.width, geo.size.height)
            let spacing = diag / CGFloat(SWGlassLogoStyle.stripeCount + 1)
            // Drift offset moves the stripes slowly along their own direction.
            let drift = CGFloat(phase.truncatingRemainder(dividingBy: .pi * 2)) / (.pi * 2) * spacing

            ZStack {
                ForEach(0..<SWGlassLogoStyle.stripeCount, id: \.self) { i in
                    let y = spacing * CGFloat(i) - diag / 2 + drift
                    Rectangle()
                        .fill(SWGlassLogoStyle.stripe.opacity(0.10))
                        .frame(width: diag * 1.6, height: spacing * 0.42)
                        .blur(radius: 12)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2 + y)
                }
            }
            .rotationEffect(.degrees(SWGlassLogoStyle.stripeAngle))
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Renderer (the four-pass composite)

private struct SWGlassLogoRenderer: View {
    let initial: SWGlassLogo

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = ctx.date.timeIntervalSince(start)
            let phase = elapsed * initial.flowSpeed

            // Bloom breathes slowly (out of phase with nothing in particular —
            // just a gentle pulse so the halo is never a dead static ring).
            let breath = (sin(phase * 1.3) * 0.5 + 0.5) // 0...1
            let innerOpacity = SWGlassLogoStyle.bloomInnerOpacityBase
                + SWGlassLogoStyle.bloomInnerOpacityRange * breath
            let outerOpacity = SWGlassLogoStyle.bloomOuterOpacityBase
                + SWGlassLogoStyle.bloomOuterOpacityRange * breath
            let outerRadius = SWGlassLogoStyle.bloomOuterRadiusBase
                + SWGlassLogoStyle.bloomOuterRadiusRange * CGFloat(breath)

            ZStack {
                // Pass 1 — near-black canvas.
                SWGlassLogoStyle.canvas.ignoresSafeArea()

                // Passes 2+3 — the flowing light, masked to the logo silhouette,
                // then run through the glass shader. Masking BEFORE the shader is
                // what gives the layer its alpha-contour silhouette, which the
                // shader reads back as the surface normal. Pass 4 (bloom) is the
                // outer .shadow stack on the same glass node.
                glassLogo(phase: phase)
                    .shadow(color: SWGlassLogoStyle.bloom.opacity(innerOpacity),
                            radius: SWGlassLogoStyle.bloomInnerRadius)
                    .shadow(color: SWGlassLogoStyle.bloom.opacity(outerOpacity),
                            radius: outerRadius)
            }
        }
    }

    // Pass 2 (flow) masked to the symbol, then Pass 3 (glass shader).
    private func glassLogo(phase: Double) -> some View {
        SWGlassLogoFlow(phase: phase)
            // Clip the flowing light to the symbol silhouette: the layer the
            // shader samples now carries the logo's exact alpha contour.
            .mask {
                Image(systemName: initial.symbolName)
                    .font(.system(size: initial.symbolSize))
            }
            // Constrain the layer to the symbol's footprint so refraction /
            // frost taps stay near the shape, not the whole screen.
            .frame(width: initial.symbolSize * 1.2, height: initial.symbolSize * 1.2)
            .layerEffect(
                ShaderLibrary.swGlassLogo(
                    .boundingRect,
                    .float(initial.refraction),
                    .float(initial.frost),
                    .float(initial.thickness),
                    .float(initial.edgeSoftness),
                    .float(initial.fresnel),
                    .float(initial.fresnelSoftness),
                    .float3(SWGlassLogoStyle.fresnelColor.r,
                            SWGlassLogoStyle.fresnelColor.g,
                            SWGlassLogoStyle.fresnelColor.b),
                    .float3(SWGlassLogoStyle.tint.r,
                            SWGlassLogoStyle.tint.g,
                            SWGlassLogoStyle.tint.b),
                    .float(SWGlassLogoStyle.tintIntensity)
                ),
                // Frost + refraction sample a small neighbourhood; budget a
                // generous offset so taps near the edge are not clamped.
                maxSampleOffset: CGSize(width: 40, height: 40)
            )
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWGlassLogoControlled: View {
    @State private var refraction: Float
    @State private var frost: Float
    @State private var thickness: Float
    @State private var edgeSoftness: Float
    @State private var fresnel: Float
    @State private var fresnelSoftness: Float
    @State private var flowSpeed: Double

    @State private var showSheet = false

    private let symbolName: String
    private let symbolSize: CGFloat

    init(initial: SWGlassLogo) {
        _refraction      = State(initialValue: initial.refraction)
        _frost           = State(initialValue: initial.frost)
        _thickness       = State(initialValue: initial.thickness)
        _edgeSoftness    = State(initialValue: initial.edgeSoftness)
        _fresnel         = State(initialValue: initial.fresnel)
        _fresnelSoftness = State(initialValue: initial.fresnelSoftness)
        _flowSpeed       = State(initialValue: initial.flowSpeed)
        self.symbolName  = initial.symbolName
        self.symbolSize  = initial.symbolSize
    }

    var body: some View {
        // The glass sheen, the cool rim and especially the bloom only read
        // against black, so the demo mode pins a full-bleed dark canvas.
        ZStack {
            SWGlassLogoStyle.canvas.ignoresSafeArea()

            SWGlassLogoRenderer(
                initial: SWGlassLogo(
                    symbolName: symbolName,
                    symbolSize: symbolSize,
                    refraction: refraction,
                    frost: frost,
                    thickness: thickness,
                    edgeSoftness: edgeSoftness,
                    fresnel: fresnel,
                    fresnelSoftness: fresnelSoftness,
                    flowSpeed: flowSpeed
                )
            )
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Glass Logo Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWGlassLogoControlsSheet(
                refraction: $refraction,
                frost: $frost,
                thickness: $thickness,
                edgeSoftness: $edgeSoftness,
                fresnel: $fresnel,
                fresnelSoftness: $fresnelSoftness,
                flowSpeed: $flowSpeed
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWGlassLogoControlsSheet: View {
    @Binding var refraction: Float
    @Binding var frost: Float
    @Binding var thickness: Float
    @Binding var edgeSoftness: Float
    @Binding var fresnel: Float
    @Binding var fresnelSoftness: Float
    @Binding var flowSpeed: Double

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Glass") {
                    SWGlassLogoSliderRow(label: "Refraction",      value: $refraction,      range: 0...1,    step: 0.01)
                    SWGlassLogoSliderRow(label: "Frost",           value: $frost,           range: 0...24,   step: 0.5)
                    SWGlassLogoSliderRow(label: "Thickness",       value: $thickness,       range: 0...2,    step: 0.05)
                    SWGlassLogoSliderRow(label: "Edge Softness",   value: $edgeSoftness,    range: 0.2...1.5, step: 0.01)
                }

                Section("Fresnel Rim") {
                    SWGlassLogoSliderRow(label: "Fresnel",         value: $fresnel,         range: 0...1,    step: 0.01)
                    SWGlassLogoSliderRow(label: "Rim Softness",    value: $fresnelSoftness, range: 0.1...1,  step: 0.01)
                }

                Section("Motion") {
                    SWGlassLogoSliderRowD(label: "Flow Speed",     value: $flowSpeed,       range: 0...0.6,  step: 0.01)
                }
            }
            .navigationTitle("Glass Logo")
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

// Float slider row.
private struct SWGlassLogoSliderRow: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: step < 0.1 ? "%.2f" : "%.1f", value))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

// Double slider row (for flow speed).
private struct SWGlassLogoSliderRowD: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

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

#Preview("Glass Apple logo") {
    NavigationStack {
        SWGlassLogo(showsControls: true)
    }
}

#Preview("Glass Swift logo") {
    SWGlassLogo(symbolName: "swift", symbolSize: 320)
}
