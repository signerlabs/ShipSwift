//
//  SWConfettiShowcase.swift
//  ShipSwift
//
//  Gallery page for SWConfetti: a tap-to-celebrate confetti burst, plus a
//  New Year fireworks show (Marina Bay Sands skyline) picked from the
//  toolbar menu.
//
//  Demo / showcase only — not a reusable SWPackage component.
//

import SwiftUI

// MARK: - Showcase

enum SWConfettiShowcaseMode: String, CaseIterable {
    case confetti = "Confetti"
    case fireworks = "Fireworks"
}

struct SWConfettiShowcase: View {
    @State private var mode: SWConfettiShowcaseMode = .confetti
    @State private var celebrate = false

    var body: some View {
        Group {
            switch mode {
            case .confetti:
                SWConfetti(isActive: $celebrate, autoReset: true) {
                    VStack(spacing: 20) {
                        Spacer()
                        Text("Confetti Burst")
                            .font(.title2.weight(.semibold))
                        Text("Tap to celebrate")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Celebrate!") {
                            celebrate = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

            case .fireworks:
                SWConfettiFireworkShowView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("", selection: $mode) {
                        ForEach(SWConfettiShowcaseMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                } label: {
                    Label(mode.rawValue, systemImage: mode == .confetti ? "party.popper" : "sparkles")
                }
            }
        }
    }
}

// MARK: - MBS Fireworks Show

private struct SWFireworkBurstConfig {
    let delay: Double
    let x: Double
    let y: Double
    let colors: [Color]
    let particleCount: Int
    let duration: Double
    let minSpeed: Double
    let maxSpeed: Double
    let gravity: Double
    let launchDuration: Double
    let launchY: Double
}

private struct SWFireworkParticle {
    let vx: Double
    let vy: Double
    let color: Color
    let size: Double
    let brightness: Double
}

private struct SWFireworkShowCanvas: View {
    let bursts: [SWFireworkBurstConfig]
    let cycleDuration: Double
    let starPositions: [(x: Double, y: Double, size: Double, phase: Double)]

    @State private var allParticles: [[SWFireworkParticle]]
    @State private var showStart: Date = .now

    init(bursts: [SWFireworkBurstConfig]) {
        self.bursts = bursts
        self.cycleDuration = (bursts.map { $0.delay + $0.launchDuration + $0.duration }.max() ?? 5) + 1.0
        var stars: [(x: Double, y: Double, size: Double, phase: Double)] = []
        for i in 0..<60 {
            let hash1 = Double((i * 7 + 13) % 100) / 100.0
            let hash2 = Double((i * 11 + 37) % 100) / 100.0
            let hash3 = Double((i * 3 + 59) % 100) / 100.0
            let hash4 = Double((i * 17 + 41) % 100) / 100.0
            stars.append((x: hash1, y: hash2 * 0.5, size: 0.5 + hash3 * 1.5, phase: hash4 * .pi * 2))
        }
        self.starPositions = stars
        _allParticles = State(initialValue: Self.generateAllParticles(for: bursts))
    }

    private static func generateAllParticles(for bursts: [SWFireworkBurstConfig]) -> [[SWFireworkParticle]] {
        bursts.map { config in
            (0..<config.particleCount).map { _ in
                let angle = Double.random(in: 0...(2 * .pi))
                let speed = Double.random(in: config.minSpeed...config.maxSpeed)
                return SWFireworkParticle(
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed,
                    color: config.colors.randomElement()!,
                    size: Double.random(in: 1.5...4.0),
                    brightness: Double.random(in: 0.6...1.0)
                )
            }
        }
    }

    var body: some View {
        TimelineView(.animation) { ctx in
            Canvas { gc, size in
                let totalElapsed = ctx.date.timeIntervalSince(showStart)
                let elapsed = totalElapsed.truncatingRemainder(dividingBy: cycleDuration)

                for star in starPositions {
                    let twinkle = 0.3 + 0.7 * abs(sin(totalElapsed * 1.5 + star.phase))
                    let sx = star.x * size.width
                    let sy = star.y * size.height
                    let r = star.size * twinkle
                    gc.opacity = twinkle * 0.8
                    gc.fill(
                        Path(ellipseIn: CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2)),
                        with: .color(.white)
                    )
                    gc.opacity = 1
                }

                for (i, config) in bursts.enumerated() {
                    guard i < allParticles.count else { continue }
                    let sinceDelay = elapsed - config.delay
                    guard sinceDelay > 0 else { continue }
                    guard sinceDelay < config.launchDuration + config.duration else { continue }

                    let originX = config.x * size.width
                    let originY = config.y * size.height
                    let groundY = config.launchY * size.height

                    // --- Phase 1: Launch trail rising from ground to burst point ---
                    if sinceDelay < config.launchDuration {
                        let lp = sinceDelay / config.launchDuration
                        let eased = 1 - (1 - lp) * (1 - lp)
                        let headX = originX
                        let headY = groundY + (originY - groundY) * eased

                        // Fading tail behind the head
                        let tailLen = min(eased, 0.35)
                        let tailY = groundY + (originY - groundY) * max(0, eased - tailLen)
                        gc.opacity = 0.5
                        var tailPath = Path()
                        tailPath.move(to: CGPoint(x: headX, y: tailY))
                        tailPath.addLine(to: CGPoint(x: headX, y: headY))
                        gc.stroke(tailPath, with: .color(config.colors[0].opacity(0.4)), lineWidth: 1.5)
                        gc.opacity = 1

                        // Sparks falling off the head
                        let sparkCount = 6
                        for s in 0..<sparkCount {
                            let seed = Double(i * 100 + s)
                            let age = sinceDelay - Double(s) * 0.04
                            guard age > 0 else { continue }
                            let sx = headX + sin(seed * 3.7 + age * 8) * 4
                            let sy = headY + age * 50 + sin(seed * 2.3) * 10
                            let sparkAlpha = max(0, 1 - age * 3)
                            gc.opacity = sparkAlpha * 0.7
                            gc.fill(
                                Path(ellipseIn: CGRect(x: sx - 1, y: sy - 1, width: 2, height: 2)),
                                with: .color(config.colors[0])
                            )
                        }

                        // Blurred head glow
                        gc.drawLayer { headCtx in
                            headCtx.addFilter(.blur(radius: 8))
                            headCtx.opacity = 0.9
                            let r = 5.0
                            headCtx.fill(
                                Path(ellipseIn: CGRect(x: headX - r, y: headY - r, width: r * 2, height: r * 2)),
                                with: .color(config.colors[0])
                            )
                        }
                        // Sharp white core
                        gc.fill(
                            Path(ellipseIn: CGRect(x: headX - 2, y: headY - 2, width: 4, height: 4)),
                            with: .color(.white)
                        )
                        continue
                    }

                    // --- Phase 2: Explosion ---
                    let burstElapsed = sinceDelay - config.launchDuration
                    let progress = burstElapsed / config.duration

                    // Blurred flash at explosion start
                    if progress < 0.1 {
                        gc.drawLayer { flashCtx in
                            flashCtx.addFilter(.blur(radius: 20))
                            let flashAlpha = 1.0 - progress / 0.1
                            let flashR = 20.0 + progress / 0.1 * 40
                            flashCtx.opacity = flashAlpha * 0.8
                            flashCtx.fill(
                                Path(ellipseIn: CGRect(
                                    x: originX - flashR, y: originY - flashR,
                                    width: flashR * 2, height: flashR * 2
                                )),
                                with: .color(.white)
                            )
                        }
                    }

                    // Glow layer — all particles for this burst, blurred
                    gc.drawLayer { glowCtx in
                        glowCtx.addFilter(.blur(radius: 6))
                        for p in allParticles[i] {
                            let t = burstElapsed
                            let drag = pow(0.92, t * 3)
                            let px = originX + p.vx * t * drag
                            let py = originY + p.vy * t * drag + 0.5 * config.gravity * t * t

                            guard px > -40 && px < size.width + 40 else { continue }
                            guard py > -40 && py < size.height + 40 else { continue }

                            let fadeStart = 0.35
                            let alpha: Double = progress < fadeStart
                                ? 1.0
                                : max(0, 1 - (progress - fadeStart) / (1 - fadeStart))
                            let particleSize = p.size * max(0.2, 1 - progress * 0.6)

                            glowCtx.opacity = alpha * p.brightness * 0.9
                            glowCtx.fill(
                                Path(ellipseIn: CGRect(
                                    x: px - particleSize, y: py - particleSize,
                                    width: particleSize * 2, height: particleSize * 2
                                )),
                                with: .color(p.color)
                            )
                        }
                    }

                    // Sharp layer — trail streaks + white cores
                    for p in allParticles[i] {
                        let t = burstElapsed
                        let drag = pow(0.92, t * 3)
                        let px = originX + p.vx * t * drag
                        let py = originY + p.vy * t * drag + 0.5 * config.gravity * t * t

                        guard px > -20 && px < size.width + 20 else { continue }
                        guard py > -20 && py < size.height + 20 else { continue }

                        let fadeStart = 0.35
                        let alpha: Double = progress < fadeStart
                            ? 1.0
                            : max(0, 1 - (progress - fadeStart) / (1 - fadeStart))
                        let particleSize = p.size * max(0.2, 1 - progress * 0.6)

                        // Trail streak
                        let trailDt = 0.05
                        let prevT = max(0, t - trailDt)
                        let prevDrag = pow(0.92, prevT * 3)
                        let prevX = originX + p.vx * prevT * prevDrag
                        let prevY = originY + p.vy * prevT * prevDrag
                            + 0.5 * config.gravity * prevT * prevT
                        gc.opacity = alpha * 0.5 * p.brightness
                        var trail = Path()
                        trail.move(to: CGPoint(x: prevX, y: prevY))
                        trail.addLine(to: CGPoint(x: px, y: py))
                        gc.stroke(trail, with: .color(p.color), lineWidth: particleSize * 0.6)

                        // White core
                        let coreR = particleSize * 0.4
                        gc.opacity = alpha * p.brightness
                        gc.fill(
                            Path(ellipseIn: CGRect(
                                x: px - coreR, y: py - coreR,
                                width: coreR * 2, height: coreR * 2
                            )),
                            with: .color(.white)
                        )
                        gc.opacity = 1
                    }

                    // Water reflection — blurred
                    let waterY = size.height * 0.78
                    if originY < waterY {
                        gc.drawLayer { refCtx in
                            refCtx.addFilter(.blur(radius: 4))
                            for p in allParticles[i] {
                                let t = burstElapsed
                                let drag = pow(0.92, t * 3)
                                let px = originX + p.vx * t * drag
                                let py = originY + p.vy * t * drag + 0.5 * config.gravity * t * t

                                guard px > -20 && px < size.width + 20 else { continue }

                                let reflectedY = 2 * waterY - py
                                guard reflectedY > waterY && reflectedY < size.height + 20 else { continue }

                                let fadeStart = 0.35
                                let alpha: Double = progress < fadeStart
                                    ? 1.0
                                    : max(0, 1 - (progress - fadeStart) / (1 - fadeStart))
                                let particleSize = p.size * max(0.2, 1 - progress * 0.6)

                                refCtx.opacity = alpha * 0.12
                                refCtx.fill(
                                    Path(ellipseIn: CGRect(
                                        x: px - particleSize, y: reflectedY - particleSize,
                                        width: particleSize * 2, height: particleSize * 2
                                    )),
                                    with: .color(p.color)
                                )
                            }
                        }
                    }
                }
            }
        }
        .onTapGesture {
            allParticles = Self.generateAllParticles(for: bursts)
            showStart = .now
        }
    }
}

// MARK: - Firework Show View

private let fireworkBursts: [SWFireworkBurstConfig] = [
    .init(delay: 0.0, x: 0.50, y: 0.22, colors: [
        Color(red: 1, green: 0.85, blue: 0.3), Color(red: 1, green: 0.7, blue: 0.1), .orange, .yellow
    ], particleCount: 100, duration: 2.8, minSpeed: 60, maxSpeed: 200, gravity: 30, launchDuration: 0.8, launchY: 0.72),
    .init(delay: 0.4, x: 0.25, y: 0.18, colors: [
        .red, Color(red: 1, green: 0.3, blue: 0.3), .orange, Color(red: 1, green: 0.5, blue: 0.2)
    ], particleCount: 80, duration: 2.5, minSpeed: 50, maxSpeed: 170, gravity: 25, launchDuration: 0.9, launchY: 0.72),
    .init(delay: 0.7, x: 0.75, y: 0.20, colors: [
        .green, .mint, .cyan, Color(red: 0.3, green: 1, blue: 0.5)
    ], particleCount: 80, duration: 2.5, minSpeed: 50, maxSpeed: 170, gravity: 25, launchDuration: 0.85, launchY: 0.72),
    .init(delay: 2.5, x: 0.45, y: 0.14, colors: [
        .purple, .pink, Color(red: 0.8, green: 0.4, blue: 1), Color(red: 1, green: 0.6, blue: 0.8)
    ], particleCount: 90, duration: 2.8, minSpeed: 55, maxSpeed: 190, gravity: 28, launchDuration: 1.0, launchY: 0.72),
    .init(delay: 2.9, x: 0.68, y: 0.16, colors: [
        .blue, .cyan, Color(red: 0.3, green: 0.6, blue: 1), .white
    ], particleCount: 70, duration: 2.4, minSpeed: 45, maxSpeed: 160, gravity: 22, launchDuration: 0.9, launchY: 0.72),
    .init(delay: 3.3, x: 0.30, y: 0.25, colors: [
        .white, Color(red: 0.85, green: 0.85, blue: 0.95), Color(red: 0.7, green: 0.8, blue: 1)
    ], particleCount: 60, duration: 2.2, minSpeed: 40, maxSpeed: 150, gravity: 20, launchDuration: 0.7, launchY: 0.72),
    .init(delay: 5.0, x: 0.50, y: 0.18, colors: [
        Color(red: 1, green: 0.9, blue: 0.4), Color(red: 1, green: 0.8, blue: 0.2), .white, .yellow
    ], particleCount: 130, duration: 3.2, minSpeed: 70, maxSpeed: 230, gravity: 32, launchDuration: 0.85, launchY: 0.72),
    .init(delay: 5.3, x: 0.18, y: 0.22, colors: [
        .red, .orange, Color(red: 1, green: 0.4, blue: 0.2)
    ], particleCount: 60, duration: 2.5, minSpeed: 40, maxSpeed: 140, gravity: 22, launchDuration: 0.75, launchY: 0.72),
    .init(delay: 5.6, x: 0.82, y: 0.22, colors: [
        .green, .cyan, Color(red: 0.4, green: 1, blue: 0.6)
    ], particleCount: 60, duration: 2.5, minSpeed: 40, maxSpeed: 140, gravity: 22, launchDuration: 0.75, launchY: 0.72),
    .init(delay: 6.0, x: 0.50, y: 0.10, colors: [
        .purple, .pink, .white, Color(red: 0.9, green: 0.5, blue: 1)
    ], particleCount: 90, duration: 3.0, minSpeed: 60, maxSpeed: 200, gravity: 28, launchDuration: 1.1, launchY: 0.72),
]

struct SWConfettiFireworkShowView: View {
    private let nightTop = Color(red: 0.02, green: 0.02, blue: 0.08)
    private let nightBottom = Color(red: 0.05, green: 0.05, blue: 0.18)
    private let waterTop = Color(red: 0.03, green: 0.04, blue: 0.14)
    private let waterBottom = Color(red: 0.01, green: 0.02, blue: 0.06)

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [nightTop, nightBottom, waterTop, waterBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            SWFireworkShowCanvas(bursts: fireworkBursts)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                Image("singapore-skyline-silhouette")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.12, blue: 0.18),
                                Color(red: 0.08, green: 0.08, blue: 0.14)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.horizontal, -8)
                    .offset(y: 4)

                Rectangle()
                    .fill(waterTop.opacity(0.6))
                    .frame(height: 2)
            }
            .padding(.bottom, 160)

            VStack {
                Text("HAPPY NEW YEAR")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(6)
                    .foregroundStyle(.white.opacity(0.7))
                Text("2026")
                    .font(.system(size: 42, weight: .thin, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1, green: 0.85, blue: 0.4),
                                Color(red: 1, green: 0.7, blue: 0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Marina Bay Sands, Singapore")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.bottom, 60)
        }
    }
}

#Preview("MBS New Year Fireworks") {
    SWConfettiFireworkShowView()
}
