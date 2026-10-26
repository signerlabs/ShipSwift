//
//  SWDotOrbit.swift
//  ShipSwift
//
//  Animated multi-color dots rendered via a SwiftUI Metal `colorEffect`,
//  each orbiting around its own Voronoi-cell center, mapped onto a 1–10
//  color step-discretized gradient.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — 5-stop rainbow orbiting on white, full-screen
//    SWDotOrbit()
//        .ignoresSafeArea()
//
//    // Custom palette + bigger spread
//    SWDotOrbit(
//        colors: [.indigo, .purple, .pink, .orange, .yellow],
//        spreading: 0.8
//    )
//
//    // As a section background
//    myContent.background { SWDotOrbit() }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWDotOrbit(showsControls: true)
//
//  Parameters:
//    - colors: 1–10 dot palette colors (default cyan / blue / purple /
//              pink / yellow 5-stop rainbow).
//    - colorBack: Background color (default `.white`).
//    - speed: Multiplier on the internal animation time (default `1.0`).
//    - scale: Grid density — small = sparse / few dots, large = dense /
//             many dots; controls how many dot cells fit in the view
//             (default `1.5`).
//    - size: Dot radius relative to cell in `0...1` (default `0.5`).
//    - sizeRange: Random per-dot size variation in `0...1` (default `0.5`).
//    - spreading: Maximum orbit distance around cell center in `0...1`
//                 (default `0.5`).
//    - stepsPerColor: Palette quantization steps in `1...4` — `1` gives
//                     hard color stops, higher values blend (default `1`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a
//                     live-tuning sheet (default `false`).
//
//  Created by Wei Zhong on 5/25/26.
//

import SwiftUI

// MARK: - Main View

struct SWDotOrbit: View {
    /// 1–10 dot palette colors.
    var colors: [Color] = [
        Color(red: 0.20, green: 0.85, blue: 0.95),  // cyan
        Color(red: 0.10, green: 0.40, blue: 0.95),  // blue
        Color(red: 0.55, green: 0.20, blue: 0.95),  // purple
        Color(red: 0.95, green: 0.30, blue: 0.65),  // pink
        Color(red: 1.00, green: 0.85, blue: 0.20),  // yellow
    ]

    /// Background color.
    var colorBack: Color = .white

    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// Grid density — small = sparse / few dots, large = dense / many dots.
    /// `scale = 0.5` ≈ very few large dots, `5` ≈ many small dots (default `1.5`).
    var scale: Float = 10

    /// Dot radius relative to cell in 0...1.
    var size: Float = 1

    /// Random per-dot size variation in 0...1.
    var sizeRange: Float = 0.5

    /// Maximum orbit distance around cell center in 0...1.
    var spreading: Float = 1

    /// Palette quantization steps in 1...4 (1 = hard stops).
    var stepsPerColor: Float = 1

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWDotOrbitControlled(initial: self)
        } else {
            SWDotOrbitRenderer(initial: self)
        }
    }
}

// MARK: - Renderer

private struct SWDotOrbitRenderer: View {
    let initial: SWDotOrbit

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            let slots = paddedSlots(initial.colors)
            let colorsCount = Float(max(min(initial.colors.count, 10), 1))

            initial.colorBack
                .colorEffect(
                    ShaderLibrary.swDotOrbit(
                        .boundingRect,
                        .float(elapsed),
                        .float(initial.speed),
                        .float(initial.scale),
                        .float(initial.size),
                        .float(initial.sizeRange),
                        .float(initial.spreading),
                        .float(initial.stepsPerColor),
                        .float(colorsCount),
                        .color(slots[0]),
                        .color(slots[1]),
                        .color(slots[2]),
                        .color(slots[3]),
                        .color(slots[4]),
                        .color(slots[5]),
                        .color(slots[6]),
                        .color(slots[7]),
                        .color(slots[8]),
                        .color(slots[9]),
                        .color(initial.colorBack)
                    )
                )
        }
    }

    private func paddedSlots(_ src: [Color]) -> [Color] {
        var out = Array(src.prefix(10))
        let tail = out.last ?? .black
        while out.count < 10 { out.append(tail) }
        return out
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWDotOrbitControlled: View {
    @State private var colors: [Color]
    @State private var colorBack: Color
    @State private var speed: Float
    @State private var scale: Float
    @State private var size: Float
    @State private var sizeRange: Float
    @State private var spreading: Float
    @State private var stepsPerColor: Float

    @State private var showSheet = false

    init(initial: SWDotOrbit) {
        var palette = initial.colors
        while palette.count < 5 { palette.append(.white) }
        _colors        = State(initialValue: palette)
        _colorBack     = State(initialValue: initial.colorBack)
        _speed         = State(initialValue: initial.speed)
        _scale         = State(initialValue: initial.scale)
        _size          = State(initialValue: initial.size)
        _sizeRange     = State(initialValue: initial.sizeRange)
        _spreading     = State(initialValue: initial.spreading)
        _stepsPerColor = State(initialValue: initial.stepsPerColor)
    }

    var body: some View {
        SWDotOrbitRenderer(
            initial: SWDotOrbit(
                colors: colors,
                colorBack: colorBack,
                speed: speed,
                scale: scale,
                size: size,
                sizeRange: sizeRange,
                spreading: spreading,
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
                .accessibilityLabel("Dot Orbit Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWDotOrbitControlsSheet(
                colors: $colors,
                colorBack: $colorBack,
                speed: $speed,
                scale: $scale,
                size: $size,
                sizeRange: $sizeRange,
                spreading: $spreading,
                stepsPerColor: $stepsPerColor
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWDotOrbitControlsSheet: View {
    @Binding var colors: [Color]
    @Binding var colorBack: Color
    @Binding var speed: Float
    @Binding var scale: Float
    @Binding var size: Float
    @Binding var sizeRange: Float
    @Binding var spreading: Float
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
                }

                Section("Dots") {
                    SliderRow(label: "Density",    value: $scale,         range: 0.5...10, step: 0.1)
                    SliderRow(label: "Size",       value: $size,          range: 0...1,    step: 0.01)
                    SliderRow(label: "Size Range", value: $sizeRange,     range: 0...1,    step: 0.01)
                    SliderRow(label: "Spreading",  value: $spreading,     range: 0...1,    step: 0.01)
                    SliderRow(label: "Steps",      value: $stepsPerColor, range: 1...4,    step: 1)
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Dot Orbit")
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
        step >= 1
            ? "\(Int(value.rounded()))"
            : String(format: "%.2f", value)
    }
}

// MARK: - Preview

#Preview("Default rainbow") {
    NavigationStack {
        SWDotOrbit(showsControls: true)
    }
}

#Preview("Indigo set") {
    SWDotOrbit(
        colors: [.indigo, .purple, .pink, .orange],
        spreading: 0.8
    )
    .ignoresSafeArea()
}
