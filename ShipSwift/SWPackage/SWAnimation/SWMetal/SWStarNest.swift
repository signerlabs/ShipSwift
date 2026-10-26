//
//  SWStarNest.swift
//  ShipSwift
//
//  Adapted from "Star Nest" by Pablo Roman Andrioli (Kali)
//  https://www.shadertoy.com/view/XlfGRj
//  Licensed under the MIT License. Copyright (c) Pablo Roman Andrioli.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Full-screen volumetric star-nebula background rendered via a SwiftUI
//  Metal stitchable shader. A fixed camera flies through a 3D space-folded
//  fractal field — a deep-space nebula of drifting stars and dark voids,
//  generated entirely in the shader with no texture or view sampling.
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — the classic Star Nest look, full-screen
//    ZStack {
//        SWStarNest()
//            .ignoresSafeArea()
//        // Your content here
//    }
//
//    // Slower drift, warmer/denser nebula
//    SWStarNest(speed: 0.006, brightness: 0.0022)
//
//    // As a section background
//    myContent
//        .background { SWStarNest() }
//
//    // Demo / debug — adds a gear button in the navigation bar that opens
//    // a sheet to tweak every parameter live. Disabled by default.
//    SWStarNest(showsControls: true)
//
//  Parameters (each maps to a Star Nest `#define`; defaults are the
//  original values unless noted):
//    - zoom: Field of view / ray spread (default `0.8`). Lower = tighter
//            tunnel, higher = wider sky.
//    - speed: Camera fly-through speed (default `0.01`).
//    - brightness: Radiance multiplier per volume slice (default `0.0015`).
//    - saturation: Color richness (default `0.85`). 1 = full color,
//                  0 = greyscale.
//    - darkmatter: Strength of the void-carving dark matter (default `0.3`).
//    - distfading: How fast distant slices fade out (default `0.73`).
//    - angleX: Camera yaw (default `0.5`). Replaces the original mouse-X
//              control; the default is Star Nest's neutral framing.
//    - angleY: Camera pitch (default `0.8`). Replaces the original mouse-Y
//              control; the default is Star Nest's neutral framing.
//    - volsteps: Volume march slices (default `16`, original is `20`).
//                Lowered from the original for a lighter full-screen mobile
//                cost; raise toward 20 for maximum depth on capable devices.
//    - iterations: Fractal fold iterations per slice (default `17`, the
//                  original value).
//    - showsControls: When `true`, adds a gear `ToolbarItem` to the
//                     enclosing `NavigationStack` that opens a live-tuning
//                     sheet. Default `false`.
//
//  Performance:
//    - Cost is `volsteps × iterations` fractal folds per pixel — at the
//      default 16 × 17 that is 272 folds for every pixel, every frame. This
//      is the heaviest background in the library. Use ONE full-screen
//      instance; never stack several or tile it into a grid. On older
//      devices drop `volsteps` to 12–14 if the frame rate suffers.
//    - `volsteps` and `iterations` are hard-clamped to 24 in the shader so a
//      runaway value can never lock the GPU.
//
//  Created by Wei Zhong on 5/30/26.
//

import SwiftUI

// MARK: - Main View

struct SWStarNest: View {
    /// Field of view / ray spread. Star Nest `#define zoom`.
    var zoom: Float = 0.8

    /// Camera fly-through speed. Star Nest `#define speed`.
    var speed: Float = 0.01

    /// Radiance multiplier per volume slice. Star Nest `#define brightness`.
    var brightness: Float = 0.0015

    /// Color richness (1 = full color, 0 = greyscale). Star Nest `#define saturation`.
    var saturation: Float = 0.85

    /// Strength of the void-carving dark matter. Star Nest `#define darkmatter`.
    var darkmatter: Float = 0.3

    /// How fast distant slices fade out. Star Nest `#define distfading`.
    var distfading: Float = 0.73

    /// Camera yaw — replaces the original mouse-X control.
    var angleX: Float = 0.5

    /// Camera pitch — replaces the original mouse-Y control.
    var angleY: Float = 0.8

    /// Volume march slices (original `20`; default lowered to `16` for mobile).
    var volsteps: Float = 16

    /// Fractal fold iterations per slice. Star Nest `#define iterations`.
    var iterations: Float = 17

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWStarNestControlled(initial: self)
        } else {
            SWStarNestRenderer(
                zoom: zoom,
                speed: speed,
                brightness: brightness,
                saturation: saturation,
                darkmatter: darkmatter,
                distfading: distfading,
                angleX: angleX,
                angleY: angleY,
                volsteps: volsteps,
                iterations: iterations
            )
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWStarNestRenderer: View {
    let zoom: Float
    let speed: Float
    let brightness: Float
    let saturation: Float
    let darkmatter: Float
    let distfading: Float
    let angleX: Float
    let angleY: Float
    let volsteps: Float
    let iterations: Float

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            // Black is the natural first-frame base for a deep-space nebula —
            // the shader fills it before the first frame is visible.
            Color.black
                .colorEffect(
                    // Argument order MUST match the Metal `swStarNest` signature
                    // exactly: boundingRect, time, speed, zoom, brightness,
                    // saturation, darkmatter, distfading, angleX, angleY,
                    // volsteps, iterations. (`.boundingRect` and `.float(time)`
                    // are bound positionally — they are not in the Swift View's
                    // stored properties.)
                    ShaderLibrary.swStarNest(
                        .boundingRect,
                        .float(elapsed),
                        .float(speed),
                        .float(zoom),
                        .float(brightness),
                        .float(saturation),
                        .float(darkmatter),
                        .float(distfading),
                        .float(angleX),
                        .float(angleY),
                        .float(volsteps),
                        .float(iterations)
                    )
                )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWStarNestControlled: View {
    @State private var zoom: Float
    @State private var speed: Float
    @State private var brightness: Float
    @State private var saturation: Float
    @State private var darkmatter: Float
    @State private var distfading: Float
    @State private var angleX: Float
    @State private var angleY: Float
    @State private var volsteps: Float
    @State private var iterations: Float

    @State private var showSheet = false

    init(initial: SWStarNest) {
        _zoom       = State(initialValue: initial.zoom)
        _speed      = State(initialValue: initial.speed)
        _brightness = State(initialValue: initial.brightness)
        _saturation = State(initialValue: initial.saturation)
        _darkmatter = State(initialValue: initial.darkmatter)
        _distfading = State(initialValue: initial.distfading)
        _angleX     = State(initialValue: initial.angleX)
        _angleY     = State(initialValue: initial.angleY)
        _volsteps   = State(initialValue: initial.volsteps)
        _iterations = State(initialValue: initial.iterations)
    }

    var body: some View {
        SWStarNestRenderer(
            zoom: zoom,
            speed: speed,
            brightness: brightness,
            saturation: saturation,
            darkmatter: darkmatter,
            distfading: distfading,
            angleX: angleX,
            angleY: angleY,
            volsteps: volsteps,
            iterations: iterations
        )
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Star Nest Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWStarNestControlsSheet(
                zoom: $zoom,
                speed: $speed,
                brightness: $brightness,
                saturation: $saturation,
                darkmatter: $darkmatter,
                distfading: $distfading,
                angleX: $angleX,
                angleY: $angleY,
                volsteps: $volsteps,
                iterations: $iterations
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWStarNestControlsSheet: View {
    @Binding var zoom: Float
    @Binding var speed: Float
    @Binding var brightness: Float
    @Binding var saturation: Float
    @Binding var darkmatter: Float
    @Binding var distfading: Float
    @Binding var angleX: Float
    @Binding var angleY: Float
    @Binding var volsteps: Float
    @Binding var iterations: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Camera") {
                    SliderRow(label: "Zoom",   value: $zoom,   range: 0.2...2,    step: 0.01)
                    SliderRow(label: "Angle X", value: $angleX, range: 0...6.283,  step: 0.01)
                    SliderRow(label: "Angle Y", value: $angleY, range: 0...6.283,  step: 0.01)
                    SliderRow(label: "Speed",  value: $speed,  range: 0...0.05,   step: 0.001)
                }

                Section("Nebula") {
                    SliderRow(label: "Brightness", value: $brightness, range: 0.0002...0.006, step: 0.0001)
                    SliderRow(label: "Saturation", value: $saturation, range: 0...1,          step: 0.01)
                    SliderRow(label: "Dark Matter", value: $darkmatter, range: 0...1,          step: 0.01)
                    SliderRow(label: "Dist Fading", value: $distfading, range: 0.3...0.95,     step: 0.01)
                }

                // Higher = more depth & detail, but quadratically more cost
                // (volsteps × iterations folds per pixel). Lower these first if
                // the frame rate drops on older devices.
                Section("Quality / Performance") {
                    SliderRow(label: "Vol Steps",  value: $volsteps,   range: 4...24, step: 1)
                    SliderRow(label: "Iterations", value: $iterations, range: 4...24, step: 1)
                }
            }
            .navigationTitle("Star Nest")
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
                Text(String(format: "%.4f", value))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

// MARK: - Preview

#Preview {
    // ToolbarItem requires an enclosing NavigationStack to render.
    NavigationStack {
        SWStarNest(showsControls: true)
    }
}
