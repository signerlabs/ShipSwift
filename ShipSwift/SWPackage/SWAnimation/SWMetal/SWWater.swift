//
//  SWWater.swift
//  ShipSwift
//
//  Wraps any view in a rippling caustic distortion via a SwiftUI Metal
//  `layerEffect` — a slow simplex-noise wave pushes UVs around while a
//  6-octave rotated caustic field paints sunlight-on-pool highlights
//  across the surface.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — gentle ripple with white highlights on black backing
//    SWWater {
//        Image(.facePicture)
//            .resizable()
//            .scaledToFill()
//    }
//
//    // Recolor — pool blue highlights, no wave drift
//    SWWater(
//        waves: 0,
//        highlights: 0.8,
//        colorBack: .black,
//        colorHighlight: Color(red: 0.4, green: 0.85, blue: 1.0)
//    ) {
//        Image(.facePicture)
//    }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWWater(showsControls: true) {
//        Image(.facePicture)
//    }
//
//  Parameters:
//    - speed: Multiplier on the internal animation time (default `1.0`).
//    - size: Pattern scale in `0.01...7` — small = tight pattern, large
//            = sparse waves (default `1.0`).
//    - caustic: Strength of the caustic UV distortion in `0...1`
//               (default `0.5`).
//    - waves: Strength of the simplex-noise wave distortion in `0...1`
//             (default `0.5`).
//    - layering: Weight of the 2nd caustic octave layered on top, in
//                `0...1` (default `0.5`).
//    - edges: How much the edge mask is flattened to 1.0 — `0` keeps the
//             distortion centered, `1` distorts the whole surface
//             (default `0.3`).
//    - highlights: Caustic highlight blend in `0...1` — drives both the
//                  tint mix and the additive sparkle (default `0.5`).
//    - colorBack: Backing color shown where the source layer is
//                 transparent (default `.black`).
//    - colorHighlight: Caustic highlight color (default `.white`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a
//                     live-tuning sheet (default `false`).
//
//  Created by Wei Zhong on 5/25/26.
//

import SwiftUI

// MARK: - Main View

struct SWWater<Content: View>: View {
    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// Pattern scale in 0.01...7 — small = tight, large = sparse.
    var size: Float = 1.0

    /// Strength of the caustic UV distortion in 0...1.
    var caustic: Float = 0.1

    /// Strength of the simplex-noise wave distortion in 0...1.
    var waves: Float = 0.08

    /// Weight of the 2nd caustic octave layered on top.
    var layering: Float = 0.15

    /// Edge mask flatness — 0 = distortion centered, 1 = distort everywhere.
    var edges: Float = 0.3

    /// Caustic highlight blend in 0...1 — drives tint + sparkle.
    var highlights: Float = 0.35

    /// Backing color shown where the source layer is transparent.
    var colorBack: Color = .black

    /// Caustic highlight color.
    var colorHighlight: Color = .white

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    private let content: Content

    init(
        speed: Float = 1.0,
        size: Float = 1.0,
        caustic: Float = 0.1,
        waves: Float = 0.08,
        layering: Float = 0.15,
        edges: Float = 0.3,
        highlights: Float = 0.35,
        colorBack: Color = .black,
        colorHighlight: Color = .white,
        showsControls: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.speed = speed
        self.size = size
        self.caustic = caustic
        self.waves = waves
        self.layering = layering
        self.edges = edges
        self.highlights = highlights
        self.colorBack = colorBack
        self.colorHighlight = colorHighlight
        self.showsControls = showsControls
        self.content = content()
    }

    var body: some View {
        if showsControls {
            SWWaterControlled(initial: self, content: content)
        } else {
            SWWaterRenderer(initial: self, content: content)
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWWaterRenderer<Content: View>: View {
    let initial: SWWater<Content>
    let content: Content

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            // `maxSampleOffset` covers the largest UV shift our distortion
            // can produce — caustic max ~0.02 of the layer + waves up to
            // 0.1 — well under 200pt for any reasonable layer.
            content.layerEffect(
                ShaderLibrary.swWater(
                    .boundingRect,
                    .float(elapsed),
                    .float(initial.speed),
                    .float(initial.size),
                    .float(initial.caustic),
                    .float(initial.waves),
                    .float(initial.layering),
                    .float(initial.edges),
                    .float(initial.highlights),
                    .color(initial.colorBack),
                    .color(initial.colorHighlight)
                ),
                maxSampleOffset: CGSize(width: 200, height: 200)
            )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWWaterControlled<Content: View>: View {
    @State private var speed: Float
    @State private var size: Float
    @State private var caustic: Float
    @State private var waves: Float
    @State private var layering: Float
    @State private var edges: Float
    @State private var highlights: Float
    @State private var colorBack: Color
    @State private var colorHighlight: Color

    @State private var showSheet = false

    private let content: Content

    init(initial: SWWater<Content>, content: Content) {
        _speed          = State(initialValue: initial.speed)
        _size           = State(initialValue: initial.size)
        _caustic        = State(initialValue: initial.caustic)
        _waves          = State(initialValue: initial.waves)
        _layering       = State(initialValue: initial.layering)
        _edges          = State(initialValue: initial.edges)
        _highlights     = State(initialValue: initial.highlights)
        _colorBack      = State(initialValue: initial.colorBack)
        _colorHighlight = State(initialValue: initial.colorHighlight)
        self.content = content
    }

    var body: some View {
        SWWaterRenderer(
            initial: SWWater(
                speed: speed,
                size: size,
                caustic: caustic,
                waves: waves,
                layering: layering,
                edges: edges,
                highlights: highlights,
                colorBack: colorBack,
                colorHighlight: colorHighlight
            ) { content },
            content: content
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Water Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWWaterControlsSheet(
                speed: $speed,
                size: $size,
                caustic: $caustic,
                waves: $waves,
                layering: $layering,
                edges: $edges,
                highlights: $highlights,
                colorBack: $colorBack,
                colorHighlight: $colorHighlight
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWWaterControlsSheet: View {
    @Binding var speed: Float
    @Binding var size: Float
    @Binding var caustic: Float
    @Binding var waves: Float
    @Binding var layering: Float
    @Binding var edges: Float
    @Binding var highlights: Float
    @Binding var colorBack: Color
    @Binding var colorHighlight: Color

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Colors") {
                    ColorPicker("Back",      selection: $colorBack,      supportsOpacity: false)
                    ColorPicker("Highlight", selection: $colorHighlight, supportsOpacity: false)
                }

                Section("Pattern") {
                    SliderRow(label: "Size",       value: $size,       range: 0.01...7, step: 0.01)
                    SliderRow(label: "Caustic",    value: $caustic,    range: 0...1,    step: 0.01)
                    SliderRow(label: "Waves",      value: $waves,      range: 0...1,    step: 0.01)
                    SliderRow(label: "Layering",   value: $layering,   range: 0...1,    step: 0.01)
                    SliderRow(label: "Edges",      value: $edges,      range: 0...1,    step: 0.01)
                    SliderRow(label: "Highlights", value: $highlights, range: 0...1,    step: 0.01)
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Water")
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
        SWWater(showsControls: true) {
            Image(.facePicture)
                .resizable()
                .scaledToFill()
        }
    }
}

#Preview("Pool blue") {
    SWWater(
        highlights: 0.8,
        colorBack: .black,
        colorHighlight: Color(red: 0.4, green: 0.85, blue: 1.0)
    ) {
        Image(.facePicture)
            .resizable()
            .scaledToFill()
    }
}
