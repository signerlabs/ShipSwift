//
//  SWVoronoi.swift
//  ShipSwift
//
//  Animated Voronoi pattern rendered via a SwiftUI Metal `colorEffect`.
//  Anti-aliased cells with smooth customizable edges, up to 5 cell colors
//  in a step-discretized ramp, optional radial inner glow, and explicit
//  gap border between cells.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — 4-stop palette on white with subtle gap + glow
//    SWVoronoi()
//        .ignoresSafeArea()
//
//    // Custom palette + tighter gaps + stronger glow
//    SWVoronoi(
//        colors: [.indigo, .purple, .pink, .orange],
//        gap: 0.02,
//        glow: 0.6
//    )
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWVoronoi(showsControls: true)
//
//  Parameters:
//    - colors: 1–5 cell palette colors (default cyan / blue / purple /
//              pink 4-stop rainbow).
//    - colorBack: Background color (default `.white`).
//    - colorGap: Color of the border / gap between cells
//                (default `.black`).
//    - colorGlow: Color of the radial inner shadow inside cells
//                 (default `.black`).
//    - speed: Multiplier on the internal animation time (default `1.0`).
//    - scale: Pattern zoom + AA control in `0.3...5` — small = sparse
//             large cells, large = dense small cells (default `1.25`).
//    - distortion: Cell-center sin distortion in `0...0.5` (default `0.3`).
//    - gap: Border width between cells in `0...0.1` (default `0.01`).
//    - glow: Radial inner shadow strength in `0...1` (default `0`).
//    - stepsPerColor: Palette quantization steps in `1...3` (default `1`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a
//                     live-tuning sheet (default `false`).
//
//  Created by Wei Zhong on 5/25/26.
//

import SwiftUI

// MARK: - Main View

struct SWVoronoi: View {
    /// 1–5 cell palette colors.
    var colors: [Color] = [
        Color(red: 0.20, green: 0.85, blue: 0.95),  // cyan
        Color(red: 0.10, green: 0.40, blue: 0.95),  // blue
        Color(red: 0.55, green: 0.20, blue: 0.95),  // purple
        Color(red: 0.95, green: 0.30, blue: 0.65),  // pink
    ]

    var colorBack: Color = .white
    var colorGap:  Color = .black
    var colorGlow: Color = .black

    var speed: Float = 1.0

    /// Grid density — small = few large cells, large = many small cells.
    var scale: Float = 6

    /// Cell-center sin distortion in 0...0.5.
    var distortion: Float = 0.3

    /// Border width between cells in 0...0.1.
    var gap: Float = 0.01

    /// Radial inner shadow strength in 0...1.
    var glow: Float = 0

    /// Palette quantization steps in 1...3.
    var stepsPerColor: Float = 1

    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWVoronoiControlled(initial: self)
        } else {
            SWVoronoiRenderer(initial: self)
        }
    }
}

// MARK: - Renderer

private struct SWVoronoiRenderer: View {
    let initial: SWVoronoi

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            let slots = paddedSlots(initial.colors)
            let colorsCount = Float(max(min(initial.colors.count, 5), 1))

            initial.colorBack
                .colorEffect(
                    ShaderLibrary.swVoronoi(
                        .boundingRect,
                        .float(elapsed),
                        .float(initial.speed),
                        .float(initial.scale),
                        .float(initial.distortion),
                        .float(initial.gap),
                        .float(initial.glow),
                        .float(initial.stepsPerColor),
                        .float(colorsCount),
                        .color(slots[0]),
                        .color(slots[1]),
                        .color(slots[2]),
                        .color(slots[3]),
                        .color(slots[4]),
                        .color(initial.colorGap),
                        .color(initial.colorGlow),
                        .color(initial.colorBack)
                    )
                )
        }
    }

    private func paddedSlots(_ src: [Color]) -> [Color] {
        var out = Array(src.prefix(5))
        let tail = out.last ?? .black
        while out.count < 5 { out.append(tail) }
        return out
    }
}

// MARK: - Controlled Wrapper

private struct SWVoronoiControlled: View {
    @State private var colors: [Color]
    @State private var colorBack: Color
    @State private var colorGap: Color
    @State private var colorGlow: Color
    @State private var speed: Float
    @State private var scale: Float
    @State private var distortion: Float
    @State private var gap: Float
    @State private var glow: Float
    @State private var stepsPerColor: Float

    @State private var showSheet = false

    init(initial: SWVoronoi) {
        var palette = initial.colors
        while palette.count < 5 { palette.append(.white) }
        _colors        = State(initialValue: palette)
        _colorBack     = State(initialValue: initial.colorBack)
        _colorGap      = State(initialValue: initial.colorGap)
        _colorGlow     = State(initialValue: initial.colorGlow)
        _speed         = State(initialValue: initial.speed)
        _scale         = State(initialValue: initial.scale)
        _distortion    = State(initialValue: initial.distortion)
        _gap           = State(initialValue: initial.gap)
        _glow          = State(initialValue: initial.glow)
        _stepsPerColor = State(initialValue: initial.stepsPerColor)
    }

    var body: some View {
        SWVoronoiRenderer(
            initial: SWVoronoi(
                colors: colors,
                colorBack: colorBack,
                colorGap: colorGap,
                colorGlow: colorGlow,
                speed: speed,
                scale: scale,
                distortion: distortion,
                gap: gap,
                glow: glow,
                stepsPerColor: stepsPerColor
            )
        )
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Voronoi Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWVoronoiControlsSheet(
                colors: $colors,
                colorBack: $colorBack,
                colorGap: $colorGap,
                colorGlow: $colorGlow,
                speed: $speed,
                scale: $scale,
                distortion: $distortion,
                gap: $gap,
                glow: $glow,
                stepsPerColor: $stepsPerColor
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWVoronoiControlsSheet: View {
    @Binding var colors: [Color]
    @Binding var colorBack: Color
    @Binding var colorGap: Color
    @Binding var colorGlow: Color
    @Binding var speed: Float
    @Binding var scale: Float
    @Binding var distortion: Float
    @Binding var gap: Float
    @Binding var glow: Float
    @Binding var stepsPerColor: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Palette") {
                    ForEach(colors.indices, id: \.self) { i in
                        ColorPicker(
                            "Color \(i + 1)",
                            selection: Binding(
                                get: { colors[i] },
                                set: { colors[i] = $0 }
                            ),
                            supportsOpacity: false
                        )
                    }
                    ColorPicker("Background", selection: $colorBack, supportsOpacity: false)
                    ColorPicker("Gap",        selection: $colorGap,  supportsOpacity: false)
                    ColorPicker("Glow",       selection: $colorGlow, supportsOpacity: false)
                }

                Section("Cells") {
                    SliderRow(label: "Density",    value: $scale,         range: 0.3...5,  step: 0.05)
                    SliderRow(label: "Distortion", value: $distortion,    range: 0...0.5,  step: 0.01)
                    SliderRow(label: "Gap",        value: $gap,           range: 0...0.1,  step: 0.001)
                    SliderRow(label: "Glow",       value: $glow,          range: 0...1,    step: 0.01)
                    SliderRow(label: "Steps",      value: $stepsPerColor, range: 1...3,    step: 1)
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Voronoi")
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
                Text(formattedValue)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }

    private var formattedValue: String {
        if step >= 1   { return "\(Int(value.rounded()))" }
        if step < 0.01 { return String(format: "%.3f", value) }
        return String(format: "%.2f", value)
    }
}

// MARK: - Preview

#Preview("Default rainbow") {
    NavigationStack {
        SWVoronoi(showsControls: true)
    }
}

#Preview("Heavy glow") {
    SWVoronoi(
        colors: [.indigo, .purple, .pink, .orange],
        gap: 0.02,
        glow: 0.6
    )
    .ignoresSafeArea()
}
