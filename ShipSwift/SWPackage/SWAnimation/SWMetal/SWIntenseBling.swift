//
//  SWIntenseBling.swift
//  ShipSwift
//
//  Adapted from ShaderKit by James Rochabrun
//  https://github.com/jamesrochabrun/ShaderKit
//  Licensed under the MIT License. Copyright (c) James Rochabrun.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Wraps any view in a maximum-intensity holographic shimmer via a
//  SwiftUI Metal `layerEffect` — a dense diamond grid, multi-hue rainbow,
//  three moving hotspots and layered sparkles, all driven by a `tilt`
//  vector (e.g. from a `DragGesture`) for a "secret-rare card" look.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — internal animation only
//    SWIntenseBling {
//        Image("messi").resizable().scaledToFill()
//    }
//
//    // Tilt-driven from a DragGesture
//    SWIntenseBling(tilt: dragTilt) { cardArtwork }
//
//    // Demo / debug — gear button + live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWIntenseBling(showsControls: true) { cardArtwork }
//
//  Parameters:
//    - tilt: Light/parallax direction in roughly `-1...1` per axis,
//            usually drag-driven (default `.zero`).
//    - intensity: Strength of every holographic overlay in `0...1`
//                 (default `0.5`). At 0 the source artwork shows through
//                 almost untouched; at 1 it is the full secret-rare blast.
//    - speed: Multiplier on the internal animation time (default `1.0`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a live-tuning
//                     sheet (default `false`).
//
//  Note: This is the most intense of the foil family. `intensity` controls
//  how much it covers the source artwork — keep it low to leave the photo
//  the clear subject and let the shader read as a surface finish only.
//

import SwiftUI

// MARK: - Main View

struct SWIntenseBling<Content: View>: View {
    /// Light/parallax direction in roughly -1...1 per axis (drag-driven).
    var tilt: CGSize = .zero

    /// Strength of every holographic overlay in 0...1. At 0 the source
    /// artwork shows through almost untouched; at 1 it is the full blast.
    var intensity: Float = 0.5

    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    private let content: Content

    init(
        tilt: CGSize = .zero,
        intensity: Float = 0.5,
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
            SWIntenseBlingControlled(initial: self, content: content)
        } else {
            SWIntenseBlingRenderer(initial: self, content: content)
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWIntenseBlingRenderer<Content: View>: View {
    let initial: SWIntenseBling<Content>
    let content: Content

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start)) * initial.speed
            content.layerEffect(
                ShaderLibrary.swIntenseBling(
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

private struct SWIntenseBlingControlled<Content: View>: View {
    @State private var tiltX: Float
    @State private var tiltY: Float
    @State private var intensity: Float
    @State private var speed: Float

    @State private var showSheet = false

    private let content: Content

    init(initial: SWIntenseBling<Content>, content: Content) {
        _tiltX = State(initialValue: Float(initial.tilt.width))
        _tiltY = State(initialValue: Float(initial.tilt.height))
        _intensity = State(initialValue: initial.intensity)
        _speed = State(initialValue: initial.speed)
        self.content = content
    }

    var body: some View {
        SWIntenseBlingRenderer(
            initial: SWIntenseBling(
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
                .accessibilityLabel("Intense Bling Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWIntenseBlingControlsSheet(
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

private struct SWIntenseBlingControlsSheet: View {
    @Binding var tiltX: Float
    @Binding var tiltY: Float
    @Binding var intensity: Float
    @Binding var speed: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Tilt") {
                    SWIntenseBlingSliderRow(label: "Tilt X", value: $tiltX, range: -1...1, step: 0.01)
                    SWIntenseBlingSliderRow(label: "Tilt Y", value: $tiltY, range: -1...1, step: 0.01)
                }
                Section("Bling") {
                    SWIntenseBlingSliderRow(label: "Intensity", value: $intensity, range: 0...1, step: 0.01)
                }
                Section("Motion") {
                    SWIntenseBlingSliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Intense Bling")
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

private struct SWIntenseBlingSliderRow: View {
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
        SWIntenseBling(showsControls: true) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.black)
                .frame(width: 250, height: 350)
        }
    }
}
