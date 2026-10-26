//
//  SWColorPanels.swift
//  ShipSwift
//
//  Pseudo-3D semi-transparent panels rendered via a SwiftUI Metal
//  `colorEffect`, rotating around a central vertical axis.
//
//  Algorithm: analytic perspective projection — for each pixel the
//  shader walks 12–20 candidate panels (count depends on `colors.count`
//  so the wheel reads coherently), checks z-depth & lateral position,
//  and composites the surviving fragment. Two interleaved sets
//  (forward / reverse rotation) keep the wheel continuous.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`, `colorEffect`,
//  Metal `stitchable`).
//
//  Usage:
//    // Default — red / yellow / cyan / pink on a deep blue back, full-screen
//    SWColorPanels()
//        .ignoresSafeArea()
//
//    // Recolor — pastels on white
//    SWColorPanels(
//        colors: [.pink, .yellow, .mint, .indigo],
//        colorBack: .white
//    )
//
//    // As a section background
//    myContent.background { SWColorPanels() }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    SWColorPanels(showsControls: true)
//
//  Parameters:
//    - colors:       1–7 panel palette colors (default red / yellow /
//                    cyan / pink).
//    - colorBack:    Background color behind the panels
//                    (default deep indigo `#0E0E14`).
//    - density:      Angle between consecutive panels, 0.25...7
//                    (default 2.0; smaller = denser fan).
//    - angle1:       Top-edge skew, -1...1 (default 0).
//    - angle2:       Bottom-edge skew, -1...1 (default 0).
//    - panelLength:  Panel length relative to height, 0.05...3
//                    (default 1.0).
//    - edges:        Edge highlight on/off (default `true`).
//    - blur:         Side blur in 0...0.5 (default 0.1, 0 = sharp).
//    - fadeIn:       Transparency near the central axis in 0...1
//                    (default 0.5).
//    - fadeOut:      Transparency near the viewer in 0...1
//                    (default 0.5).
//    - gradient:     Intra-panel color mixing in 0...1
//                    (default 0; 0 = solid, 1 = gradient).
//    - scale:        Overall zoom in 0.05...4 (default 1.0).
//    - speed:        Multiplier on the internal animation time
//                    (default 1.0).
//    - showsControls: Attach a gear `ToolbarItem` that opens a
//                     live-tuning sheet (default `false`).
//

import SwiftUI

// MARK: - Main View

struct SWColorPanels: View {
    /// 1–7 panel palette colors. Extra entries beyond 7 are dropped.
    var colors: [Color] = [
        Color(red: 0.95, green: 0.20, blue: 0.30),  // red
        Color(red: 0.98, green: 0.85, blue: 0.20),  // yellow
        Color(red: 0.25, green: 0.85, blue: 0.95),  // cyan
        Color(red: 0.95, green: 0.40, blue: 0.75)   // pink
    ]

    /// Background color.
    var colorBack: Color = Color(red: 0.055, green: 0.055, blue: 0.08)  // #0E0E14

    /// Angle between consecutive panels, 0.25...7.
    var density: Float = 2.0

    /// Top-edge skew, -1...1.
    var angle1: Float = 0.0

    /// Bottom-edge skew, -1...1.
    var angle2: Float = 0.0

    /// Panel length relative to height, 0.05...3.
    var panelLength: Float = 1.0

    /// Edge highlight on/off.
    var edges: Bool = true

    /// Side blur in 0...0.5.
    var blur: Float = 0.1

    /// Transparency near the central axis in 0...1.
    var fadeIn: Float = 0.5

    /// Transparency near the viewer in 0...1.
    var fadeOut: Float = 0.5

    /// Intra-panel color mixing in 0...1 (0 = solid, 1 = gradient).
    var gradient: Float = 0.0

    /// Overall zoom in 0.05...4.
    var scale: Float = 1.0

    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a
    /// live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWColorPanelsControlled(initial: self)
        } else {
            SWColorPanelsRenderer(
                colors: colors,
                colorBack: colorBack,
                density: density,
                angle1: angle1,
                angle2: angle2,
                panelLength: panelLength,
                edges: edges,
                blur: blur,
                fadeIn: fadeIn,
                fadeOut: fadeOut,
                gradient: gradient,
                scale: scale,
                speed: speed
            )
        }
    }
}

// MARK: - Renderer

private struct SWColorPanelsRenderer: View {
    let colors: [Color]
    let colorBack: Color
    let density: Float
    let angle1: Float
    let angle2: Float
    let panelLength: Float
    let edges: Bool
    let blur: Float
    let fadeIn: Float
    let fadeOut: Float
    let gradient: Float
    let scale: Float
    let speed: Float

    @State private var start: Date = .now

    var body: some View {
        let slots = paddedSlots(colors)
        let colorsCount = Float(max(min(colors.count, 7), 1))

        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start)) * speed
            // Base layer must be opaque — `colorBack` doubles as the
            // first-frame fallback before the shader is invoked.
            colorBack
                .colorEffect(
                    ShaderLibrary.swColorPanels(
                        .boundingRect,
                        .float(elapsed),
                        .float(scale),
                        .float(colorsCount),
                        .float(density),
                        .float(angle1),
                        .float(angle2),
                        .float(panelLength),
                        .float(edges ? 1.0 : 0.0),
                        .float(blur),
                        .float(fadeIn),
                        .float(fadeOut),
                        .float(gradient),
                        .color(colorBack),
                        .color(slots[0]),
                        .color(slots[1]),
                        .color(slots[2]),
                        .color(slots[3]),
                        .color(slots[4]),
                        .color(slots[5]),
                        .color(slots[6])
                    )
                )
        }
    }

    /// Pad palette to exactly 7 entries by repeating the tail color.
    /// Slots beyond `colorsCount` are not used by the shader; padding
    /// just keeps the parameter list well-formed.
    private func paddedSlots(_ src: [Color]) -> [Color] {
        var out = Array(src.prefix(7))
        let tail = out.last ?? .black
        while out.count < 7 { out.append(tail) }
        return out
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWColorPanelsControlled: View {
    @State private var colors: [Color]
    @State private var colorBack: Color
    @State private var density: Float
    @State private var angle1: Float
    @State private var angle2: Float
    @State private var panelLength: Float
    @State private var edges: Bool
    @State private var blur: Float
    @State private var fadeIn: Float
    @State private var fadeOut: Float
    @State private var gradient: Float
    @State private var scale: Float
    @State private var speed: Float

    @State private var showSheet = false

    init(initial: SWColorPanels) {
        let trimmed = Array(initial.colors.prefix(7))
        _colors      = State(initialValue: trimmed.isEmpty ? [.white] : trimmed)
        _colorBack   = State(initialValue: initial.colorBack)
        _density     = State(initialValue: initial.density)
        _angle1      = State(initialValue: initial.angle1)
        _angle2      = State(initialValue: initial.angle2)
        _panelLength = State(initialValue: initial.panelLength)
        _edges       = State(initialValue: initial.edges)
        _blur        = State(initialValue: initial.blur)
        _fadeIn      = State(initialValue: initial.fadeIn)
        _fadeOut     = State(initialValue: initial.fadeOut)
        _gradient    = State(initialValue: initial.gradient)
        _scale       = State(initialValue: initial.scale)
        _speed       = State(initialValue: initial.speed)
    }

    var body: some View {
        SWColorPanelsRenderer(
            colors: colors,
            colorBack: colorBack,
            density: density,
            angle1: angle1,
            angle2: angle2,
            panelLength: panelLength,
            edges: edges,
            blur: blur,
            fadeIn: fadeIn,
            fadeOut: fadeOut,
            gradient: gradient,
            scale: scale,
            speed: speed
        )
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Color Panels Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWColorPanelsControlsSheet(
                colors: $colors,
                colorBack: $colorBack,
                density: $density,
                angle1: $angle1,
                angle2: $angle2,
                panelLength: $panelLength,
                edges: $edges,
                blur: $blur,
                fadeIn: $fadeIn,
                fadeOut: $fadeOut,
                gradient: $gradient,
                scale: $scale,
                speed: $speed
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWColorPanelsControlsSheet: View {
    @Binding var colors: [Color]
    @Binding var colorBack: Color
    @Binding var density: Float
    @Binding var angle1: Float
    @Binding var angle2: Float
    @Binding var panelLength: Float
    @Binding var edges: Bool
    @Binding var blur: Float
    @Binding var fadeIn: Float
    @Binding var fadeOut: Float
    @Binding var gradient: Float
    @Binding var scale: Float
    @Binding var speed: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(colors.indices, id: \.self) { i in
                        ColorPicker("Panel \(i + 1)",
                                    selection: $colors[i],
                                    supportsOpacity: true)
                    }
                    ColorPicker("Background",
                                selection: $colorBack,
                                supportsOpacity: false)
                } header: {
                    HStack {
                        Text("Palette (\(colors.count) / 7)")
                        Spacer()
                        Button {
                            if colors.count > 1 { colors.removeLast() }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .disabled(colors.count <= 1)
                        Button {
                            if colors.count < 7 {
                                colors.append(colors.last ?? .white)
                            }
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .disabled(colors.count >= 7)
                    }
                }

                Section("Wheel") {
                    SliderRow(label: "Density",  value: $density,     range: 0.25...7,  step: 0.05)
                    SliderRow(label: "Length",   value: $panelLength, range: 0.05...3,  step: 0.05)
                    SliderRow(label: "Scale",    value: $scale,       range: 0.05...4,  step: 0.05)
                }

                Section("Skew") {
                    SliderRow(label: "Angle 1",  value: $angle1, range: -1...1, step: 0.01)
                    SliderRow(label: "Angle 2",  value: $angle2, range: -1...1, step: 0.01)
                }

                Section("Material") {
                    Toggle("Edge Highlight", isOn: $edges)
                    SliderRow(label: "Side Blur", value: $blur,     range: 0...0.5, step: 0.01)
                    SliderRow(label: "Fade In",   value: $fadeIn,   range: 0...1,   step: 0.01)
                    SliderRow(label: "Fade Out",  value: $fadeOut,  range: 0...1,   step: 0.01)
                    SliderRow(label: "Gradient",  value: $gradient, range: 0...1,   step: 0.01)
                }

                Section("Motion") {
                    SliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Color Panels")
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
        SWColorPanels(showsControls: true)
    }
}

#Preview("Pastel on white") {
    SWColorPanels(
        colors: [.pink, .yellow, .mint, .indigo],
        colorBack: .white
    )
    .ignoresSafeArea()
}
