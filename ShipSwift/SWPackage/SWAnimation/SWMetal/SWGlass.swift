//
//  SWGlass.swift
//  ShipSwift
//
//  A refractive glass sheet laid over any content. `SWGlass` wraps a piece of
//  background content and applies a Metal `layerEffect` that bends, frosts,
//  tints and lights that background inside an analytic SDF region (a circle or
//  a rounded rectangle). Outside the shape the background passes through, or is
//  cut away when `cutout` is on.
//
//  The look is driven entirely by the shape's signed-distance field and its
//  gradient: the rim refracts hardest, a golden-angle disk frosts the content,
//  the same taps split chromatically for dispersion, and tint, directional edge
//  light, a specular glint and a Fresnel rim are layered on top. It is a
//  from-scratch Metal recipe.
//
//  This is a sibling of `SWGlassOrb` (which renders a *sphere* with its own
//  gradient fill); `SWGlass` instead glasses over *arbitrary* content with a
//  flat sheet and a far larger control surface.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`, Metal `stitchable`).
//
//  Usage:
//    // Glass a circle over your own content.
//    SWGlass { MyHeroImage() }
//
//    // Rounded-rectangle glass card, isolated on transparency.
//    SWGlass(shape: .roundedRect, cutout: true) { MyHeroImage() }
//
//    // Demo — built-in sample background + gear toolbar item + live-tuning
//    // sheet. Requires an enclosing `NavigationStack`.
//    SWGlass(showsControls: true)
//

import SwiftUI

// MARK: - SWGlassShape

/// The analytic SDF region the glass covers.
enum SWGlassShape: Int, CaseIterable, Identifiable {
    case circle = 0
    case roundedRect = 1

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .circle: return "Circle"
        case .roundedRect: return "Rounded Rect"
        }
    }
}

// MARK: - SWGlass

struct SWGlass<Content: View>: View {
    // --- Shape ---------------------------------------------------------------
    /// The SDF region the glass covers.
    var shape: SWGlassShape = .circle
    /// Shape centre in normalised view space (0...1).
    var center: CGPoint = CGPoint(x: 0.5, y: 0.5)
    /// Shape scale; >1 shrinks the glass, <1 grows it.
    var scale: CGFloat = 1
    /// Corner radius for the rounded-rectangle shape.
    var cornerRadius: CGFloat = 0.12
    /// When `true`, the exterior is transparent and only the glass remains.
    var cutout: Bool = false

    // --- Glass ---------------------------------------------------------------
    /// Master strength of the refractive bend.
    var refraction: CGFloat = 1
    /// Width of the soft edge fill band.
    var edgeSoftness: CGFloat = 0.1
    /// Frosted-glass blur radius (0 = sharp; 0...20).
    var blur: CGFloat = 0
    /// Apparent glass thickness; widens the refractive band.
    var thickness: CGFloat = 0.2
    /// Chromatic split strength along the refraction vector.
    var aberration: CGFloat = 0.5
    /// Magnifies the refracted content (>1 zooms in).
    var innerZoom: CGFloat = 1

    // --- Highlight -----------------------------------------------------------
    /// Light direction in degrees (0 = +x, counter-clockwise).
    var lightAngle: CGFloat = 300
    /// Master strength of edge light + specular glint.
    var highlight: CGFloat = 0.05
    /// Highlight / specular color.
    var highlightColor: Color = .white
    /// Specular tightness (higher = broader glint).
    var highlightSoftness: CGFloat = 0.5

    // --- Fresnel -------------------------------------------------------------
    /// Strength of the Fresnel rim.
    var fresnel: CGFloat = 0.1
    /// Width of the Fresnel rim band.
    var fresnelSoftness: CGFloat = 0.1
    /// Fresnel rim color.
    var fresnelColor: Color = .white

    // --- Tint ----------------------------------------------------------------
    /// The color the glass tints the refracted content toward.
    var tintColor: Color = .white
    /// How strongly the tint is mixed in (0 = none).
    var tintIntensity: CGFloat = 0
    /// When `true`, the tint keeps the original luminance (hue/chroma only).
    var tintPreserveLuminosity: Bool = true

    // --- Demo ----------------------------------------------------------------
    /// Wrap in a dark demo canvas with a gear toolbar item + live-tuning sheet.
    var showsControls: Bool = false

    /// The background content the glass refracts.
    @ViewBuilder var content: () -> Content

    var body: some View {
        if showsControls {
            SWGlassControlled(initial: self, content: content)
        } else {
            SWGlassBody(config: config, content: content)
        }
    }

    /// Snapshot of every tunable parameter, passed down to the body / sheet.
    fileprivate var config: SWGlassConfig {
        SWGlassConfig(
            shape: shape,
            center: center,
            scale: scale,
            cornerRadius: cornerRadius,
            cutout: cutout,
            refraction: refraction,
            edgeSoftness: edgeSoftness,
            blur: blur,
            thickness: thickness,
            aberration: aberration,
            innerZoom: innerZoom,
            lightAngle: lightAngle,
            highlight: highlight,
            highlightColor: highlightColor,
            highlightSoftness: highlightSoftness,
            fresnel: fresnel,
            fresnelSoftness: fresnelSoftness,
            fresnelColor: fresnelColor,
            tintColor: tintColor,
            tintIntensity: tintIntensity,
            tintPreserveLuminosity: tintPreserveLuminosity
        )
    }
}

// MARK: - Convenience init (built-in sample background)

extension SWGlass where Content == SWGlassSampleBackground {
    /// Convenience initialiser that supplies a built-in colorful sample
    /// background, so `SWGlass(showsControls: true)` shows the effect with no
    /// extra wiring.
    init(
        shape: SWGlassShape = .circle,
        center: CGPoint = CGPoint(x: 0.5, y: 0.5),
        scale: CGFloat = 1,
        cornerRadius: CGFloat = 0.12,
        cutout: Bool = false,
        refraction: CGFloat = 1,
        edgeSoftness: CGFloat = 0.1,
        blur: CGFloat = 0,
        thickness: CGFloat = 0.2,
        aberration: CGFloat = 0.5,
        innerZoom: CGFloat = 1,
        lightAngle: CGFloat = 300,
        highlight: CGFloat = 0.05,
        highlightColor: Color = .white,
        highlightSoftness: CGFloat = 0.5,
        fresnel: CGFloat = 0.1,
        fresnelSoftness: CGFloat = 0.1,
        fresnelColor: Color = .white,
        tintColor: Color = .white,
        tintIntensity: CGFloat = 0,
        tintPreserveLuminosity: Bool = true,
        showsControls: Bool = false
    ) {
        self.shape = shape
        self.center = center
        self.scale = scale
        self.cornerRadius = cornerRadius
        self.cutout = cutout
        self.refraction = refraction
        self.edgeSoftness = edgeSoftness
        self.blur = blur
        self.thickness = thickness
        self.aberration = aberration
        self.innerZoom = innerZoom
        self.lightAngle = lightAngle
        self.highlight = highlight
        self.highlightColor = highlightColor
        self.highlightSoftness = highlightSoftness
        self.fresnel = fresnel
        self.fresnelSoftness = fresnelSoftness
        self.fresnelColor = fresnelColor
        self.tintColor = tintColor
        self.tintIntensity = tintIntensity
        self.tintPreserveLuminosity = tintPreserveLuminosity
        self.showsControls = showsControls
        self.content = { SWGlassSampleBackground() }
    }
}

// MARK: - Config snapshot

/// A plain value bag of every tunable parameter. Keeps the body and the live
/// sheet in sync without threading two dozen arguments through each layer.
private struct SWGlassConfig {
    var shape: SWGlassShape
    var center: CGPoint
    var scale: CGFloat
    var cornerRadius: CGFloat
    var cutout: Bool
    var refraction: CGFloat
    var edgeSoftness: CGFloat
    var blur: CGFloat
    var thickness: CGFloat
    var aberration: CGFloat
    var innerZoom: CGFloat
    var lightAngle: CGFloat
    var highlight: CGFloat
    var highlightColor: Color
    var highlightSoftness: CGFloat
    var fresnel: CGFloat
    var fresnelSoftness: CGFloat
    var fresnelColor: Color
    var tintColor: Color
    var tintIntensity: CGFloat
    var tintPreserveLuminosity: Bool
}

// MARK: - Glass Body (content + layerEffect)

/// The glass itself: the supplied background content with the `swGlass`
/// `layerEffect` applied. The light angle is converted to a `(cos, sin)`
/// direction on the CPU so the shader avoids per-pixel trig, and `Color`s are
/// resolved to RGB triples here too.
private struct SWGlassBody<Content: View>: View {
    let config: SWGlassConfig
    @ViewBuilder var content: () -> Content

    var body: some View {
        let lightRad = Float(config.lightAngle) * .pi / 180
        let lightDir = (cos(lightRad), sin(lightRad))
        let hi = config.highlightColor.swGlassRGB
        let fr = config.fresnelColor.swGlassRGB
        let ti = config.tintColor.swGlassRGB

        // Sample budget: frosted disk reach (blur * 2) plus the refractive bend
        // (≈ refraction * 0.15 of the view) and the aberration split, in points.
        // A generous constant cap keeps the tile budget sane on large views.
        let budget = max(config.blur * 2, 1) + config.refraction * 40 + 24

        content()
            .layerEffect(
                ShaderLibrary.swGlass(
                    // `position` and `layer` are auto-injected by SwiftUI; the
                    // first explicit argument is the bounding rect.
                    .boundingRect,
                    // SwiftUI's Shader.Argument has no integer case, so the
                    // shape enum travels as a float and is compared with > 0.5.
                    .float(Float(config.shape.rawValue)),
                    .float2(Float(config.center.x), Float(config.center.y)),
                    .float(Float(config.scale)),
                    .float(Float(config.cornerRadius)),
                    .float(config.cutout ? 1 : 0),
                    .float(Float(config.refraction)),
                    .float(Float(config.edgeSoftness)),
                    .float(Float(config.blur)),
                    .float(Float(config.thickness)),
                    .float(Float(config.aberration)),
                    .float(Float(config.innerZoom)),
                    .float2(lightDir.0, lightDir.1),
                    .float(Float(config.highlight)),
                    .float3(hi.0, hi.1, hi.2),
                    .float(Float(config.highlightSoftness)),
                    .float(Float(config.fresnel)),
                    .float(Float(config.fresnelSoftness)),
                    .float3(fr.0, fr.1, fr.2),
                    .float3(ti.0, ti.1, ti.2),
                    .float(Float(config.tintIntensity)),
                    .float(config.tintPreserveLuminosity ? 1 : 0)
                ),
                maxSampleOffset: CGSize(width: budget, height: budget)
            )
    }
}

// MARK: - Sample Background

/// A colorful built-in background used by the convenience initialiser so the
/// glass effect is visible out of the box. A diagonal multi-stop gradient plus
/// a few soft blobs give the refraction something rich to bend.
struct SWGlassSampleBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.orange, .pink, .purple, .blue, .teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft accent blobs to give the refraction structure to distort.
            Circle()
                .fill(.yellow.opacity(0.9))
                .frame(width: 160)
                .blur(radius: 30)
                .offset(x: -90, y: -160)

            Circle()
                .fill(.cyan.opacity(0.9))
                .frame(width: 200)
                .blur(radius: 40)
                .offset(x: 110, y: 180)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Controlled Wrapper (dark demo canvas + gear toolbar item + live sheet)

private struct SWGlassControlled<Content: View>: View {
    @State private var config: SWGlassConfig
    @State private var showSheet = false
    @ViewBuilder private let content: () -> Content

    init(initial: SWGlass<Content>, @ViewBuilder content: @escaping () -> Content) {
        _config = State(initialValue: initial.config)
        self.content = content
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            SWGlassBody(config: config, content: content)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Glass Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWGlassControlsSheet(config: $config)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet (grouped: Shape / Glass / Highlight / Fresnel / Tint)

private struct SWGlassControlsSheet: View {
    @Binding var config: SWGlassConfig
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Shape") {
                    Picker("Shape", selection: $config.shape) {
                        ForEach(SWGlassShape.allCases) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    SWGlassSliderRow(label: "Scale",         value: $config.scale,        range: 0.5...2,   step: 0.01)
                    SWGlassSliderRow(label: "Corner Radius", value: $config.cornerRadius, range: 0...0.34,  step: 0.005)
                    Toggle("Cutout", isOn: $config.cutout)
                }
                Section("Glass") {
                    SWGlassSliderRow(label: "Refraction",   value: $config.refraction,   range: 0...3,     step: 0.01)
                    SWGlassSliderRow(label: "Edge Softness",value: $config.edgeSoftness, range: 0.01...0.5,step: 0.005)
                    SWGlassSliderRow(label: "Blur",         value: $config.blur,         range: 0...20,    step: 0.1)
                    SWGlassSliderRow(label: "Thickness",    value: $config.thickness,    range: 0.02...1,  step: 0.01)
                    SWGlassSliderRow(label: "Aberration",   value: $config.aberration,   range: 0...2,     step: 0.01)
                    SWGlassSliderRow(label: "Inner Zoom",   value: $config.innerZoom,    range: 0.5...2,   step: 0.01)
                }
                Section("Highlight") {
                    SWGlassSliderRow(label: "Light Angle",       value: $config.lightAngle,        range: 0...360, step: 1)
                    SWGlassSliderRow(label: "Highlight",         value: $config.highlight,         range: 0...1,   step: 0.01)
                    SWGlassSliderRow(label: "Highlight Softness",value: $config.highlightSoftness, range: 0...1,   step: 0.01)
                    ColorPicker("Highlight Color", selection: $config.highlightColor, supportsOpacity: false)
                }
                Section("Fresnel") {
                    SWGlassSliderRow(label: "Fresnel",         value: $config.fresnel,         range: 0...1, step: 0.01)
                    SWGlassSliderRow(label: "Fresnel Softness",value: $config.fresnelSoftness, range: 0.01...1, step: 0.01)
                    ColorPicker("Fresnel Color", selection: $config.fresnelColor, supportsOpacity: false)
                }
                Section("Tint") {
                    SWGlassSliderRow(label: "Tint Intensity", value: $config.tintIntensity, range: 0...1, step: 0.01)
                    ColorPicker("Tint Color", selection: $config.tintColor, supportsOpacity: false)
                    Toggle("Preserve Luminosity", isOn: $config.tintPreserveLuminosity)
                }
            }
            .navigationTitle("Glass")
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

private struct SWGlassSliderRow: View {
    let label: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let step: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: "%.2f", Double(value)))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

// MARK: - Color → RGB (cross-platform, self-contained)

private extension Color {
    /// Resolve this color to a linear-ish sRGB `(r, g, b)` triple for the
    /// shader. Self-contained on purpose — no dependency on other SWPackage
    /// files. Falls back to white if the platform color cannot be resolved.
    var swGlassRGB: (Float, Float, Float) {
        #if canImport(UIKit)
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
        if UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (Float(r), Float(g), Float(b))
        }
        return (1, 1, 1)
        #elseif canImport(AppKit)
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? .white
        return (Float(ns.redComponent), Float(ns.greenComponent), Float(ns.blueComponent))
        #else
        return (1, 1, 1)
        #endif
    }
}

// MARK: - Preview

#Preview("Default") {
    NavigationStack {
        SWGlass(showsControls: true)
    }
}
