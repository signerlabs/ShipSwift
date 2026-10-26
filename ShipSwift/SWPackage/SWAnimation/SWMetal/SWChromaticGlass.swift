//
//  SWChromaticGlass.swift
//  ShipSwift
//
//  Adapted from ShaderKit by James Rochabrun
//  https://github.com/jamesrochabrun/ShaderKit
//  Licensed under the MIT License. Copyright (c) James Rochabrun.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Wraps any view in a subtle chromatic-aberration "glass" pass via a
//  SwiftUI Metal `layerEffect` — red/blue channels split toward the edges
//  along the `tilt` direction (e.g. from a `DragGesture`), with a soft
//  centre glow, for a premium glass-over-card feel.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — gentle RGB split, internal only
//    SWChromaticGlass {
//        Image("ronaldo").resizable().scaledToFill()
//    }
//
//    // Tilt-driven, stronger separation
//    SWChromaticGlass(tilt: dragTilt, separation: 0.6) { cardArtwork }
//
//    // Demo / debug — gear button + live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWChromaticGlass(showsControls: true) { cardArtwork }
//
//  Parameters:
//    - tilt: Light/parallax direction in roughly `-1...1` per axis,
//            usually drag-driven (default `.zero`).
//    - intensity: Blend of the split over the source in `0...1`
//                 (default `0.6`).
//    - separation: How far the R/B channels separate in `0...1`
//                  (default `0.4`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a live-tuning
//                     sheet (default `false`).
//

import SwiftUI

// MARK: - Main View

struct SWChromaticGlass<Content: View>: View {
    /// Light/parallax direction in roughly -1...1 per axis (drag-driven).
    var tilt: CGSize = .zero

    /// Blend of the split over the source in 0...1.
    var intensity: Float = 0.6

    /// How far the R/B channels separate in 0...1.
    var separation: Float = 0.4

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    private let content: Content

    init(
        tilt: CGSize = .zero,
        intensity: Float = 0.6,
        separation: Float = 0.4,
        showsControls: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.tilt = tilt
        self.intensity = intensity
        self.separation = separation
        self.showsControls = showsControls
        self.content = content()
    }

    var body: some View {
        if showsControls {
            SWChromaticGlassControlled(initial: self, content: content)
        } else {
            SWChromaticGlassRenderer(initial: self, content: content)
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWChromaticGlassRenderer<Content: View>: View {
    let initial: SWChromaticGlass<Content>
    let content: Content

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            // RGB split offsets the sample point — give the layerEffect a
            // small offset budget so edge pixels can pull in neighbours.
            content.layerEffect(
                ShaderLibrary.swChromaticGlass(
                    .boundingRect,
                    .float2(Float(initial.tilt.width), Float(initial.tilt.height)),
                    .float(elapsed),
                    .float(initial.intensity),
                    .float(initial.separation)
                ),
                maxSampleOffset: CGSize(width: 28, height: 28)
            )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWChromaticGlassControlled<Content: View>: View {
    @State private var tiltX: Float
    @State private var tiltY: Float
    @State private var intensity: Float
    @State private var separation: Float

    @State private var showSheet = false

    private let content: Content

    init(initial: SWChromaticGlass<Content>, content: Content) {
        _tiltX      = State(initialValue: Float(initial.tilt.width))
        _tiltY      = State(initialValue: Float(initial.tilt.height))
        _intensity  = State(initialValue: initial.intensity)
        _separation = State(initialValue: initial.separation)
        self.content = content
    }

    var body: some View {
        SWChromaticGlassRenderer(
            initial: SWChromaticGlass(
                tilt: CGSize(width: CGFloat(tiltX), height: CGFloat(tiltY)),
                intensity: intensity,
                separation: separation
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
                .accessibilityLabel("Chromatic Glass Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWChromaticGlassControlsSheet(
                tiltX: $tiltX,
                tiltY: $tiltY,
                intensity: $intensity,
                separation: $separation
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWChromaticGlassControlsSheet: View {
    @Binding var tiltX: Float
    @Binding var tiltY: Float
    @Binding var intensity: Float
    @Binding var separation: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Tilt") {
                    SWChromaticGlassSliderRow(label: "Tilt X", value: $tiltX, range: -1...1, step: 0.01)
                    SWChromaticGlassSliderRow(label: "Tilt Y", value: $tiltY, range: -1...1, step: 0.01)
                }
                Section("Glass") {
                    SWChromaticGlassSliderRow(label: "Intensity",  value: $intensity,  range: 0...1, step: 0.01)
                    SWChromaticGlassSliderRow(label: "Separation", value: $separation, range: 0...1, step: 0.01)
                }
            }
            .navigationTitle("Chromatic Glass")
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

private struct SWChromaticGlassSliderRow: View {
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
        SWChromaticGlass(showsControls: true) {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.cyan, .blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 250, height: 350)
        }
    }
}
