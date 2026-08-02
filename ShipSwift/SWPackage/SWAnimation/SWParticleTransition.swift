//
//  SWParticleTransition.swift
//  ShipSwift
//
//  Three particle-powered view transitions built on the iOS 17+
//  `Transition` protocol, each with a self-contained Canvas burst engine:
//
//    - swPoof:  the view disappears (or appears) in a cartoon puff of
//               smoke — soft gray clouds that expand, drift up and fade.
//    - swPop:   the view pops into place with a ripple ring and a small
//               flurry of colorful particles.
//    - swAnvil: the view slams down from above and kicks up a burst of
//               dust on impact.
//
//  Usage:
//    if showBadge {
//        BadgeView()
//            .transition(.swPop)
//    }
//    withAnimation(.spring(duration: 0.5, bounce: 0.55)) { showBadge.toggle() }
//
//    // Poof works best around half a second
//    .transition(.swPoof)                    // with .easeOut(duration: 0.5)
//
//    // Anvil needs a hard ease-in drop
//    .transition(.swAnvil)                   // with .easeIn(duration: 0.22)
//
//    // Custom particle colors for pop
//    .transition(.swPop(colors: [.pink, .orange, .yellow]))
//
//  Recommended animations:
//    - swPoof:  .easeOut(duration: 0.5)
//    - swPop:   .spring(duration: 0.5, bounce: 0.55)
//    - swAnvil: .easeIn(duration: 0.22)
//
//  Tip: pair swAnvil with `.sensoryFeedback(.impact(weight: .heavy), trigger:)`
//  on the toggling state for a satisfying thud.
//
//  Created by Wei Zhong on 2/8/26.
//

import SwiftUI

// MARK: - Poof

/// Cartoon puff-of-smoke transition. On removal the view hides quickly
/// while a smoke cloud expands; on insertion the smoke bursts first and
/// the view fades in beneath it.
struct SWPoofTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .modifier(SWPoofFadeModifier(progress: phase.isIdentity ? 1 : 0))
            .overlay {
                SWBurstEmitterView(style: .poof, phase: phase)
                    .padding(-70)
                    .allowsHitTesting(false)
            }
    }
}

/// Compresses the fade into the first 40% of the timeline so the view
/// is gone (or back) while the smoke is still doing its thing.
private struct SWPoofFadeModifier: ViewModifier, Animatable {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let visibility = min(max((progress - 0.6) / 0.4, 0), 1)
        content
            .opacity(visibility)
            .scaleEffect(0.85 + 0.15 * visibility)
    }
}

extension Transition where Self == SWPoofTransition {
    /// Puff-of-smoke appear/disappear. Use with `.easeOut(duration: 0.5)`.
    static var swPoof: Self { .init() }
}

// MARK: - Pop

/// Pops the view in with a ripple ring and a flurry of particles.
struct SWPopTransition: Transition {
    var colors: [Color] = [.pink, .orange, .yellow, .mint, .cyan]

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .scaleEffect(phase.isIdentity ? 1 : 0.1)
            .opacity(phase.isIdentity ? 1 : 0)
            .overlay {
                SWBurstEmitterView(style: .pop(colors: colors), phase: phase)
                    .padding(-70)
                    .allowsHitTesting(false)
            }
    }
}

extension Transition where Self == SWPopTransition {
    /// Ripple-and-particles pop. Use with `.spring(duration: 0.5, bounce: 0.55)`.
    static var swPop: Self { .init() }
    /// Pop with custom particle colors.
    static func swPop(colors: [Color]) -> Self { .init(colors: colors) }
}

// MARK: - Anvil

/// Slams the view down from above; dust erupts from the base on impact.
struct SWAnvilTransition: Transition {
    var dropDistance: CGFloat = 350
    /// Seconds between the phase change and the dust burst — should match
    /// the drop animation duration so dust flies exactly on touchdown.
    var impactDelay: Double = 0.2

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .offset(y: phase == .willAppear ? -dropDistance : 0)
            .opacity(phase == .didDisappear ? 0 : 1)
            .overlay {
                SWBurstEmitterView(
                    style: .dust,
                    phase: phase,
                    fireDelay: impactDelay,
                    firesOnRemoval: false
                )
                .padding(-70)
                .allowsHitTesting(false)
            }
    }
}

extension Transition where Self == SWAnvilTransition {
    /// Slam-down with dust impact. Use with `.easeIn(duration: 0.22)`.
    static var swAnvil: Self { .init() }
    /// Slam-down with a custom drop distance.
    static func swAnvil(dropDistance: CGFloat) -> Self { .init(dropDistance: dropDistance) }
}

// MARK: - Burst Engine

/// Visual style of a particle burst.
private enum SWBurstStyle {
    case poof
    case pop(colors: [Color])
    case dust
}

/// One particle in a burst. Positions are relative to the emitter
/// canvas; physics are evaluated analytically each frame.
private struct SWBurstParticle {
    var startX: Double
    var startY: Double
    var vx: Double
    var vy: Double
    var gravity: Double
    var size: Double
    var growth: Double
    var color: Color
    var blur: Double
    var delay: Double
}

/// Fires one burst of particles whenever the transition phase changes.
/// Rendering runs on its own TimelineView clock, independent of the
/// transition's interpolation.
private struct SWBurstEmitterView: View {
    let style: SWBurstStyle
    let phase: TransitionPhase
    var fireDelay: Double = 0
    var firesOnRemoval: Bool = true

    @State private var particles: [SWBurstParticle] = []
    @State private var startTime: Date?

    /// Longest particle lifetime for this style.
    private var duration: Double {
        switch style {
        case .poof: 0.5
        case .pop: 0.55
        case .dust: 0.55
        }
    }

    var body: some View {
        TimelineView(.animation(paused: startTime == nil)) { ctx in
            Canvas { gc, size in
                guard let start = startTime else { return }
                let elapsed = ctx.date.timeIntervalSince(start)
                guard elapsed <= duration + 0.05 else { return }

                for p in particles {
                    let t = elapsed - p.delay
                    guard t > 0 else { continue }
                    let life = min(t / (duration - p.delay), 1)

                    let px = size.width / 2 + p.startX + p.vx * t
                    let py = size.height / 2 + p.startY + p.vy * t
                        + 0.5 * p.gravity * t * t
                    let radius = p.size * (1 + (p.growth - 1) * life) / 2
                    let alpha = life < 0.5 ? 1.0 : 1 - (life - 0.5) / 0.5

                    let rect = CGRect(
                        x: px - radius, y: py - radius,
                        width: radius * 2, height: radius * 2
                    )

                    if p.blur > 0 {
                        gc.drawLayer { layer in
                            layer.addFilter(.blur(radius: p.blur))
                            layer.opacity = alpha
                            layer.fill(Path(ellipseIn: rect), with: .color(p.color))
                        }
                    } else {
                        gc.opacity = alpha
                        gc.fill(Path(ellipseIn: rect), with: .color(p.color))
                        gc.opacity = 1
                    }
                }

                // Pop extra: expanding ripple ring drawn above particles.
                if case .pop = style {
                    let life = min(elapsed / 0.4, 1)
                    if life < 1 {
                        let inset = 70.0
                        let base = min(size.width - inset * 2, size.height - inset * 2)
                        let ringR = base * (0.3 + 0.55 * life) / 2
                        let alpha = 1 - life
                        gc.opacity = alpha
                        gc.stroke(
                            Path(ellipseIn: CGRect(
                                x: size.width / 2 - ringR,
                                y: size.height / 2 - ringR,
                                width: ringR * 2,
                                height: ringR * 2
                            )),
                            with: .color(.white.opacity(0.9)),
                            lineWidth: 3 * (1 - life) + 1
                        )
                        gc.opacity = 1
                    }
                }

                // Dust extra: flattened shockwave ellipse at the base.
                if case .dust = style {
                    let life = min(elapsed / 0.3, 1)
                    if life < 1 {
                        let inset = 70.0
                        let baseY = size.height - inset
                        let w = (size.width - inset * 2) * (0.4 + 0.8 * life)
                        gc.drawLayer { layer in
                            layer.addFilter(.blur(radius: 4))
                            layer.opacity = (1 - life) * 0.5
                            layer.fill(
                                Path(ellipseIn: CGRect(
                                    x: size.width / 2 - w / 2,
                                    y: baseY - 8,
                                    width: w,
                                    height: 16
                                )),
                                with: .color(.gray)
                            )
                        }
                    }
                }
            }
        }
        .onChange(of: phase) { oldPhase, newPhase in
            let inserting = oldPhase == .willAppear && newPhase == .identity
            let removing = oldPhase == .identity && newPhase == .didDisappear
            guard inserting || (removing && firesOnRemoval) else { return }
            fire()
        }
    }

    private func fire() {
        let generated = Self.makeParticles(for: style)
        if fireDelay > 0 {
            Task {
                try? await Task.sleep(for: .seconds(fireDelay))
                particles = generated
                startTime = .now
            }
        } else {
            particles = generated
            startTime = .now
        }
    }

    private static func makeParticles(for style: SWBurstStyle) -> [SWBurstParticle] {
        switch style {
        case .poof:
            // Soft gray clouds spreading outward from an ellipse around
            // the view, drifting up while expanding.
            return (0..<14).map { i in
                let angle = Double(i) / 14 * 2 * .pi + .random(in: -0.2...0.2)
                let rx = Double.random(in: 30...55)
                let ry = Double.random(in: 20...40)
                let speed = Double.random(in: 40...90)
                return SWBurstParticle(
                    startX: cos(angle) * rx,
                    startY: sin(angle) * ry,
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed * 0.6 - 30,
                    gravity: -40,
                    size: .random(in: 26...46),
                    growth: 1.8,
                    color: Color(white: .random(in: 0.75...0.95)),
                    blur: 6,
                    delay: .random(in: 0...0.06)
                )
            }

        case .pop(let colors):
            guard !colors.isEmpty else { return [] }
            // Small crisp dots shooting radially outward.
            return (0..<12).map { i in
                let angle = Double(i) / 12 * 2 * .pi + .random(in: -0.15...0.15)
                let speed = Double.random(in: 160...280)
                return SWBurstParticle(
                    startX: cos(angle) * 20,
                    startY: sin(angle) * 20,
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed,
                    gravity: 150,
                    size: .random(in: 5...9),
                    growth: 0.4,
                    color: colors[i % colors.count],
                    blur: 0,
                    delay: 0
                )
            }

        case .dust:
            // Gray clouds kicked out sideways from the base, settling down.
            return (0..<18).map { _ in
                let side: Double = Bool.random() ? 1 : -1
                return SWBurstParticle(
                    startX: side * .random(in: 20...70),
                    startY: .random(in: 60...80),
                    vx: side * .random(in: 60...220),
                    vy: .random(in: -80 ... -20),
                    gravity: 320,
                    size: .random(in: 10...22),
                    growth: 1.5,
                    color: Color(white: .random(in: 0.6...0.8)),
                    blur: 3,
                    delay: .random(in: 0...0.05)
                )
            }
        }
    }
}

// MARK: - Showcase

enum SWParticleTransitionKind: String, CaseIterable, Identifiable {
    case poof = "Poof"
    case pop = "Pop"
    case anvil = "Anvil"

    var id: String { rawValue }

    var transition: AnyTransition {
        switch self {
        case .poof: AnyTransition(.swPoof)
        case .pop: AnyTransition(.swPop)
        case .anvil: AnyTransition(.swAnvil)
        }
    }

    var animation: Animation {
        switch self {
        case .poof: .easeOut(duration: 0.5)
        case .pop: .spring(duration: 0.5, bounce: 0.55)
        case .anvil: .easeIn(duration: 0.22)
        }
    }

    var icon: String {
        switch self {
        case .poof: "cloud.fill"
        case .pop: "burst.fill"
        case .anvil: "hammer.fill"
        }
    }
}

struct SWParticleTransitionShowcase: View {
    @State private var kind: SWParticleTransitionKind = .poof
    @State private var visible = true
    @State private var impacts = 0

    var body: some View {
        VStack(spacing: 10) {
            // Stage — takes all remaining vertical space.
            // Demo image: Bubble Nebula, NASA/Hubble via Unsplash (free license).
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.quinary)

                    if visible {
                        demoCard(size: CGSize(
                            width: min(330, geo.size.width - 48),
                            height: min(450, geo.size.height - 48)
                        ))
                        .transition(kind.transition)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .padding(.horizontal)
            .sensoryFeedback(.impact(weight: .heavy), trigger: impacts)

            Picker("Effect", selection: $kind) {
                ForEach(SWParticleTransitionKind.allCases) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: kind) {
                replay()
            }

            Button {
                replay()
            } label: {
                Label("Replay", systemImage: "arrow.counterclockwise")
                    .font(.footnote.weight(.medium))
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.small)
            .padding(.bottom, 6)
        }
        .navigationTitle("Particle Transitions")
        .toolbarTitleDisplayMode(.inline)
    }

    private func demoCard(size: CGSize) -> some View {
        Image(.transitionDemo)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .bottom) {
                VStack(spacing: 3) {
                    Text(kind.rawValue)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text(".transition(.sw\(kind.rawValue))")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func replay() {
        withAnimation(kind.animation) {
            visible = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            withAnimation(kind.animation) {
                visible = true
            }
            if kind == .anvil {
                try? await Task.sleep(for: .milliseconds(220))
                impacts += 1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SWParticleTransitionShowcase()
    }
}
