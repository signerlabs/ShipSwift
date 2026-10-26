//
//  SWCharSphere.swift
//  ShipSwift
//
//  Rotating 3D sphere where each point is a glyph drawn at its
//  perspective-projected position. A user-supplied character palette
//  (`chars: [String]`) is randomly assigned across sphere points — the
//  assignment is baked at cloud-init so it doesn't flicker between
//  frames. Optional back-face culling, perspective-scaled font, and a
//  color wave that washes the palette up the sphere.
//
//  Rendered with a single SwiftUI `Canvas` per frame so 100–300
//  glyphs stay at 60fps on iPhone.
//
//  Algorithms used (both well-known graphics primitives):
//    - Spherical Fibonacci point set:
//        y = 1 − 2i / (N − 1)
//        θ = i · π(3 − √5)
//        (x, z) = √(1 − y²) · (cos θ, sin θ)
//    - One-axis perspective projection:
//        screen = world · (focal / (focal + z))
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `TimelineView`, `Canvas`).
//
//  Usage:
//    // Default — 240 "道" glyphs, white/cyan/pink wave on black
//    SWCharSphere()
//        .ignoresSafeArea()
//
//    // Random-mix a palette of glyphs
//    SWCharSphere(chars: ["道", "德", "经"])
//
//    // Latin glyphs work too
//    SWCharSphere(
//        chars: ["S", "h", "i", "p", "S", "w", "i", "f", "t"],
//        colors: [.orange, .yellow, .white]
//    )
//
//    // As a section background
//    myContent.background { SWCharSphere() }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    SWCharSphere(showsControls: true)
//
//  Parameters:
//    - chars:          Glyph palette. Each sphere point is assigned a
//                      random index into this array once at cloud-init
//                      time, so the assignment is stable across frames
//                      (default `["道"]`).
//    - glyphCount:     Number of points on the sphere, 50...1000
//                      (default 240; > 400 starts to overlap visibly).
//    - colors:         Palette cycled through over time (default
//                      white / cyan / pink).
//    - background:     Background fill (default `.black`).
//    - morphAmount:    0 = random 3D cloud, 1 = perfect sphere
//                      (default 1.0).
//    - rotationSpeed:  Radians per second around the Y axis
//                      (default 0.5).
//    - fadeSeconds:    Seconds per color cross-fade (default 5.5).
//    - waitSeconds:    Pause between fades (default 5.0).
//    - fontSize:       Base font point size; perspective scales it
//                      (default 10, range 4...30).
//    - fontWeight:     Glyph weight (default `.semibold`).
//    - hidesBackFaces: Skip points on the far side of the sphere so
//                      back-side glyphs don't muddle the front
//                      (default `true`).
//    - showsControls:  Attach a gear `ToolbarItem` + bottom morph
//                      slider for live tuning (default `false`).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Main View

struct SWCharSphere: View {
    /// Glyph palette. Each sphere point is assigned a random index into
    /// this array once (deterministic per cloud) so the assignment
    /// doesn't flicker between frames.
    ///
    /// Default is Tao Te Ching Chapter 1 (public-domain ancient Chinese
    /// text, ~33 unique glyphs across 59 positions — rich scatter on
    /// the sphere).
    var chars: [String] = [
        "道", "可", "道", "非", "常", "道",
        "名", "可", "名", "非", "常", "名",
        "無", "名", "天", "地", "之", "始",
        "有", "名", "萬", "物", "之", "母",
        "故", "常", "無", "欲", "以", "觀", "其", "妙",
        "常", "有", "欲", "以", "觀", "其", "徼",
        "此", "兩", "者", "同", "出", "而", "異", "名",
        "同", "謂", "之", "玄", "玄", "之", "又", "玄",
        "眾", "妙", "之", "門"
    ]
//    var chars: [String] = [
//        // Asia
//        "🇨🇳", "🇯🇵", "🇰🇷", "🇮🇳", "🇸🇬", "🇹🇭", "🇻🇳", "🇮🇩",
//        "🇲🇾", "🇵🇭", "🇦🇪", "🇸🇦", "🇮🇱", "🇹🇷", "🇵🇰", "🇧🇩",
//        // Europe
//        "🇬🇧", "🇫🇷", "🇩🇪", "🇮🇹", "🇪🇸", "🇵🇹", "🇳🇱", "🇧🇪",
//        "🇨🇭", "🇸🇪", "🇳🇴", "🇫🇮", "🇩🇰", "🇵🇱", "🇦🇹", "🇬🇷",
//        "🇮🇪", "🇨🇿", "🇭🇺", "🇷🇴",
//        // Americas
//        "🇺🇸", "🇨🇦", "🇲🇽", "🇧🇷", "🇦🇷", "🇨🇱", "🇨🇴", "🇵🇪",
//        // Africa
//        "🇿🇦", "🇪🇬", "🇳🇬", "🇰🇪", "🇲🇦", "🇪🇹", "🇬🇭",
//        // Oceania
//        "🇦🇺", "🇳🇿",
//        // Eurasia
//        "🇷🇺", "🇺🇦", "🇰🇿"
//    ]
    var glyphCount: Int = 240
    var colors: [Color] = [.white, .cyan, .pink]
    var background: Color = .black
    var morphAmount: Double = 1.0
    var rotationSpeed: Double = 0.5
    var fadeSeconds: Double = 5.5
    var waitSeconds: Double = 5.0
    var fontSize: Double = 7
    var fontWeight: Font.Weight = .semibold
    var hidesBackFaces: Bool = false
    var showsControls: Bool = false

    var body: some View {
        if showsControls {
            SWCharSphereControlled(initial: self)
        } else {
            SWCharSphereRenderer(
                chars: chars,
                glyphCount: glyphCount,
                colors: colors,
                background: background,
                morphAmount: morphAmount,
                rotationSpeed: rotationSpeed,
                fadeSeconds: fadeSeconds,
                waitSeconds: waitSeconds,
                fontSize: fontSize,
                fontWeight: fontWeight,
                hidesBackFaces: hidesBackFaces
            )
        }
    }
}

// MARK: - Renderer

/// Pre-computed random offsets per glyph; resampled when `glyphCount`
/// changes. Kept separate from the renderer so the loop's hot path
/// never allocates.
private struct SWCharSphereCloud {
    let randomXYZ: [SIMD3<Double>]
    let yNormalized: [Double]
    /// One char-palette index per glyph slot, baked at cloud-init so the
    /// per-glyph character assignment is stable across frames.
    let charIndices: [Int]

    init(glyphCount: Int, charCount: Int) {
        var random: [SIMD3<Double>] = []
        random.reserveCapacity(glyphCount)
        var sortable: [(Int, Double)] = []
        sortable.reserveCapacity(glyphCount)
        var charIdx: [Int] = []
        charIdx.reserveCapacity(glyphCount)
        let safeCharCount = max(1, charCount)
        for i in 0..<glyphCount {
            // Uniform random point inside the unit ball.
            let u = Double.random(in: 0...1)
            let v = Double.random(in: 0...1)
            let theta = u * 2 * .pi
            let phi = acos(2 * v - 1)
            let r = pow(Double.random(in: 0...1), 1.0 / 3.0)
            let x = r * sin(phi) * cos(theta)
            let y = r * sin(phi) * sin(theta)
            let z = r * cos(phi)
            random.append(SIMD3(x, y, z))

            let sphereY = (glyphCount > 1)
                ? 1 - (Double(i) / Double(glyphCount - 1)) * 2
                : 0
            sortable.append((i, sphereY))

            charIdx.append(Int.random(in: 0..<safeCharCount))
        }
        self.randomXYZ = random
        self.charIndices = charIdx

        let minY = sortable.map { $0.1 }.min() ?? -1
        let maxY = sortable.map { $0.1 }.max() ??  1
        let span = max(1e-6, maxY - minY)
        var norm = Array(repeating: 0.0, count: glyphCount)
        for (i, y) in sortable {
            norm[i] = (y - minY) / span
        }
        self.yNormalized = norm
    }
}

private struct SWCharSphereRenderer: View {
    let chars: [String]
    let glyphCount: Int
    let colors: [Color]
    let background: Color
    let morphAmount: Double
    let rotationSpeed: Double
    let fadeSeconds: Double
    let waitSeconds: Double
    let fontSize: Double
    let fontWeight: Font.Weight
    let hidesBackFaces: Bool

    @State private var cloud: SWCharSphereCloud = .init(glyphCount: 240, charCount: 59)
    @State private var start: Date = .now
    @State private var lastCount: Int = 240
    @State private var lastCharCount: Int = 59

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = ctx.date.timeIntervalSince(start)
            let rotation = elapsed * rotationSpeed
            let totalCycle = max(0.001, fadeSeconds + waitSeconds)
            let timeInCycle = elapsed.truncatingRemainder(dividingBy: totalCycle)
            let baseIdx = Int(floor(elapsed / totalCycle)) % max(1, colors.count)
            let nextIdx = (baseIdx + 1) % max(1, colors.count)
            let baseRGB = rgbComponents(colors[baseIdx])
            let nextRGB = rgbComponents(colors[nextIdx])
            let cosR = cos(rotation)
            let sinR = sin(rotation)
            let count = cloud.randomXYZ.count
            let tMorph = max(0.0, min(1.0, morphAmount))
            let chaosScale = 250.0 * (1 - tMorph) + 100.0 * tMorph
            let goldenAngle = .pi * (3 - sqrt(5.0))

            // Fall back to a single dot if the palette is empty.
            let safeChars: [String] = chars.isEmpty ? ["·"] : chars

            Canvas { gc, size in
                let centerX = size.width / 2
                let centerY = size.height / 2

                for i in 0..<count {
                    // Sphere position via Vogel spiral.
                    let sphereY: Double = (count > 1)
                        ? 1 - (Double(i) / Double(count - 1)) * 2
                        : 0
                    let radiusAtY = sqrt(max(0, 1 - sphereY * sphereY))
                    let theta = goldenAngle * Double(i)
                    let sphereX = radiusAtY * cos(theta)
                    let sphereZ = radiusAtY * sin(theta)

                    // Morph: lerp between random cloud and sphere.
                    let rnd = cloud.randomXYZ[i]
                    let wx = (rnd.x * (1 - tMorph) + sphereX * tMorph) * chaosScale
                    let wy = (rnd.y * (1 - tMorph) + sphereY * tMorph) * chaosScale
                    let wz = (rnd.z * (1 - tMorph) + sphereZ * tMorph) * chaosScale

                    // Rotate around Y, then 1-axis perspective.
                    let rx = wx * cosR - wz * sinR
                    let rz = wx * sinR + wz * cosR

                    // Back-face culling: positive rz is the far side.
                    if hidesBackFaces && rz > 0 { continue }

                    let focal = 300.0
                    let p = focal / (focal + rz)
                    let sx = rx * p
                    let sy = wy * p
                    let glyphSize = max(4.0, fontSize * p)

                    // Color wave delay: bottom-to-top wash.
                    let delay = cloud.yNormalized[i] * fadeSeconds
                    let progress = max(0.0, min(1.0, (timeInCycle - delay) / fadeSeconds))
                    let r = baseRGB.r * (1 - progress) + nextRGB.r * progress
                    let g = baseRGB.g * (1 - progress) + nextRGB.g * progress
                    let b = baseRGB.b * (1 - progress) + nextRGB.b * progress

                    let glyph = safeChars[cloud.charIndices[i] % safeChars.count]
                    gc.draw(
                        Text(glyph)
                            .font(.system(size: glyphSize, weight: fontWeight, design: .rounded))
                            .foregroundStyle(Color(red: r, green: g, blue: b, opacity: 0.9)),
                        at: CGPoint(x: centerX + sx, y: centerY + sy)
                    )
                }
            }
        }
        .background(background)
        .onAppear { ensureCloud() }
        .onChange(of: glyphCount) { _, _ in ensureCloud() }
        .onChange(of: chars.count) { _, _ in ensureCloud() }
    }

    private func ensureCloud() {
        let target = max(50, min(1000, glyphCount))
        let charCount = max(1, chars.count)
        if target != lastCount
            || charCount != lastCharCount
            || cloud.randomXYZ.count != target {
            cloud = SWCharSphereCloud(glyphCount: target, charCount: charCount)
            lastCount = target
            lastCharCount = charCount
        }
    }

    private func rgbComponents(_ color: Color) -> (r: Double, g: Double, b: Double) {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #else
        let resolved = color.resolve(in: EnvironmentValues())
        return (Double(resolved.red), Double(resolved.green), Double(resolved.blue))
        #endif
    }
}

// MARK: - Controlled Wrapper

private struct SWCharSphereControlled: View {
    @State private var chars: [String]
    @State private var glyphCount: Int
    @State private var colors: [Color]
    @State private var background: Color
    @State private var morphAmount: Double
    @State private var rotationSpeed: Double
    @State private var fadeSeconds: Double
    @State private var waitSeconds: Double
    @State private var fontSize: Double
    @State private var fontWeight: Font.Weight
    @State private var hidesBackFaces: Bool

    @State private var showSheet = false

    init(initial: SWCharSphere) {
        _chars          = State(initialValue: initial.chars)
        _glyphCount     = State(initialValue: initial.glyphCount)
        _colors         = State(initialValue: initial.colors)
        _background     = State(initialValue: initial.background)
        _morphAmount    = State(initialValue: initial.morphAmount)
        _rotationSpeed  = State(initialValue: initial.rotationSpeed)
        _fadeSeconds    = State(initialValue: initial.fadeSeconds)
        _waitSeconds    = State(initialValue: initial.waitSeconds)
        _fontSize       = State(initialValue: initial.fontSize)
        _fontWeight     = State(initialValue: initial.fontWeight)
        _hidesBackFaces = State(initialValue: initial.hidesBackFaces)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SWCharSphereRenderer(
                chars: chars,
                glyphCount: glyphCount,
                colors: colors,
                background: background,
                morphAmount: morphAmount,
                rotationSpeed: rotationSpeed,
                fadeSeconds: fadeSeconds,
                waitSeconds: waitSeconds,
                fontSize: fontSize,
                fontWeight: fontWeight,
                hidesBackFaces: hidesBackFaces
            )
            .ignoresSafeArea()

            Slider(value: $morphAmount, in: 0...1)
                .padding(60)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showSheet = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Char Sphere Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWCharSphereControlsSheet(
                chars: $chars,
                glyphCount: $glyphCount,
                colors: $colors,
                background: $background,
                morphAmount: $morphAmount,
                rotationSpeed: $rotationSpeed,
                fadeSeconds: $fadeSeconds,
                waitSeconds: $waitSeconds,
                fontSize: $fontSize,
                fontWeight: $fontWeight,
                hidesBackFaces: $hidesBackFaces
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWCharSphereControlsSheet: View {
    @Binding var chars: [String]
    @Binding var glyphCount: Int
    @Binding var colors: [Color]
    @Binding var background: Color
    @Binding var morphAmount: Double
    @Binding var rotationSpeed: Double
    @Binding var fadeSeconds: Double
    @Binding var waitSeconds: Double
    @Binding var fontSize: Double
    @Binding var fontWeight: Font.Weight
    @Binding var hidesBackFaces: Bool

    @Environment(\.dismiss) private var dismiss

    /// Treat each character of the input as one palette entry — typing
    /// "道德经" produces `["道", "德", "经"]`, three glyphs randomly
    /// scattered across the sphere.
    private var charsTextBinding: Binding<String> {
        Binding(
            get: { chars.joined() },
            set: { chars = $0.map { String($0) } }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Glyph Palette (each char placed randomly)") {
                    #if os(iOS)
                    TextField("Type characters — e.g. 道德经",
                              text: charsTextBinding)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    #else
                    TextField("Type characters — e.g. 道德经",
                              text: charsTextBinding)
                        .autocorrectionDisabled()
                    #endif

                    Picker("Weight", selection: $fontWeight) {
                        Text("Regular").tag(Font.Weight.regular)
                        Text("Medium").tag(Font.Weight.medium)
                        Text("Semibold").tag(Font.Weight.semibold)
                        Text("Bold").tag(Font.Weight.bold)
                        Text("Heavy").tag(Font.Weight.heavy)
                    }
                    .pickerStyle(.menu)

                    Toggle("Hide back faces", isOn: $hidesBackFaces)
                }

                Section {
                    ForEach(colors.indices, id: \.self) { i in
                        ColorPicker("Color \(i + 1)",
                                    selection: $colors[i],
                                    supportsOpacity: false)
                    }
                    ColorPicker("Background",
                                selection: $background,
                                supportsOpacity: false)
                } header: {
                    HStack {
                        Text("Palette (\(colors.count))")
                        Spacer()
                        Button {
                            if colors.count > 1 { colors.removeLast() }
                        } label: { Image(systemName: "minus.circle") }
                            .disabled(colors.count <= 1)
                        Button {
                            colors.append(colors.last ?? .white)
                        } label: { Image(systemName: "plus.circle") }
                    }
                }

                Section("Geometry") {
                    StepperRow(label: "Glyph Count", value: $glyphCount, range: 50...1000, step: 20)
                    DoubleSliderRow(label: "Morph",     value: $morphAmount,    range: 0...1,   step: 0.01)
                    DoubleSliderRow(label: "Font Size", value: $fontSize,       range: 4...30,  step: 0.5)
                }

                Section("Motion") {
                    DoubleSliderRow(label: "Rotation", value: $rotationSpeed, range: 0...3,    step: 0.05)
                    DoubleSliderRow(label: "Fade s",   value: $fadeSeconds,   range: 0.5...20, step: 0.25)
                    DoubleSliderRow(label: "Wait s",   value: $waitSeconds,   range: 0...20,   step: 0.25)
                }
            }
            .navigationTitle("Char Sphere")
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

private struct DoubleSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

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

private struct StepperRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(label)
                Spacer()
                Text("\(value)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview("Default — Tao Te Ching") {
    NavigationStack {
        SWCharSphere(showsControls: true)
    }
}

#Preview("World flags") {
    SWCharSphere(
        chars: [
            // Asia
            "🇨🇳", "🇯🇵", "🇰🇷", "🇮🇳", "🇸🇬", "🇹🇭", "🇻🇳", "🇮🇩",
            "🇲🇾", "🇵🇭", "🇦🇪", "🇸🇦", "🇮🇱", "🇹🇷", "🇵🇰", "🇧🇩",
            // Europe
            "🇬🇧", "🇫🇷", "🇩🇪", "🇮🇹", "🇪🇸", "🇵🇹", "🇳🇱", "🇧🇪",
            "🇨🇭", "🇸🇪", "🇳🇴", "🇫🇮", "🇩🇰", "🇵🇱", "🇦🇹", "🇬🇷",
            "🇮🇪", "🇨🇿", "🇭🇺", "🇷🇴",
            // Americas
            "🇺🇸", "🇨🇦", "🇲🇽", "🇧🇷", "🇦🇷", "🇨🇱", "🇨🇴", "🇵🇪",
            // Africa
            "🇿🇦", "🇪🇬", "🇳🇬", "🇰🇪", "🇲🇦", "🇪🇹", "🇬🇭",
            // Oceania
            "🇦🇺", "🇳🇿",
            // Eurasia
            "🇷🇺", "🇺🇦", "🇰🇿"
        ], glyphCount: 160, fontSize: 10, showsControls: true
    )
    .ignoresSafeArea()
}
