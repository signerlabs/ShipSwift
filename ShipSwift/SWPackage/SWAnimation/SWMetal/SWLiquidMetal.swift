//
//  SWLiquidMetal.swift
//  ShipSwift
//
//  Wraps any view in a flowing chromatic liquid-metal effect via a SwiftUI
//  Metal `layerEffect`: simplex noise drives a stripe-pattern color split
//  with refraction, edge-aware bulge, and per-channel chromatic shift.
//
//  Best paired with a bold, opaque silhouette (SF Symbol, logo) — the
//  effect uses the source's red channel as its edge mask, so vector
//  shapes against transparent background work cleanest.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — flowing chrome over the Apple logo
//    SWLiquidMetal {
//        Image(systemName: "apple.logo")
//            .font(.system(size: 300))
//    }
//
//    // Subtler refraction, slower
//    SWLiquidMetal(
//        refraction: 0.003,
//        timeScale: 0.1
//    ) {
//        Image(systemName: "swift")
//            .font(.system(size: 300))
//    }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWLiquidMetal(showsControls: true) {
//        Image(systemName: "apple.logo")
//            .font(.system(size: 300))
//    }
//
//  The defaults are tuned to land close to the WWDC-style "liquid metal Apple
//  logo": a high-contrast cool-white-to-near-black polished-metal silhouette
//  with broad curved reflection bands, a cool ambient bounce in the mid-tones,
//  a bright fresnel rim along the contour, and slow liquid creep. Every value
//  is still adjustable, and `showsControls: true` exposes them in a live sheet.
//
//  Parameters:
//    - speed: Multiplier on the internal animation time (default `1.0`).
//    - refraction: Strength of the per-channel chromatic split in
//                  `0...0.06`. Keep near zero for a neutral cool silver with
//                  no rainbow fringing (default `0.001`).
//    - edge: Edge mask sharpness in `0...1` — higher = tighter edge
//            opacity falloff (default `0.8`).
//    - liquid: Noise distortion strength in `0...1` (default `0.45`).
//    - patternBlur: Stripe band softness in `0...0.05` (default `0.012`).
//    - patternScale: Reflection-band density in `0.3...10` — sub-1.0 makes the
//                    look governed by large NON-periodic reflection blocks
//                    (2-3 big smooth zones, no repeating stripes); higher
//                    values bring back denser periodic bands (default `0.5`).
//    - timeScale: Base animation speed multiplier in `0...2` — slow liquid
//                 creep (default `0.08`).
//    - coolTint: Cool blue/cyan ambient bounce strength in `0...1`, injected
//                into the highlight→shadow transition (default `0.5`).
//    - fresnel: Cool-white rim-highlight strength along the silhouette
//               contour in `0...1` (default `0.6`).
//    - bandSoftness: Broad-band reflection blur multiplier in `1...8` —
//                    higher melts adjacent bands into large smooth polished-
//                    mercury blobs instead of thin lines (default `7.0`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a
//                     live-tuning sheet (default `false`).
//
//  Created by Wei Zhong on 5/25/26.
//

import SwiftUI

// MARK: - Main View

struct SWLiquidMetal<Content: View>: View {
    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// Strength of the per-channel chromatic split (near zero = neutral silver).
    var refraction: Float = 0.001

    /// Edge mask sharpness in 0...1.
    var edge: Float = 0.8

    /// Noise distortion strength in 0...1.
    var liquid: Float = 0.45

    /// Stripe band softness in 0...0.05.
    var patternBlur: Float = 0.012

    /// Reflection-band density in 0.3...10 (sub-1 = mostly non-periodic blocks).
    var patternScale: Float = 0.5

    /// Base animation speed multiplier in 0...2 (slow liquid creep).
    var timeScale: Float = 0.08

    /// Cool blue/cyan ambient bounce strength in 0...1.
    var coolTint: Float = 0.5

    /// Cool-white fresnel rim-highlight strength along the contour in 0...1.
    var fresnel: Float = 0.6

    /// Broad-band reflection blur multiplier in 1...8 (higher = large smooth blobs).
    var bandSoftness: Float = 7.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    private let content: Content

    init(
        speed: Float = 1.0,
        refraction: Float = 0.001,
        edge: Float = 0.8,
        liquid: Float = 0.45,
        patternBlur: Float = 0.012,
        patternScale: Float = 0.5,
        timeScale: Float = 0.08,
        coolTint: Float = 0.5,
        fresnel: Float = 0.6,
        bandSoftness: Float = 7.0,
        showsControls: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.speed = speed
        self.refraction = refraction
        self.edge = edge
        self.liquid = liquid
        self.patternBlur = patternBlur
        self.patternScale = patternScale
        self.timeScale = timeScale
        self.coolTint = coolTint
        self.fresnel = fresnel
        self.bandSoftness = bandSoftness
        self.showsControls = showsControls
        self.content = content()
    }

    var body: some View {
        if showsControls {
            SWLiquidMetalControlled(initial: self, content: content)
        } else {
            SWLiquidMetalRenderer(initial: self, content: content)
        }
    }
}

// MARK: - Glow Tuning
// All dynamic-bloom magic numbers in one place — edit, recompile, observe.
// The halo breathes and shifts color on the metal's own slow clock; each value
// notes which way to nudge it.
private enum SWLMGlow {
    // The glow is built from BLURRED COPIES OF THE METAL ITSELF, layered under
    // the crisp logo with an additive blend. Because each copy is the SAME
    // shader output (just blurred), the halo's color, direction and motion
    // follow the bright regions inside the metal automatically — when an
    // internal reflection flows to one side, the outer glow flows with it; when
    // the body breathes dark/bright the glow breathes too. No separate halo
    // clock — it is literally the metal's own light spilling outward. Two
    // layers: a tight near bloom + a wide soft outer halo.
    static let nearRadius:  CGFloat = 26   // tight bloom blur radius (pt) — bigger = softer/wider near glow
    static let nearOpacity: Double  = 1.0  // tight bloom strength
    static let wideRadius:  CGFloat = 82   // wide halo blur radius (pt) — the far outer spill
    static let wideOpacity: Double  = 0.9  // wide halo strength
}

// MARK: - Renderer

private struct SWLiquidMetalRenderer<Content: View>: View {
    let initial: SWLiquidMetal<Content>
    let content: Content

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))

            // The metal logo itself — one shader pass. The shader only samples
            // the layer at the current pixel (and reads layer.r for the edge
            // mask), so no sample-offset budget is needed.
            let metal = content.layerEffect(
                ShaderLibrary.swLiquidMetal(
                    .boundingRect,
                    .float(elapsed),
                    .float(initial.speed),
                    .float(initial.refraction),
                    .float(initial.edge),
                    .float(initial.liquid),
                    .float(initial.patternBlur),
                    .float(initial.patternScale),
                    .float(initial.timeScale),
                    .float(initial.coolTint),
                    .float(initial.fresnel),
                    .float(initial.bandSoftness)
                ),
                maxSampleOffset: .zero
            )

            // Glow = blurred copies of the metal underneath, additively (screen)
            // blended. They are the SAME shader output, just blurred, so the
            // halo's color / direction / motion follow the bright regions inside
            // the metal — when an internal reflection flows to one side the
            // outer glow flows with it, and when the body breathes dark/bright
            // the glow breathes too. A wide soft outer halo + a tight near bloom
            // under the crisp logo.
            ZStack {
                metal
                    .blur(radius: SWLMGlow.wideRadius)
                    .blendMode(.screen)
                    .opacity(SWLMGlow.wideOpacity)
                metal
                    .blur(radius: SWLMGlow.nearRadius)
                    .blendMode(.screen)
                    .opacity(SWLMGlow.nearOpacity)
                metal
            }
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWLiquidMetalControlled<Content: View>: View {
    @State private var speed: Float
    @State private var refraction: Float
    @State private var edge: Float
    @State private var liquid: Float
    @State private var patternBlur: Float
    @State private var patternScale: Float
    @State private var timeScale: Float
    @State private var coolTint: Float
    @State private var fresnel: Float
    @State private var bandSoftness: Float

    @State private var showSheet = false

    private let content: Content

    init(initial: SWLiquidMetal<Content>, content: Content) {
        _speed        = State(initialValue: initial.speed)
        _refraction   = State(initialValue: initial.refraction)
        _edge         = State(initialValue: initial.edge)
        _liquid       = State(initialValue: initial.liquid)
        _patternBlur  = State(initialValue: initial.patternBlur)
        _patternScale = State(initialValue: initial.patternScale)
        _timeScale    = State(initialValue: initial.timeScale)
        _coolTint     = State(initialValue: initial.coolTint)
        _fresnel      = State(initialValue: initial.fresnel)
        _bandSoftness = State(initialValue: initial.bandSoftness)
        self.content = content
    }

    var body: some View {
        // Fixed dark demo canvas: the metal sheen, the cool tint and especially
        // the white bloom only read against black, so the controlled/demo mode
        // pins a full-bleed black background behind the rendered logo.
        ZStack {
            Color.black.ignoresSafeArea()

            SWLiquidMetalRenderer(
                initial: SWLiquidMetal(
                    speed: speed,
                    refraction: refraction,
                    edge: edge,
                    liquid: liquid,
                    patternBlur: patternBlur,
                    patternScale: patternScale,
                    timeScale: timeScale,
                    coolTint: coolTint,
                    fresnel: fresnel,
                    bandSoftness: bandSoftness
                ) { content },
                content: content
            )
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Liquid Metal Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWLiquidMetalControlsSheet(
                speed: $speed,
                refraction: $refraction,
                edge: $edge,
                liquid: $liquid,
                patternBlur: $patternBlur,
                patternScale: $patternScale,
                timeScale: $timeScale,
                coolTint: $coolTint,
                fresnel: $fresnel,
                bandSoftness: $bandSoftness
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWLiquidMetalControlsSheet: View {
    @Binding var speed: Float
    @Binding var refraction: Float
    @Binding var edge: Float
    @Binding var liquid: Float
    @Binding var patternBlur: Float
    @Binding var patternScale: Float
    @Binding var timeScale: Float
    @Binding var coolTint: Float
    @Binding var fresnel: Float
    @Binding var bandSoftness: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Pattern") {
                    SliderRow(label: "Refraction",    value: $refraction,   range: 0...0.06,   step: 0.001)
                    SliderRow(label: "Edge",          value: $edge,         range: 0...1,      step: 0.01)
                    SliderRow(label: "Liquid",        value: $liquid,       range: 0...1,      step: 0.01)
                    SliderRow(label: "Pattern Blur",  value: $patternBlur,  range: 0...0.05,   step: 0.001)
                    SliderRow(label: "Pattern Scale", value: $patternScale, range: 0.3...10,   step: 0.05)
                }

                Section("Metal") {
                    SliderRow(label: "Cool Tint",     value: $coolTint,     range: 0...1,      step: 0.01)
                    SliderRow(label: "Fresnel Rim",   value: $fresnel,      range: 0...1,      step: 0.01)
                    SliderRow(label: "Band Softness", value: $bandSoftness, range: 1...8,      step: 0.1)
                }

                Section("Motion") {
                    SliderRow(label: "Time Scale", value: $timeScale, range: 0...2, step: 0.01)
                    SliderRow(label: "Speed",      value: $speed,     range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Liquid Metal")
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
                Text(String(format: step < 0.01 ? "%.3f" : "%.2f", value))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

// MARK: - Preview

#Preview("Apple logo") {
    NavigationStack {
        SWLiquidMetal(showsControls: true) {
            Image(systemName: "apple.logo")
                .font(.system(size: 300))
        }
    }
}

#Preview("Swift logo") {
    SWLiquidMetal {
        Image(systemName: "swift")
            .font(.system(size: 300))
    }
}
