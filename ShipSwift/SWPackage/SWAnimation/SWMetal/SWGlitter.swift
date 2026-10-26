//
//  SWGlitter.swift
//  ShipSwift
//
//  Adapted from ShaderKit by James Rochabrun
//  https://github.com/jamesrochabrun/ShaderKit
//  Licensed under the MIT License. Copyright (c) James Rochabrun.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Wraps any view in a field of animated glitter via a SwiftUI Metal
//  `layerEffect` — a hashed grid scatters twinkling rainbow-tinted points
//  whose phase responds to a `tilt` vector (e.g. from a `DragGesture`).
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — 50-cell glitter grid, internal twinkle only
//    SWGlitter {
//        Image("ronaldo").resizable().scaledToFill()
//    }
//
//    // Denser glitter, tilt-driven from a DragGesture
//    SWGlitter(tilt: dragTilt, density: 80) { cardArtwork }
//
//    // Demo / debug — gear button + live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWGlitter(showsControls: true) { cardArtwork }
//
//  Parameters:
//    - tilt: Light/parallax direction in roughly `-1...1` per axis,
//            usually drag-driven (default `.zero`).
//    - density: Number of glitter grid cells per axis (default `50`).
//    - speed: Multiplier on the internal animation time (default `1.0`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a live-tuning
//                     sheet (default `false`).
//

import SwiftUI

// MARK: - Main View

struct SWGlitter<Content: View>: View {
    /// Light/parallax direction in roughly -1...1 per axis (drag-driven).
    var tilt: CGSize = .zero

    /// Number of glitter grid cells per axis.
    var density: Float = 50

    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    private let content: Content

    init(
        tilt: CGSize = .zero,
        density: Float = 50,
        speed: Float = 1.0,
        showsControls: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.tilt = tilt
        self.density = density
        self.speed = speed
        self.showsControls = showsControls
        self.content = content()
    }

    var body: some View {
        if showsControls {
            SWGlitterControlled(initial: self, content: content)
        } else {
            SWGlitterRenderer(initial: self, content: content)
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWGlitterRenderer<Content: View>: View {
    let initial: SWGlitter<Content>
    let content: Content

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start)) * initial.speed
            content.layerEffect(
                ShaderLibrary.swGlitter(
                    .boundingRect,
                    .float2(Float(initial.tilt.width), Float(initial.tilt.height)),
                    .float(elapsed),
                    .float(initial.density)
                ),
                maxSampleOffset: .zero
            )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWGlitterControlled<Content: View>: View {
    @State private var tiltX: Float
    @State private var tiltY: Float
    @State private var density: Float
    @State private var speed: Float

    @State private var showSheet = false

    private let content: Content

    init(initial: SWGlitter<Content>, content: Content) {
        _tiltX   = State(initialValue: Float(initial.tilt.width))
        _tiltY   = State(initialValue: Float(initial.tilt.height))
        _density = State(initialValue: initial.density)
        _speed   = State(initialValue: initial.speed)
        self.content = content
    }

    var body: some View {
        SWGlitterRenderer(
            initial: SWGlitter(
                tilt: CGSize(width: CGFloat(tiltX), height: CGFloat(tiltY)),
                density: density,
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
                .accessibilityLabel("Glitter Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWGlitterControlsSheet(
                tiltX: $tiltX,
                tiltY: $tiltY,
                density: $density,
                speed: $speed
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWGlitterControlsSheet: View {
    @Binding var tiltX: Float
    @Binding var tiltY: Float
    @Binding var density: Float
    @Binding var speed: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Tilt") {
                    SWGlitterSliderRow(label: "Tilt X", value: $tiltX, range: -1...1, step: 0.01)
                    SWGlitterSliderRow(label: "Tilt Y", value: $tiltY, range: -1...1, step: 0.01)
                }
                Section("Glitter") {
                    SWGlitterSliderRow(label: "Density", value: $density, range: 10...120, step: 1)
                }
                Section("Motion") {
                    SWGlitterSliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Glitter")
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

private struct SWGlitterSliderRow: View {
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
        SWGlitter(showsControls: true) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.purple)
                .frame(width: 250, height: 350)
        }
    }
}
