//
//  SWHalftone.swift
//  ShipSwift
//
//  A halftone print filter rendered via a SwiftUI Metal `layerEffect`.
//  Wraps any view — the child content is treated as a source image,
//  quantized into a rotated cell grid, and rendered as dots whose size
//  tracks the local luminance (or CMYK channel coverage in `.cmyk` mode).
//
//  Style menu:
//    • `.dotsClassic` — crisp newspaper circles (square or hex grid)
//    • `.dotsGooey`   — soft merging ink puddles
//    • `.dotsHoles`   — donut-style negative dots that fill the cell
//                       once they get big enough
//    • `.dotsSoft`    — fuzzy radial falloff
//    • `.cmyk`        — 4-channel CMYK ink at 15° / 75° / 0° / 45°,
//                       multiplicatively layered on a paper background
//
//  Requires iOS 18+ / macOS 15+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — gooey black dots on white paper, square grid
//    SWHalftone {
//        Image(.facePicture)
//            .resizable()
//            .scaledToFill()
//    }
//
//    // CMYK printing look
//    SWHalftone(style: .cmyk) {
//        Image(.facePicture)
//    }
//
//    // Original-color halftone (keeps the photo's natural hues, drops
//    // the dot mask on top)
//    SWHalftone(
//        style: .dotsGooey,
//        originalColors: true
//    ) {
//        Image(.facePicture)
//    }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWHalftone(showsControls: true) {
//        Image(.facePicture)
//    }
//
//  Parameters:
//    - style: One of 5 halftone styles (see list above). Default
//             `.dotsGooey`.
//    - grid: `.square` or `.hex`. Only affects `.dots*` styles
//            (default `.square`).
//    - size: Grid density in `0...1` — small = dense, large = sparse
//            (default `0.5`).
//    - radius: Maximum dot size in `0...2` (default `1.0`).
//    - contrast: Luminance shaping in `0...1` (default `0.5`).
//    - inverted: Swap dark / light luminance mapping (default `false`).
//    - originalColors: Keep the sampled image's colors instead of
//                      replacing with `colorFront` / `colorBack`
//                      (default `false`, dots styles only).
//    - grainMixer: 0–1 noise that perturbs dot edges (default `0`).
//    - grainOverlay: 0–1 black/white grain laid on top (default `0`).
//    - grainSize: 0–1 grain texture scale (default `0.5`).
//    - colorFront / colorBack: Ink and paper colors for the `.dots*`
//                              styles (default `.black` / `.white`).
//    - colorC / colorM / colorY / colorK: CMYK plate colors for the
//                              `.cmyk` style.
//    - colorBack: Paper color (shared between `.dots*` and `.cmyk`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a
//                     live-tuning sheet (default `false`).
//
//  Created by Wei Zhong on 5/24/26.
//

import SwiftUI

// MARK: - Public types

/// Halftone style — picks dot shape & whether to use CMYK plates.
enum SWHalftoneStyle: Hashable {
    case dotsClassic
    case dotsGooey
    case dotsHoles
    case dotsSoft
    case cmyk

    /// Whether this style routes to the dots shader (vs the cmyk shader).
    fileprivate var isDots: Bool { self != .cmyk }

    /// Metal `type` parameter for the dots shader (0..3); irrelevant for cmyk.
    fileprivate var dotsTypeIndex: Int {
        switch self {
        case .dotsClassic: return 0
        case .dotsGooey:   return 1
        case .dotsHoles:   return 2
        case .dotsSoft:    return 3
        case .cmyk:        return 0
        }
    }
}

/// Grid arrangement for the `.dots*` styles. Ignored by `.cmyk`.
enum SWHalftoneGrid: Hashable {
    case square
    case hex

    fileprivate var index: Int { self == .square ? 0 : 1 }
}

// MARK: - Main View

struct SWHalftone<Content: View>: View {
    /// One of 5 halftone styles.
    var style: SWHalftoneStyle = .dotsGooey

    /// Grid arrangement — only meaningful for `.dots*` styles.
    var grid: SWHalftoneGrid = .square

    /// Grid density in 0...1 — small = dense, large = sparse.
    var size: Float = 1

    /// Maximum dot size in 0...2.
    var radius: Float = 1.0

    /// Luminance shaping in 0...1.
    var contrast: Float = 0.5

    /// Swap dark / light luminance mapping.
    var inverted: Bool = false

    /// Keep the sampled image's colors rather than replacing with ink/paper.
    /// Only applies to `.dots*` styles.
    var originalColors: Bool = false

    /// Noise that perturbs dot edges (0...1).
    var grainMixer: Float = 0

    /// Black/white grain laid on top of the result (0...1).
    var grainOverlay: Float = 0

    /// Grain texture scale (0...1).
    var grainSize: Float = 0.5

    /// Ink color for `.dots*` styles.
    var colorFront: Color = .black

    /// Paper / background color (used by both `.dots*` and `.cmyk`).
    var colorBack: Color = .white

    // CMYK plate colors — defaults to the conventional process inks.
    var colorC: Color = Color(red: 0.000, green: 0.682, blue: 0.937)   // process cyan
    var colorM: Color = Color(red: 0.925, green: 0.000, blue: 0.549)   // process magenta
    var colorY: Color = Color(red: 1.000, green: 0.949, blue: 0.000)   // process yellow
    var colorK: Color = .black

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    private let content: Content

    init(
        style: SWHalftoneStyle = .dotsGooey,
        grid: SWHalftoneGrid = .square,
        size: Float = 0.5,
        radius: Float = 1.0,
        contrast: Float = 0.5,
        inverted: Bool = false,
        originalColors: Bool = false,
        grainMixer: Float = 0,
        grainOverlay: Float = 0,
        grainSize: Float = 0.5,
        colorFront: Color = .black,
        colorBack: Color = .white,
        colorC: Color = Color(red: 0.000, green: 0.682, blue: 0.937),
        colorM: Color = Color(red: 0.925, green: 0.000, blue: 0.549),
        colorY: Color = Color(red: 1.000, green: 0.949, blue: 0.000),
        colorK: Color = .black,
        showsControls: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.grid = grid
        self.size = size
        self.radius = radius
        self.contrast = contrast
        self.inverted = inverted
        self.originalColors = originalColors
        self.grainMixer = grainMixer
        self.grainOverlay = grainOverlay
        self.grainSize = grainSize
        self.colorFront = colorFront
        self.colorBack = colorBack
        self.colorC = colorC
        self.colorM = colorM
        self.colorY = colorY
        self.colorK = colorK
        self.showsControls = showsControls
        self.content = content()
    }

    var body: some View {
        if showsControls {
            SWHalftoneControlled(initial: self, content: content)
        } else {
            SWHalftoneRenderer(initial: self, content: content)
        }
    }
}

// MARK: - Renderer (routes to dots or cmyk shader)

private struct SWHalftoneRenderer<Content: View>: View {
    let initial: SWHalftone<Content>
    let content: Content

    var body: some View {
        // `maxSampleOffset` tells SwiftUI how far the shader may read.
        // The halftone grid samples cell centers up to ~`dotSize` away —
        // 400pt covers all realistic sizes safely.
        let maxOffset = CGSize(width: 400, height: 400)

        if initial.style.isDots {
            content.layerEffect(
                ShaderLibrary.swHalftoneDots(
                    .boundingRect,
                    .float(Float(initial.style.dotsTypeIndex)),
                    .float(Float(initial.grid.index)),
                    .float(initial.size),
                    .float(initial.radius),
                    .float(initial.contrast),
                    .float(initial.inverted ? 1 : 0),
                    .float(initial.originalColors ? 1 : 0),
                    .float(initial.grainMixer),
                    .float(initial.grainOverlay),
                    .float(initial.grainSize),
                    .color(initial.colorFront),
                    .color(initial.colorBack)
                ),
                maxSampleOffset: maxOffset
            )
        } else {
            content.layerEffect(
                ShaderLibrary.swHalftoneCmyk(
                    .boundingRect,
                    .float(initial.size),
                    .float(initial.contrast),
                    .color(initial.colorBack),
                    .color(initial.colorC),
                    .color(initial.colorM),
                    .color(initial.colorY),
                    .color(initial.colorK)
                ),
                maxSampleOffset: maxOffset
            )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWHalftoneControlled<Content: View>: View {
    @State private var style: SWHalftoneStyle
    @State private var grid: SWHalftoneGrid
    @State private var size: Float
    @State private var radius: Float
    @State private var contrast: Float
    @State private var inverted: Bool
    @State private var originalColors: Bool
    @State private var grainMixer: Float
    @State private var grainOverlay: Float
    @State private var grainSize: Float
    @State private var colorFront: Color
    @State private var colorBack: Color
    @State private var colorC: Color
    @State private var colorM: Color
    @State private var colorY: Color
    @State private var colorK: Color

    @State private var showSheet = false

    private let content: Content

    init(initial: SWHalftone<Content>, content: Content) {
        _style           = State(initialValue: initial.style)
        _grid            = State(initialValue: initial.grid)
        _size            = State(initialValue: initial.size)
        _radius          = State(initialValue: initial.radius)
        _contrast        = State(initialValue: initial.contrast)
        _inverted        = State(initialValue: initial.inverted)
        _originalColors  = State(initialValue: initial.originalColors)
        _grainMixer      = State(initialValue: initial.grainMixer)
        _grainOverlay    = State(initialValue: initial.grainOverlay)
        _grainSize       = State(initialValue: initial.grainSize)
        _colorFront      = State(initialValue: initial.colorFront)
        _colorBack       = State(initialValue: initial.colorBack)
        _colorC          = State(initialValue: initial.colorC)
        _colorM          = State(initialValue: initial.colorM)
        _colorY          = State(initialValue: initial.colorY)
        _colorK          = State(initialValue: initial.colorK)
        self.content = content
    }

    var body: some View {
        SWHalftoneRenderer(
            initial: SWHalftone(
                style: style,
                grid: grid,
                size: size,
                radius: radius,
                contrast: contrast,
                inverted: inverted,
                originalColors: originalColors,
                grainMixer: grainMixer,
                grainOverlay: grainOverlay,
                grainSize: grainSize,
                colorFront: colorFront,
                colorBack: colorBack,
                colorC: colorC,
                colorM: colorM,
                colorY: colorY,
                colorK: colorK
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
                .accessibilityLabel("Halftone Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWHalftoneControlsSheet(
                style: $style,
                grid: $grid,
                size: $size,
                radius: $radius,
                contrast: $contrast,
                inverted: $inverted,
                originalColors: $originalColors,
                grainMixer: $grainMixer,
                grainOverlay: $grainOverlay,
                grainSize: $grainSize,
                colorFront: $colorFront,
                colorBack: $colorBack,
                colorC: $colorC,
                colorM: $colorM,
                colorY: $colorY,
                colorK: $colorK
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWHalftoneControlsSheet: View {
    @Binding var style: SWHalftoneStyle
    @Binding var grid: SWHalftoneGrid
    @Binding var size: Float
    @Binding var radius: Float
    @Binding var contrast: Float
    @Binding var inverted: Bool
    @Binding var originalColors: Bool
    @Binding var grainMixer: Float
    @Binding var grainOverlay: Float
    @Binding var grainSize: Float
    @Binding var colorFront: Color
    @Binding var colorBack: Color
    @Binding var colorC: Color
    @Binding var colorM: Color
    @Binding var colorY: Color
    @Binding var colorK: Color

    @Environment(\.dismiss) private var dismiss

    private var isDots: Bool { style.isDots }

    var body: some View {
        NavigationStack {
            Form {
                Section("Style") {
                    Picker("Style", selection: $style) {
                        Text("Classic").tag(SWHalftoneStyle.dotsClassic)
                        Text("Gooey").tag(SWHalftoneStyle.dotsGooey)
                        Text("Holes").tag(SWHalftoneStyle.dotsHoles)
                        Text("Soft").tag(SWHalftoneStyle.dotsSoft)
                        Text("CMYK").tag(SWHalftoneStyle.cmyk)
                    }
                    if isDots {
                        Picker("Grid", selection: $grid) {
                            Text("Square").tag(SWHalftoneGrid.square)
                            Text("Hex").tag(SWHalftoneGrid.hex)
                        }
                        .pickerStyle(.segmented)
                        Toggle("Inverted",        isOn: $inverted)
                        Toggle("Original Colors", isOn: $originalColors)
                    }
                }

                if isDots {
                    Section("Ink") {
                        ColorPicker("Front", selection: $colorFront, supportsOpacity: false)
                        ColorPicker("Back",  selection: $colorBack,  supportsOpacity: false)
                    }
                } else {
                    Section("Plates") {
                        ColorPicker("Cyan",    selection: $colorC, supportsOpacity: false)
                        ColorPicker("Magenta", selection: $colorM, supportsOpacity: false)
                        ColorPicker("Yellow",  selection: $colorY, supportsOpacity: false)
                        ColorPicker("Black",   selection: $colorK, supportsOpacity: false)
                        ColorPicker("Paper",   selection: $colorBack, supportsOpacity: false)
                    }
                }

                Section("Grid") {
                    SliderRow(label: "Size",     value: $size,     range: 0...1, step: 0.01)
                    if isDots {
                        SliderRow(label: "Radius", value: $radius, range: 0...2, step: 0.01)
                    }
                    SliderRow(label: "Contrast", value: $contrast, range: 0...1, step: 0.01)
                }

                if isDots {
                    Section("Grain") {
                        SliderRow(label: "Mixer",   value: $grainMixer,   range: 0...1, step: 0.01)
                        SliderRow(label: "Overlay", value: $grainOverlay, range: 0...1, step: 0.01)
                        SliderRow(label: "Size",    value: $grainSize,    range: 0...1, step: 0.01)
                    }
                }
            }
            .navigationTitle("Halftone")
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

#Preview("Gooey on photo") {
    NavigationStack {
        SWHalftone(showsControls: true) {
            Image(.facePicture)
                .resizable()
                .scaledToFill()
        }
    }
}

#Preview("CMYK plates") {
    SWHalftone(style: .cmyk) {
        Image(.facePicture)
            .resizable()
            .scaledToFill()
    }
}
