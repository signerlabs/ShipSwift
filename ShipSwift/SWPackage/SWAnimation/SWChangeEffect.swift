//
//  SWChangeEffect.swift
//  ShipSwift
//
//  Eight micro-interaction effects that fire whenever an Equatable value
//  changes, built on modern iOS 17+ APIs (KeyframeAnimator, PhaseAnimator,
//  sensoryFeedback, Canvas). Attach one modifier, change the trigger
//  value, and the effect plays once:
//
//    - swShake:   horizontal shake with decaying amplitude (wrong input)
//    - swJump:    squat, leap and land with squash & stretch
//    - swSpin:    one full rotation with smooth easing
//    - swPing:    expanding rings radiating from behind the view
//    - swSpray:   cone of tinted SF Symbol particles shooting upward
//    - swRise:    floating "+1"-style text that drifts up and fades
//    - swHaptic:  thin bridge over .sensoryFeedback for discoverability
//    - SWShine:   one-shot highlight sweep masked to the content (wrapper)
//
//  Usage:
//    // Shake on failed attempts
//    PasswordField()
//        .swShake(trigger: failedAttempts)
//
//    // Like button: hearts spray + counter rises
//    Button { likes += 1 } label: { Image(systemName: "heart.fill") }
//        .swSpray(trigger: likes, symbol: "heart.fill",
//                 colors: [.red, .pink, .orange])
//        .swRise(trigger: likes, text: "+1", color: .red)
//
//    // One-shot shine (view wrapper, masks to content shape)
//    SWShine(trigger: purchased) {
//        ProBadge()
//    }
//
//    // Haptics — same as .sensoryFeedback, kept for discoverability
//    view.swHaptic(.success, trigger: purchased)
//
//  All effects are additive: stack multiple modifiers on the same view
//  and drive them from the same trigger.
//
//  Created by Wei Zhong on 2/8/26.
//

import SwiftUI

// MARK: - Shake

extension View {
    /// Shakes the view horizontally with decaying amplitude when
    /// `trigger` changes. Classic "wrong password" feedback.
    func swShake(trigger: some Equatable, amplitude: Double = 9) -> some View {
        keyframeAnimator(
            initialValue: 0.0,
            trigger: trigger
        ) { content, offset in
            content.offset(x: offset)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(-amplitude, duration: 0.06)
                CubicKeyframe(amplitude * 0.9, duration: 0.07)
                CubicKeyframe(-amplitude * 0.7, duration: 0.07)
                CubicKeyframe(amplitude * 0.5, duration: 0.07)
                CubicKeyframe(-amplitude * 0.3, duration: 0.07)
                CubicKeyframe(0.0, duration: 0.08)
            }
        }
    }
}

// MARK: - Jump

/// Keyframe state for the jump effect.
private struct SWJumpState {
    var y: Double = 0
    var stretch: Double = 1
}

extension View {
    /// Makes the view squat, leap up and land with cartoon
    /// squash-and-stretch when `trigger` changes.
    func swJump(trigger: some Equatable, height: Double = 40) -> some View {
        keyframeAnimator(
            initialValue: SWJumpState(),
            trigger: trigger
        ) { content, state in
            content
                .scaleEffect(
                    x: 2 - state.stretch,
                    y: state.stretch,
                    anchor: .bottom
                )
                .offset(y: state.y)
        } keyframes: { _ in
            KeyframeTrack(\.y) {
                // Squat, spring into the air, then drop back down.
                CubicKeyframe(0, duration: 0.10)
                CubicKeyframe(-height, duration: 0.24)
                CubicKeyframe(0, duration: 0.18)
                SpringKeyframe(0, duration: 0.2, spring: .bouncy)
            }
            KeyframeTrack(\.stretch) {
                CubicKeyframe(0.85, duration: 0.10)   // squat
                CubicKeyframe(1.12, duration: 0.20)   // stretch upward
                CubicKeyframe(1.0, duration: 0.18)
                CubicKeyframe(0.88, duration: 0.06)   // land squash
                SpringKeyframe(1.0, duration: 0.18, spring: .bouncy)
            }
        }
    }
}

// MARK: - Spin

extension View {
    /// Rotates the view one full turn when `trigger` changes.
    func swSpin(trigger: some Equatable, duration: Double = 0.6) -> some View {
        keyframeAnimator(
            initialValue: 0.0,
            trigger: trigger
        ) { content, angle in
            content.rotationEffect(.degrees(angle))
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(360, duration: duration)
            }
        }
    }
}

// MARK: - Ping

/// Keyframe state for one ping ring.
private struct SWPingRingState {
    var scale: Double = 1
    var opacity: Double = 0
}

/// One expanding ring; `delay` staggers rings within a burst.
private struct SWPingRing: View {
    let fire: Int
    let delay: Double
    let color: Color

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .keyframeAnimator(
                initialValue: SWPingRingState(),
                trigger: fire
            ) { content, state in
                content
                    .scaleEffect(state.scale)
                    .opacity(state.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1.0, duration: delay)
                    CubicKeyframe(2.4, duration: 0.9)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(0.0, duration: delay)
                    LinearKeyframe(0.7, duration: 0.05)
                    LinearKeyframe(0.0, duration: 0.85)
                }
            }
    }
}

private struct SWPingModifier<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let color: Color
    let rings: Int

    @State private var fireCount = 0

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    ForEach(0..<rings, id: \.self) { index in
                        SWPingRing(
                            fire: fireCount,
                            delay: Double(index) * 0.18,
                            color: color
                        )
                    }
                }
                .allowsHitTesting(false)
            }
            .onChange(of: trigger) {
                fireCount += 1
            }
    }
}

extension View {
    /// Radiates expanding rings from behind the view when `trigger`
    /// changes. Great on notification bells and record buttons.
    func swPing(
        trigger: some Equatable,
        color: Color = .accentColor,
        rings: Int = 2
    ) -> some View {
        modifier(SWPingModifier(trigger: trigger, color: color, rings: rings))
    }
}

// MARK: - Spray

/// One particle in a spray or rise burst.
private struct SWSprayParticle {
    var birth: Date
    var startX: Double
    var vx: Double
    var vy: Double
    var size: Double
    var spin: Double
    var color: Color
}

private struct SWSprayModifier<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let symbol: String
    let colors: [Color]

    @State private var particles: [SWSprayParticle] = []

    private let lifetime = 0.9
    private let gravity = 480.0

    func body(content: Content) -> some View {
        content
            .overlay {
                TimelineView(.animation(paused: particles.isEmpty)) { ctx in
                    Canvas { gc, size in
                        let origin = CGPoint(x: size.width / 2, y: size.height / 2)
                        for p in particles {
                            let t = ctx.date.timeIntervalSince(p.birth)
                            guard t >= 0, t <= lifetime else { continue }

                            let life = t / lifetime
                            let px = origin.x + p.startX + p.vx * t
                            let py = origin.y + p.vy * t + 0.5 * gravity * t * t
                            let alpha = life < 0.6 ? 1.0 : 1 - (life - 0.6) / 0.4

                            var image = gc.resolve(Image(systemName: symbol))
                            image.shading = .color(p.color)

                            gc.drawLayer { layer in
                                layer.opacity = alpha
                                layer.translateBy(x: px, y: py)
                                layer.rotate(by: .degrees(p.spin * t))
                                layer.draw(
                                    image,
                                    in: CGRect(
                                        x: -p.size / 2, y: -p.size / 2,
                                        width: p.size, height: p.size
                                    )
                                )
                            }
                        }
                    }
                }
                .padding(-90)
                .allowsHitTesting(false)
            }
            .onChange(of: trigger) {
                fire()
            }
    }

    private func fire() {
        guard !colors.isEmpty else { return }
        let now = Date.now
        let fresh = (0..<11).map { i in
            // Upward cone between -55° and -125°.
            let angle = Double.random(in: (-125.0)...(-55.0)) * .pi / 180
            let speed = Double.random(in: 220...380)
            return SWSprayParticle(
                birth: now.addingTimeInterval(.random(in: 0...0.06)),
                startX: .random(in: -10...10),
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                size: .random(in: 10...18),
                spin: .random(in: -220...220),
                color: colors[i % colors.count]
            )
        }
        // Keep any particles still alive so rapid taps overlap nicely.
        particles = particles.filter {
            now.timeIntervalSince($0.birth) < lifetime
        } + fresh
    }
}

extension View {
    /// Sprays a cone of tinted SF Symbol particles upward from the view
    /// when `trigger` changes. The go-to for like buttons.
    func swSpray(
        trigger: some Equatable,
        symbol: String = "circle.fill",
        colors: [Color] = [.pink, .red, .orange]
    ) -> some View {
        modifier(SWSprayModifier(trigger: trigger, symbol: symbol, colors: colors))
    }
}

// MARK: - Rise

/// One floating text item.
private struct SWRiseItem: Identifiable {
    let id = UUID()
    let birth: Date
    let drift: Double
    let wobblePhase: Double
}

private struct SWRiseModifier<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let text: String
    let color: Color

    @State private var items: [SWRiseItem] = []

    private let lifetime = 1.1
    private let riseDistance = 60.0

    func body(content: Content) -> some View {
        content
            .overlay {
                TimelineView(.animation(paused: items.isEmpty)) { ctx in
                    Canvas { gc, size in
                        for item in items {
                            let t = ctx.date.timeIntervalSince(item.birth)
                            guard t >= 0, t <= lifetime else { continue }

                            let life = t / lifetime
                            // Ease-out rise with a gentle sideways wobble.
                            let eased = 1 - pow(1 - life, 2)
                            let x = size.width / 2 + item.drift
                                + sin(life * 3 * .pi + item.wobblePhase) * 5
                            let y = size.height * 0.25 - eased * riseDistance
                            let alpha = life < 0.15
                                ? life / 0.15
                                : (life < 0.65 ? 1 : 1 - (life - 0.65) / 0.35)

                            let resolved = gc.resolve(
                                Text(text)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(color)
                            )
                            gc.opacity = alpha
                            gc.draw(resolved, at: CGPoint(x: x, y: y))
                            gc.opacity = 1
                        }
                    }
                }
                .padding(-90)
                .allowsHitTesting(false)
            }
            .onChange(of: trigger) {
                let now = Date.now
                items = items.filter {
                    now.timeIntervalSince($0.birth) < lifetime
                } + [SWRiseItem(
                    birth: now,
                    drift: .random(in: -12...12),
                    wobblePhase: .random(in: 0...(2 * .pi))
                )]
            }
    }
}

extension View {
    /// Floats a "+1"-style label up from the view when `trigger` changes.
    /// Rapid triggers stack multiple floaters.
    func swRise(
        trigger: some Equatable,
        text: String = "+1",
        color: Color = .primary
    ) -> some View {
        modifier(SWRiseModifier(trigger: trigger, text: text, color: color))
    }
}

// MARK: - Haptic

extension View {
    /// Plays haptic feedback when `trigger` changes. Thin bridge over the
    /// native `.sensoryFeedback` API, included so haptics show up next to
    /// the other change effects. Prefer the native API in new code.
    func swHaptic(
        _ feedback: SensoryFeedback,
        trigger: some Equatable
    ) -> some View {
        sensoryFeedback(feedback, trigger: trigger)
    }
}

// MARK: - Shine

/// One-shot highlight sweep across the content, masked to its shape.
/// A view wrapper (not a modifier) so the light band can be clipped to
/// the exact content silhouette. For a continuous loop use `SWShimmer`.
struct SWShine<Trigger: Equatable, Content: View>: View {
    var trigger: Trigger
    var duration: Double = 0.75
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .overlay {
                GeometryReader { geo in
                    let bandWidth = geo.size.width * 0.6
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.75), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: bandWidth)
                    .rotationEffect(.degrees(14))
                    .phaseAnimator(
                        [false, true],
                        trigger: trigger
                    ) { view, swept in
                        view.offset(
                            x: swept
                                ? geo.size.width + bandWidth
                                : -bandWidth * 1.5
                        )
                    } animation: { swept in
                        // Animate the sweep; snap back instantly off-screen.
                        swept ? .easeInOut(duration: duration) : nil
                    }
                }
                .mask { content() }
                .allowsHitTesting(false)
            }
    }
}

// MARK: - Showcase

/// Generic demo row: tapping anywhere triggers the wrapped effect.
private struct SWEffectDemoRow<Demo: View>: View {
    let title: String
    let code: String
    @ViewBuilder let demo: (Int) -> Demo

    @State private var count = 0

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(code)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            demo(count)
                .frame(width: 96, height: 64)
        }
        .contentShape(.rect)
        .onTapGesture {
            count += 1
        }
    }
}

struct SWChangeEffectShowcase: View {
    var body: some View {
        List {
            Section {
                SWEffectDemoRow(
                    title: "Shake",
                    code: ".swShake(trigger:)"
                ) { count in
                    Text("PIN 0000")
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.red.opacity(0.12), in: .rect(cornerRadius: 8))
                        .foregroundStyle(.red)
                        .swShake(trigger: count)
                }

                SWEffectDemoRow(
                    title: "Jump",
                    code: ".swJump(trigger:)"
                ) { count in
                    Text("🏀")
                        .font(.system(size: 40))
                        .swJump(trigger: count)
                }

                SWEffectDemoRow(
                    title: "Spin",
                    code: ".swSpin(trigger:)"
                ) { count in
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.blue)
                        .swSpin(trigger: count)
                }

                SWEffectDemoRow(
                    title: "Ping",
                    code: ".swPing(trigger:)"
                ) { count in
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.orange)
                        .frame(width: 44, height: 44)
                        .background(.orange.opacity(0.15), in: .circle)
                        .swPing(trigger: count, color: .orange)
                }

                SWEffectDemoRow(
                    title: "Spray",
                    code: ".swSpray(trigger:)"
                ) { count in
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.red)
                        .swSpray(
                            trigger: count,
                            symbol: "heart.fill",
                            colors: [.red, .pink, .orange]
                        )
                }

                SWEffectDemoRow(
                    title: "Rise",
                    code: ".swRise(trigger:)"
                ) { count in
                    VStack(spacing: 2) {
                        Text("\(count)")
                            .font(.title3.weight(.bold))
                            .contentTransition(.numericText(value: Double(count)))
                            .animation(.snappy, value: count)
                        Text("points")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .swRise(trigger: count, text: "+1", color: .green)
                }

                SWEffectDemoRow(
                    title: "Shine",
                    code: "SWShine(trigger:) { }"
                ) { count in
                    SWShine(trigger: count) {
                        Text("PRO")
                            .font(.callout.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: .capsule
                            )
                    }
                }

                SWEffectDemoRow(
                    title: "Haptic",
                    code: ".swHaptic(.success, trigger:)"
                ) { count in
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.green)
                        .swHaptic(.success, trigger: count)
                        .swJump(trigger: count, height: 14)
                }
            } header: {
                Text("Tap any row to fire its effect")
            }
        }
        .navigationTitle("Change Effects")
        .toolbarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SWChangeEffectShowcase()
    }
}
