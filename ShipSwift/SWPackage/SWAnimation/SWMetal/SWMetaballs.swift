//
//  SWMetaballs.swift
//  ShipSwift
//
//  Renders a cluster of soft blobs whose colors blend smoothly where they
//  overlap, over a flat background, via a SwiftUI Metal stitchable shader.
//  No spherical lighting / rim / specular — straight 2D shape blending.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — 5-color rainbow on black
//    ZStack {
//        SWMetaballs()
//            .ignoresSafeArea()
//        // Your content here
//    }
//
//    // Recolor — sunset palette
//    SWMetaballs(
//        colors: [.yellow, .orange, .red, .purple],
//        background: .black,
//        count: 6,
//        size: 0.7
//    )
//
//    // As a section background
//    myContent
//        .background { SWMetaballs() }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    // Disabled by default; requires an enclosing `NavigationStack`.
//    SWMetaballs(showsControls: true)
//
//  Parameters:
//    - colors: Per-ball palette, 1–8 entries. Ball `i` picks
//              `colors[i % colors.count]`, so adding more balls than
//              colors cycles through the palette. Default is a 5-color
//              rainbow (`#CC3333`, `#CC9933`, `#99CC33`, `#33CC33`,
//              `#33CC99`).
//    - background: Color rendered behind the blobs (default `.black`).
//    - speed: Multiplier on the internal drift time (default `1.0`).
//    - count: Number of blobs, clamped to `1...8` by the shader
//              (default `5`).
//    - size: Per-ball size factor in `0...1` (default `0.83`). Larger =
//              fatter blobs.
//    - showsControls: When `true`, attaches a gear `ToolbarItem` to the
//              enclosing `NavigationStack` that opens a live-tuning
//              sheet. Default `false`.
//
//  Notes:
//    - SwiftUI shader parameters can't be arrays, so internally the
//      palette is packed into eight independent `Color` slots plus a
//      `colorsCount` scalar. Extra slots are filled with `.clear`.
//    - Loops capped at 8 balls to fit SwiftUI's stitchable shader
//      instruction budget.
//
//  Created by Wei Zhong on 5/24/26.
//

import SwiftUI

// MARK: - Style

enum SWMetaballsStyle: String, CaseIterable, Identifiable {
    /// Balls meander on independent noise drifts (the original look).
    case cluster
    /// A big central ball with small balls streaming in from the bottom and
    /// out the top.
    case fountain

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cluster:  "Cluster"
        case .fountain: "Fountain"
        }
    }

    /// Metal `stitchable` function name in the default `ShaderLibrary`.
    var shaderName: String {
        switch self {
        case .cluster:  "swMetaballs"
        case .fountain: "swMetaballsFountain"
        }
    }
}

// MARK: - Main View

struct SWMetaballs: View {
    /// Rendering style — `.cluster` (independent noise drift) or `.fountain`
    /// (big central ball with small balls streaming in / out).
    var style: SWMetaballsStyle = .cluster

    /// Per-ball palette (1–8 entries). Ball `i` picks `colors[i % colors.count]`.
    var colors: [Color] = [Color.red,
                           Color.green,
                           Color.white,
                           Color.yellow,
                           Color.blue,
                           Color.teal,
                           Color.purple]

    /// Color rendered behind the blobs.
    var background: Color = .black

    /// Multiplier on the internal drift time.
    var speed: Float = 1.0

    /// Number of blobs (clamped to 1...8 by the shader).
    var count: Int = 8

    /// Per-ball size factor in 0...1. Larger = fatter blobs.
    var size: Float = 0.8

    /// Big central ball size for the `.fountain` style (0...1, independent of
    /// `size`). Ignored by `.cluster`.
    var bigSize: Float = 0.85

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWMetaballsControlled(initial: self)
        } else {
            SWMetaballsRenderer(
                style: style,
                colors: colors,
                background: background,
                speed: speed,
                count: count,
                size: size,
                bigSize: bigSize
            )
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWMetaballsRenderer: View {
    let style: SWMetaballsStyle
    let colors: [Color]
    let background: Color
    let speed: Float
    let count: Int
    let size: Float
    let bigSize: Float

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            // Pack colors into 8 fixed slots; pad with `.clear` so unused
            // slots don't contribute (they're never indexed when
            // colorsCount is correct, but premultiplied alpha keeps
            // them harmless if they ever were).
            let slots = paddedSlots(colors)
            let colorsCount = Float(max(min(colors.count, 8), 1))

            // Fountain takes one extra arg (big ball size); build the list in a
            // closure so the ViewBuilder body stays a single view expression.
            let arguments: [Shader.Argument] = {
                var a: [Shader.Argument] = [
                    .boundingRect,
                    .float(elapsed),
                    .float(speed),
                    .float(Float(count)),
                    .float(size),
                    .float(colorsCount),
                    .color(slots[0]),
                    .color(slots[1]),
                    .color(slots[2]),
                    .color(slots[3]),
                    .color(slots[4]),
                    .color(slots[5]),
                    .color(slots[6]),
                    .color(slots[7]),
                    .color(background)
                ]
                if style == .fountain {
                    a.append(.float(bigSize))
                }
                return a
            }()

            background
                .colorEffect(
                    Shader(
                        function: ShaderFunction(library: .default, name: style.shaderName),
                        arguments: arguments
                    )
                )
        }
    }

    private func paddedSlots(_ src: [Color]) -> [Color] {
        var out = Array(src.prefix(8))
        while out.count < 8 {
            out.append(.clear)
        }
        return out
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWMetaballsControlled: View {
    @State private var style: SWMetaballsStyle
    @State private var colors: [Color]
    @State private var background: Color
    @State private var speed: Float
    /// Float-backed so it can drive a Slider; rendered as `Int(.rounded())`.
    @State private var count: Float
    @State private var size: Float
    @State private var bigSize: Float

    @State private var showSheet = false

    init(initial: SWMetaballs) {
        // Pad up to a stable 5-slot working set for the picker UI so the
        // sliders don't shuffle when the palette length changes.
        var palette = initial.colors
        while palette.count < 5 { palette.append(.white) }
        _style      = State(initialValue: initial.style)
        _colors     = State(initialValue: palette)
        _background = State(initialValue: initial.background)
        _speed      = State(initialValue: initial.speed)
        _count      = State(initialValue: Float(initial.count))
        _size       = State(initialValue: initial.size)
        _bigSize    = State(initialValue: initial.bigSize)
    }

    var body: some View {
        SWMetaballsRenderer(
            style: style,
            colors: colors,
            background: background,
            speed: speed,
            count: Int(count.rounded()),
            size: size,
            bigSize: bigSize
        )
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Metaballs Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWMetaballsControlsSheet(
                style: $style,
                colors: $colors,
                background: $background,
                speed: $speed,
                count: $count,
                size: $size,
                bigSize: $bigSize
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWMetaballsControlsSheet: View {
    @Binding var style: SWMetaballsStyle
    @Binding var colors: [Color]
    @Binding var background: Color
    @Binding var speed: Float
    @Binding var count: Float
    @Binding var size: Float
    @Binding var bigSize: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Style") {
                    Picker("Style", selection: $style) {
                        ForEach(SWMetaballsStyle.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                }

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
                    ColorPicker("Background", selection: $background, supportsOpacity: false)
                }

                Section("Field") {
                    SliderRow(label: "Count", value: $count, range: style == .fountain ? 1...99 : 1...8, step: 1)
                    SliderRow(label: "Size",  value: $size,  range: 0...1, step: 0.01)
                    if style == .fountain {
                        SliderRow(label: "Big Ball Size", value: $bigSize, range: 0...1, step: 0.01)
                    }
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Metaballs")
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

    /// Integer-stepped sliders display as whole numbers.
    private var formattedValue: String {
        step >= 1
            ? "\(Int(value.rounded()))"
            : String(format: "%.2f", value)
    }
}

// MARK: - Preview

#Preview {
    // ToolbarItem requires an enclosing NavigationStack to render.
    NavigationStack {
        SWMetaballs(showsControls: true)
    }
}
