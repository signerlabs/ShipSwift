//
//  SWPolishedAluminum.swift
//  ShipSwift
//
//  Adapted from ShaderKit by James Rochabrun
//  https://github.com/jamesrochabrun/ShaderKit
//  Licensed under the MIT License. Copyright (c) James Rochabrun.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Wraps any view in a polished-aluminum finish via a SwiftUI Metal
//  `layerEffect` — a tilt-shifted cyan/silver/purple brushed-metal
//  gradient, a diagonal rainbow iridescence band, and a tilt-tracking
//  specular hotspot. Feed `tilt` from a `DragGesture` to rotate the metal.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — polished metal, internal animation only
//    SWPolishedAluminum {
//        Image("messi").resizable().scaledToFill()
//    }
//
//    // Tilt-driven from a DragGesture
//    SWPolishedAluminum(tilt: dragTilt, intensity: 0.85) { cardArtwork }
//
//    // Demo / debug — gear button + live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWPolishedAluminum(showsControls: true) { cardArtwork }
//
//  Parameters:
//    - tilt: Light/parallax direction in roughly `-1...1` per axis,
//            usually drag-driven (default `.zero`).
//    - intensity: Blend of the metal finish over the source in `0...1`
//                 (default `0.85`).
//    - speed: Multiplier on the internal animation time (default `1.0`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a live-tuning
//                     sheet (default `false`).
//
//  Note: `time` is wired through for API symmetry with the foil family;
//  the metal finish is driven mainly by `tilt`, so it reads as a still,
//  reflective surface that comes alive on drag.
//

import SwiftUI

// MARK: - Main View

struct SWPolishedAluminum<Content: View>: View {
    /// Light/parallax direction in roughly -1...1 per axis (drag-driven).
    var tilt: CGSize = .zero

    /// Blend of the metal finish over the source in 0...1.
    var intensity: Float = 0.85

    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    private let content: Content

    init(
        tilt: CGSize = .zero,
        intensity: Float = 0.85,
        speed: Float = 1.0,
        showsControls: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.tilt = tilt
        self.intensity = intensity
        self.speed = speed
        self.showsControls = showsControls
        self.content = content()
    }

    var body: some View {
        if showsControls {
            SWPolishedAluminumControlled(initial: self, content: content)
        } else {
            SWPolishedAluminumRenderer(initial: self, content: content)
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWPolishedAluminumRenderer<Content: View>: View {
    let initial: SWPolishedAluminum<Content>
    let content: Content

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start)) * initial.speed
            content.layerEffect(
                ShaderLibrary.swPolishedAluminum(
                    .boundingRect,
                    .float2(Float(initial.tilt.width), Float(initial.tilt.height)),
                    .float(elapsed),
                    .float(initial.intensity)
                ),
                maxSampleOffset: .zero
            )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWPolishedAluminumControlled<Content: View>: View {
    @State private var tiltX: Float
    @State private var tiltY: Float
    @State private var intensity: Float
    @State private var speed: Float

    @State private var showSheet = false

    private let content: Content

    init(initial: SWPolishedAluminum<Content>, content: Content) {
        _tiltX     = State(initialValue: Float(initial.tilt.width))
        _tiltY     = State(initialValue: Float(initial.tilt.height))
        _intensity = State(initialValue: initial.intensity)
        _speed     = State(initialValue: initial.speed)
        self.content = content
    }

    var body: some View {
        SWPolishedAluminumRenderer(
            initial: SWPolishedAluminum(
                tilt: CGSize(width: CGFloat(tiltX), height: CGFloat(tiltY)),
                intensity: intensity,
                speed: speed
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
                .accessibilityLabel("Polished Aluminum Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWPolishedAluminumControlsSheet(
                tiltX: $tiltX,
                tiltY: $tiltY,
                intensity: $intensity,
                speed: $speed
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWPolishedAluminumControlsSheet: View {
    @Binding var tiltX: Float
    @Binding var tiltY: Float
    @Binding var intensity: Float
    @Binding var speed: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Tilt") {
                    SWPolishedAluminumSliderRow(label: "Tilt X", value: $tiltX, range: -1...1, step: 0.01)
                    SWPolishedAluminumSliderRow(label: "Tilt Y", value: $tiltY, range: -1...1, step: 0.01)
                }
                Section("Metal") {
                    SWPolishedAluminumSliderRow(label: "Intensity", value: $intensity, range: 0...1, step: 0.01)
                }
                Section("Motion") {
                    SWPolishedAluminumSliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Polished Aluminum")
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

private struct SWPolishedAluminumSliderRow: View {
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
        SWPolishedAluminum(showsControls: true) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.gray)
                .frame(width: 250, height: 350)
        }
    }
}
