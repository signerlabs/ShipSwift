//
//  SWGlassOrb.swift
//  ShipSwift
//
//  Adapted from Inferno's "Warping Loupe" by Paul Hudson
//  https://github.com/twostraws/Inferno
//  Licensed under the MIT License. Copyright (c) 2023 Paul Hudson and other authors.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  A draggable glass orb with a built-in gradient fill. The orb is one
//  self-contained view: a vertical color gradient (its own background) sits
//  under a Metal `layerEffect` that magnifies and refracts that gradient with a
//  spherical (barrel) warp, a cool Fresnel rim, an upper-left specular
//  hot-spot, and optional rim RGB dispersion. The gradient belongs to the orb,
//  so dragging the orb carries the whole thing — gradient, refraction and
//  highlights move together (the centre stays fixed in the orb's own frame and
//  the entire view is translated). The gradient's hue cycles over time so the
//  orb's color slowly flows.
//
//  Inferno's Warping Loupe contributes the core refraction maths; the sphere
//  cues (Fresnel rim, specular, dispersion, contact shadow) are added here.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`, Metal `stitchable`).
//
//  Usage:
//    // Default gradient orb — draggable, with a slowly flowing hue.
//    SWGlassOrb()
//
//    // Custom size + gradient (top → bottom).
//    SWGlassOrb(radius: 150, colors: [.indigo, .blue, .teal, .green])
//
//    // Demo — dark canvas + gear toolbar item + live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWGlassOrb(showsControls: true)
//
//  Parameters:
//    - radius: Orb radius in points (default `120`).
//    - magnification: Peak zoom at the orb centre (default `1.6` = 1.6x).
//    - refraction: Spherical barrel-warp strength, 0...1 (default `0.5`).
//    - edgeHighlight: Fresnel rim + specular strength, 0...1 (default `0.6`).
//    - dispersion: Rim RGB-split strength, 0...1 (default `0.25`; 0 disables).
//    - colors: Vertical gradient fill, top → bottom (default indigo → green).
//    - colorFlow: Hue-rotation speed in degrees/second for a flowing color
//                 cycle (default `30`; 0 = static).
//    - showsControls: Wrap in a dark demo canvas with a gear toolbar item +
//                     live-tuning sheet (default `false`).
//

import SwiftUI

// MARK: - SWGlassOrb

struct SWGlassOrb: View {
    /// Orb radius in points.
    var radius: CGFloat = 120

    /// Peak zoom at the orb centre (1.6 = 1.6x).
    var magnification: CGFloat = 1.6

    /// Strength of the spherical barrel warp, 0...1.
    var refraction: CGFloat = 0.5

    /// Strength of the Fresnel rim + specular + shading, 0...1.
    var edgeHighlight: CGFloat = 0.6

    /// Rim RGB-split strength, 0...1 (0 disables).
    var dispersion: CGFloat = 0.25

    /// Vertical gradient fill, top → bottom.
    var colors: [Color] = SWGlassOrb.defaultColors

    /// Hue-rotation speed in degrees/second for a flowing color cycle (0 = static).
    var colorFlow: Double = 30

    /// When `true`, wraps the orb in a dark demo canvas with a gear toolbar
    /// item that opens a live-tuning sheet.
    var showsControls: Bool = false

    /// Default gradient: indigo → blue → teal → green → green (top → bottom).
    static let defaultColors: [Color] = [
        Color(.indigo),
        Color(.blue),
        Color(.teal),
        Color(.green),
        Color(.green)
    ]

    init(
        radius: CGFloat = 120,
        magnification: CGFloat = 1.6,
        refraction: CGFloat = 0.5,
        edgeHighlight: CGFloat = 0.6,
        dispersion: CGFloat = 0.25,
        colors: [Color] = SWGlassOrb.defaultColors,
        colorFlow: Double = 30,
        showsControls: Bool = false
    ) {
        self.radius = radius
        self.magnification = magnification
        self.refraction = refraction
        self.edgeHighlight = edgeHighlight
        self.dispersion = dispersion
        self.colors = colors
        self.colorFlow = colorFlow
        self.showsControls = showsControls
    }

    var body: some View {
        if showsControls {
            SWGlassOrbControlled(initial: self)
        } else {
            SWGlassOrbBody(
                radius: radius,
                magnification: magnification,
                refraction: refraction,
                edgeHighlight: edgeHighlight,
                dispersion: dispersion,
                colors: colors,
                colorFlow: colorFlow
            )
        }
    }
}

// MARK: - Orb Body (gradient fill + flowing hue + refraction + drag-to-move)

/// The orb itself: a circular gradient fill whose hue cycles over time, refracted
/// by the glass shader, with the whole view draggable. The gradient is the orb's
/// own background, so it travels with the orb — dragging carries gradient,
/// refraction and highlights together. `hueRotation` is applied to the gradient
/// *before* the shader, so only the fill flows; the shader's Fresnel rim and
/// specular stay cool-white. The shader centre is fixed at the frame's middle;
/// movement is a plain `.offset` on the whole view (outside `TimelineView` so the
/// drag stays stable across animation frames).
private struct SWGlassOrbBody: View {
    let radius: CGFloat
    let magnification: CGFloat
    let refraction: CGFloat
    let edgeHighlight: CGFloat
    let dispersion: CGFloat
    let colors: [Color]
    let colorFlow: Double

    /// Committed position offset; updated when each drag ends.
    @State private var position: CGSize = .zero
    /// Live drag translation; resets to zero automatically when the drag ends.
    @GestureState private var drag: CGSize = .zero

    var body: some View {
        let diameter = radius * 2
        // The orb only samples within its own radius, so one radius of budget
        // is plenty for the magnified / dispersed taps.
        let maxOffset = radius + 24

        TimelineView(.animation) { context in
            // Cycle the gradient's hue over time so the orb's color flows. Kept
            // within 0...360 to avoid float-precision jitter on a large clock.
            let t = context.date.timeIntervalSinceReferenceDate
            let hueDegrees = colorFlow == 0
                ? 0
                : (t * colorFlow).truncatingRemainder(dividingBy: 360)

            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                .hueRotation(.degrees(hueDegrees))
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
                .layerEffect(
                    ShaderLibrary.swGlassOrb(
                        .boundingRect,
                        .float2(Float(radius), Float(radius)), // centre = frame middle
                        .float(Float(radius)),
                        .float(Float(magnification)),
                        .float(Float(refraction)),
                        .float(Float(edgeHighlight)),
                        .float(Float(dispersion))
                    ),
                    maxSampleOffset: CGSize(width: maxOffset, height: maxOffset)
                )
        }
        .offset(x: position.width + drag.width, y: position.height + drag.height)
        .gesture(
            DragGesture()
                .updating($drag) { value, state, _ in state = value.translation }
                .onEnded { value in
                    position.width += value.translation.width
                    position.height += value.translation.height
                }
        )
    }
}

// MARK: - Controlled Wrapper (dark demo canvas + gear toolbar item + live sheet)

private struct SWGlassOrbControlled: View {
    @State private var radius: CGFloat
    @State private var magnification: CGFloat
    @State private var refraction: CGFloat
    @State private var edgeHighlight: CGFloat
    @State private var dispersion: CGFloat
    @State private var colorFlow: Double
    private let colors: [Color]

    @State private var showSheet = false

    init(initial: SWGlassOrb) {
        _radius        = State(initialValue: initial.radius)
        _magnification = State(initialValue: initial.magnification)
        _refraction    = State(initialValue: initial.refraction)
        _edgeHighlight = State(initialValue: initial.edgeHighlight)
        _dispersion    = State(initialValue: initial.dispersion)
        _colorFlow     = State(initialValue: initial.colorFlow)
        self.colors = initial.colors
    }

    var body: some View {
        ZStack {
            // Fixed dark demo canvas — the orb is dragged across it.
            Color(.black)
                .ignoresSafeArea()

            SWGlassOrbBody(
                radius: radius,
                magnification: magnification,
                refraction: refraction,
                edgeHighlight: edgeHighlight,
                dispersion: dispersion,
                colors: colors,
                colorFlow: colorFlow
            )
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Glass Orb Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWGlassOrbControlsSheet(
                radius: $radius,
                magnification: $magnification,
                refraction: $refraction,
                edgeHighlight: $edgeHighlight,
                dispersion: $dispersion,
                colorFlow: $colorFlow
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWGlassOrbControlsSheet: View {
    @Binding var radius: CGFloat
    @Binding var magnification: CGFloat
    @Binding var refraction: CGFloat
    @Binding var edgeHighlight: CGFloat
    @Binding var dispersion: CGFloat
    @Binding var colorFlow: Double

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Lens") {
                    SWGlassOrbSliderRow(label: "Radius",        value: $radius,        range: 40...220,  step: 1)
                    SWGlassOrbSliderRow(label: "Magnification", value: $magnification, range: 1...3,     step: 0.05)
                    SWGlassOrbSliderRow(label: "Refraction",    value: $refraction,    range: 0...1,     step: 0.01)
                }
                Section("Glass") {
                    SWGlassOrbSliderRow(label: "Edge Highlight", value: $edgeHighlight, range: 0...1, step: 0.01)
                    SWGlassOrbSliderRow(label: "Dispersion",     value: $dispersion,    range: 0...1, step: 0.01)
                }
                Section("Color") {
                    SWGlassOrbSliderRow(
                        label: "Color Flow",
                        value: Binding(get: { CGFloat(colorFlow) }, set: { colorFlow = Double($0) }),
                        range: 0...120,
                        step: 1
                    )
                }
            }
            .navigationTitle("Glass Orb")
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

private struct SWGlassOrbSliderRow: View {
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

// MARK: - Preview

#Preview("Default") {
    NavigationStack {
        SWGlassOrb(showsControls: true)
    }
}
