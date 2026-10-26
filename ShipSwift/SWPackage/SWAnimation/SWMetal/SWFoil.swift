//
//  SWFoil.swift
//  ShipSwift
//
//  Adapted from ShaderKit by James Rochabrun
//  https://github.com/jamesrochabrun/ShaderKit
//  Licensed under the MIT License. Copyright (c) James Rochabrun.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Wraps any view in a holographic rainbow foil via a SwiftUI Metal
//  `layerEffect` — crossing sine waves drive a rainbow ramp, a sparkle
//  term adds glints, and a `tilt` vector lets the caller rotate the
//  highlight (e.g. from a `DragGesture`) for a "trading-card foil" feel.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — foil tracks the internal animation only
//    SWFoil {
//        Image("messi").resizable().scaledToFill()
//    }
//
//    // Tilt-driven — feed a normalized (-1...1) tilt from a DragGesture
//    SWFoil(tilt: dragTilt, intensity: 1.0) {
//        cardArtwork
//    }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWFoil(showsControls: true) { cardArtwork }
//
//  Parameters:
//    - tilt: Light/parallax direction in roughly `-1...1` per axis,
//            usually driven by a drag gesture (default `.zero`).
//    - intensity: Blend of the foil over the source in `0...1`
//                 (default `1.0`).
//    - speed: Multiplier on the internal animation time (default `1.0`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a live-tuning
//                     sheet (default `false`).
//

import SwiftUI

// MARK: - Main View

struct SWFoil<Content: View>: View {
    /// Light/parallax direction in roughly -1...1 per axis (drag-driven).
    var tilt: CGSize = .zero

    /// Blend of the foil over the source in 0...1.
    var intensity: Float = 1.0

    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    private let content: Content

    init(
        tilt: CGSize = .zero,
        intensity: Float = 1.0,
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
            SWFoilControlled(initial: self, content: content)
        } else {
            SWFoilRenderer(initial: self, content: content)
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWFoilRenderer<Content: View>: View {
    let initial: SWFoil<Content>
    let content: Content

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start)) * initial.speed
            content.layerEffect(
                ShaderLibrary.swFoil(
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

private struct SWFoilControlled<Content: View>: View {
    @State private var tiltX: Float
    @State private var tiltY: Float
    @State private var intensity: Float
    @State private var speed: Float

    @State private var showSheet = false

    private let content: Content

    init(initial: SWFoil<Content>, content: Content) {
        _tiltX     = State(initialValue: Float(initial.tilt.width))
        _tiltY     = State(initialValue: Float(initial.tilt.height))
        _intensity = State(initialValue: initial.intensity)
        _speed     = State(initialValue: initial.speed)
        self.content = content
    }

    var body: some View {
        SWFoilRenderer(
            initial: SWFoil(
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
                .accessibilityLabel("Foil Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWFoilControlsSheet(
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

private struct SWFoilControlsSheet: View {
    @Binding var tiltX: Float
    @Binding var tiltY: Float
    @Binding var intensity: Float
    @Binding var speed: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Tilt") {
                    SWFoilSliderRow(label: "Tilt X", value: $tiltX, range: -1...1, step: 0.01)
                    SWFoilSliderRow(label: "Tilt Y", value: $tiltY, range: -1...1, step: 0.01)
                }
                Section("Foil") {
                    SWFoilSliderRow(label: "Intensity", value: $intensity, range: 0...1, step: 0.01)
                }
                Section("Motion") {
                    SWFoilSliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Foil")
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

private struct SWFoilSliderRow: View {
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
        SWFoil(showsControls: true) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.indigo)
                .frame(width: 250, height: 350)
        }
    }
}
