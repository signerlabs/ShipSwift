//
//  SWHolographicCardShowcase.swift
//  ShipSwift
//
//  A "trading-card" showcase for the ShaderKit-derived foil family
//  (SWFoil / SWGlitter / SWIntenseBling / SWChromaticGlass /
//  SWPolishedAluminum). A single poker-card-proportioned scenery photo is
//  shown with one holographic finish applied. The finish is switched from a
//  Menu in the top-right of the navigation bar, and the active finish's core
//  parameters are exposed as live sliders directly on the page — dragging a
//  slider updates the shader in real time. Dragging the card itself feeds a
//  normalized tilt into the shader and a matching 3D rotation, so the
//  highlight sweeps across the surface like a real holographic card.
//
//  Demo / showcase only — not a reusable SWPackage component. It exists to
//  demonstrate the foil shaders on real artwork inside the component gallery.
//
//  Requires iOS 18+ / macOS 15+.
//

import SwiftUI

// MARK: - Effect Catalog

/// The five holographic finishes selectable from the toolbar Menu.
private enum CardEffect: Int, CaseIterable, Identifiable {
    case foil
    case glitter
    case intenseBling
    case chromaticGlass
    case polishedAluminum

    var id: Int { rawValue }

    /// Display name shown under the card and in the Menu.
    var title: String {
        switch self {
        case .foil:             return "Foil"
        case .glitter:          return "Glitter"
        case .intenseBling:     return "Intense Bling"
        case .chromaticGlass:   return "Chromatic Glass"
        case .polishedAluminum: return "Polished Aluminum"
        }
    }

    /// Asset name for the scenery photo paired with each finish.
    var imageName: String {
        switch self {
        case .foil:             return "aurora"
        case .glitter:          return "fireworks"
        case .intenseBling:     return "galaxy"
        case .chromaticGlass:   return "glacier"
        case .polishedAluminum: return "peak"
        }
    }

    /// Scene name printed on the card.
    var sceneTitle: String {
        switch self {
        case .foil:             return "AURORA BOREALIS"
        case .glitter:          return "FIREWORKS"
        case .intenseBling:     return "THE MILKY WAY"
        case .chromaticGlass:   return "GLACIER"
        case .polishedAluminum: return "THE MATTERHORN"
        }
    }

    /// Location line printed under the scene name.
    var sceneSubtitle: String {
        switch self {
        case .foil:             return "ALASKA · NORTHERN LIGHTS"
        case .glitter:          return "SYDNEY HARBOUR"
        case .intenseBling:     return "PARANAL OBSERVATORY"
        case .chromaticGlass:   return "GREENLAND ICE"
        case .polishedAluminum: return "SWISS ALPS"
        }
    }
}

// MARK: - Per-Effect Parameter Defaults

/// The tuned default parameter values applied whenever an effect is selected.
/// These match the values the carousel previously hard-coded, so switching to
/// an effect always starts from the look we shipped before the sliders existed.
private struct EffectDefaults {
    var intensity: Float
    var separation: Float
    var density: Float
    var speed: Float

    static func `for`(_ effect: CardEffect) -> EffectDefaults {
        switch effect {
        case .foil:
            return EffectDefaults(intensity: 0.5, separation: 0.9, density: 70, speed: 1.0)
        case .glitter:
            return EffectDefaults(intensity: 0.5, separation: 0.9, density: 70, speed: 1.0)
        case .intenseBling:
            return EffectDefaults(intensity: 0.5, separation: 0.9, density: 70, speed: 1.0)
        case .chromaticGlass:
            return EffectDefaults(intensity: 1.0, separation: 0.9, density: 70, speed: 1.0)
        case .polishedAluminum:
            return EffectDefaults(intensity: 0.4, separation: 0.9, density: 70, speed: 1.0)
        }
    }
}

// MARK: - Showcase Root

struct SWHolographicCardShowcase: View {
    @State private var selection: CardEffect = .foil

    // Live, page-resident parameters. Each effect reads only the subset it
    // exposes; the rest are kept in sync but simply ignored by that effect.
    @State private var intensity: Float = 0.5
    @State private var separation: Float = 0.9
    @State private var density: Float = 70
    @State private var speed: Float = 1.0

    var body: some View {
        ZStack {
            // Light stage keeps the labels and sliders legible.
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.85, green: 0.87, blue: 0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 0)

                // Single card for the active effect, fed by the live sliders.
                SWHolographicCard(
                    effect: selection,
                    intensity: intensity,
                    separation: separation,
                    density: density,
                    speed: speed
                )
                .padding(.horizontal, 36)
                .frame(height: 440)
                // Cross-fade + slight scale when switching effects.
                .id(selection)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))

                // Effect name.
                Text(selection.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: selection)

                // Live parameter sliders for the active effect.
                VStack(spacing: 12) {
                    ForEach(parameters(for: selection)) { param in
                        SWParameterSlider(
                            label: param.label,
                            value: param.binding,
                            range: param.range,
                            step: param.step
                        )
                    }
                }
                .padding(.horizontal, 28)
                .animation(.snappy, value: selection)

                Text("Drag the card to tilt its holographic finish")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 20)
        }
        .navigationTitle("Holographic Cards")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(CardEffect.allCases) { effect in
                        Button {
                            withAnimation(.snappy) { select(effect) }
                        } label: {
                            if selection == effect {
                                Label(effect.title, systemImage: "checkmark")
                            } else {
                                Text(effect.title)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "wand.and.stars")
                }
                .accessibilityLabel("Choose Effect")
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Selection + Parameter Reset

    /// Switches the active effect and resets every parameter to that effect's
    /// tuned defaults, so each finish always opens at the look we shipped.
    private func select(_ effect: CardEffect) {
        selection = effect
        let defaults = EffectDefaults.for(effect)
        intensity = defaults.intensity
        separation = defaults.separation
        density = defaults.density
        speed = defaults.speed
    }

    /// Describes one tunable slider: a label, a binding into the page state,
    /// and its range / step.
    private struct ParameterSpec: Identifiable {
        // Identify by label, NOT a fresh UUID. A new UUID on every rebuild made
        // ForEach destroy/recreate the Slider each time its value changed, which
        // interrupted the in-flight drag gesture ("stuck after one nudge").
        var id: String { label }
        let label: String
        let binding: Binding<Float>
        let range: ClosedRange<Float>
        let step: Float
    }

    /// The subset of sliders each effect actually exposes, matching the
    /// initializer parameters of the corresponding SW component.
    private func parameters(for effect: CardEffect) -> [ParameterSpec] {
        switch effect {
        case .foil:
            return [
                ParameterSpec(label: "Intensity", binding: $intensity, range: 0...1, step: 0.01),
                ParameterSpec(label: "Speed", binding: $speed, range: 0...3, step: 0.05),
            ]
        case .glitter:
            return [
                ParameterSpec(label: "Density", binding: $density, range: 10...120, step: 1),
                ParameterSpec(label: "Speed", binding: $speed, range: 0...3, step: 0.05),
            ]
        case .intenseBling:
            return [
                ParameterSpec(label: "Intensity", binding: $intensity, range: 0...1, step: 0.01),
                ParameterSpec(label: "Speed", binding: $speed, range: 0...3, step: 0.05),
            ]
        case .chromaticGlass:
            return [
                ParameterSpec(label: "Intensity", binding: $intensity, range: 0...1, step: 0.01),
                ParameterSpec(label: "Separation", binding: $separation, range: 0...1, step: 0.01),
            ]
        case .polishedAluminum:
            return [
                ParameterSpec(label: "Intensity", binding: $intensity, range: 0...1, step: 0.01),
                ParameterSpec(label: "Speed", binding: $speed, range: 0...3, step: 0.05),
            ]
        }
    }
}

// MARK: - Page Parameter Slider

/// A page-resident slider row: label on the left, right-aligned monospaced
/// value on the right, full-width Slider below. Mirrors the SliderRow style
/// used inside the SW finish components' tuning sheets, but lives on the page.
private struct SWParameterSlider: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

// MARK: - Single Card

private struct SWHolographicCard: View {
    let effect: CardEffect

    /// Live shader parameters supplied by the page sliders. Each effect reads
    /// only the subset it exposes.
    let intensity: Float
    let separation: Float
    let density: Float
    let speed: Float

    /// Live drag translation, reset to zero on release.
    @GestureState private var drag: CGSize = .zero

    /// Poker-card proportion (2.5 : 3.5).
    private let cardWidth: CGFloat = 260
    private var cardHeight: CGFloat { cardWidth * 3.5 / 2.5 }

    /// Normalized tilt in roughly -1...1 per axis, fed to the shader.
    private var tilt: CGSize {
        CGSize(
            width: max(-1, min(1, drag.width / 120)),
            height: max(-1, min(1, drag.height / 120))
        )
    }

    var body: some View {
        cardFace
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                // Glossy rim that sells the laminated-card edge.
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.7), .white.opacity(0.05), .white.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 18)
            // Tilt the whole card in 3D toward the drag direction.
            .rotation3DEffect(
                .degrees(Double(tilt.width) * 14),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .rotation3DEffect(
                .degrees(Double(-tilt.height) * 14),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .gesture(
                DragGesture()
                    .updating($drag) { value, state, _ in
                        state = value.translation
                    }
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: drag)
            .frame(maxWidth: .infinity)
    }

    /// The artwork + text composited, then run through the chosen shader using
    /// the live parameters from the page sliders.
    @ViewBuilder
    private var cardFace: some View {
        let content = artwork

        switch effect {
        case .foil:
            SWFoil(tilt: tilt, intensity: intensity, speed: speed) { content }
        case .glitter:
            SWGlitter(tilt: tilt, density: density, speed: speed) { content }
        case .intenseBling:
            SWIntenseBling(tilt: tilt, intensity: intensity, speed: speed) { content }
        case .chromaticGlass:
            SWChromaticGlass(tilt: tilt, intensity: intensity, separation: separation) { content }
        case .polishedAluminum:
            SWPolishedAluminum(tilt: tilt, intensity: intensity, speed: speed) { content }
        }
    }

    /// Portrait fill + bottom name plate. Shares one layout for all effects.
    private var artwork: some View {
        ZStack(alignment: .bottomLeading) {
            // Portrait fill — uses Image(effect.imageName) directly. If the
            // asset is missing, fall back to a tinted symbol so the build
            // never breaks.
            cardImage
                .frame(width: cardWidth, height: cardHeight)
                .clipped()

            // Legibility scrim under the name plate.
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Name plate.
            VStack(alignment: .leading, spacing: 4) {
                Text(effect.sceneTitle)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(effect.sceneSubtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .tracking(1.5)
            }
            .padding(18)
        }
        .background(Color.black)
    }

    /// Resolves the portrait asset, with a SF Symbol placeholder fallback.
    @ViewBuilder
    private var cardImage: some View {
        #if canImport(UIKit)
        if UIImage(named: effect.imageName) != nil {
            Image(effect.imageName)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
        #else
        Image(effect.imageName)
            .resizable()
            .scaledToFill()
        #endif
    }

    /// Tinted placeholder used only if the portrait asset is absent.
    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [.indigo, .purple],
                startPoint: .top,
                endPoint: .bottom
            )
            Image(systemName: "figure.soccer")
                .font(.system(size: 120))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SWHolographicCardShowcase()
    }
}
