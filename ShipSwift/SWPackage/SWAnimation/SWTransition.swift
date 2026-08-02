//
//  SWTransition.swift
//  ShipSwift
//
//  A collection of 16 modern view transitions built on the iOS 17+
//  `Transition` protocol. Covers filter effects (blur, film exposure,
//  snapshot flash), 3D motion (flip, rotate, swoosh), elastic motion
//  (boing, skid, move), and animatable mask reveals (iris, wipe, blinds,
//  clock, glare, flicker, dissolve). Every transition is a plain value
//  type usable via static dot-syntax, e.g. `.transition(.swBoing)`.
//
//  Usage:
//    // Insert / remove a view with a transition
//    if showCard {
//        CardView()
//            .transition(.swIris)
//    }
//    // Trigger with an explicit animation for best feel
//    withAnimation(.spring(duration: 0.6, bounce: 0.5)) { showCard.toggle() }
//
//    // Parameterised variants
//    .transition(.swWipe(angle: .degrees(45)))
//    .transition(.swMove(angle: .degrees(135), distance: 500))
//    .transition(.swIris(origin: .bottomTrailing))
//    .transition(.swDissolve(cellSize: 10))
//
//  Recommended animations:
//    - swBoing / swSkid / swSwoosh:  .spring(duration: 0.6, bounce: 0.5)
//    - swFlicker / swDissolve / mask reveals:  .linear(duration: 0.5) or .easeInOut
//    - everything else:  .smooth or .easeInOut
//
//  Parameters (per transition, all optional with sensible defaults):
//    - swBlur(radius:)          — Max blur radius, default 24
//    - swBoing(distance:)       — Drop-in distance in pts, default 80
//    - swSkid(distance:)        — Slide-in distance in pts, default 160
//    - swMove(angle:distance:)  — Direction the view enters from
//    - swRotate3D(angle:axis:)  — 3D rotation angle and axis
//    - swIris(origin:)          — Circle grow origin as UnitPoint
//    - swWipe(angle:)           — Sweep direction, default 45°
//    - swBlinds(slatHeight:)    — Slat height in pts, default 24
//    - swGlare(angle:)          — Streak direction, default 45°
//    - swDissolve(cellSize:)    — Dissolve grid cell size in pts, default 8
//
//  Created by Wei Zhong on 2/8/26.
//

import SwiftUI

// MARK: - Blur

/// Transitions from blurry and transparent to sharp and opaque.
struct SWBlurTransition: Transition {
    var radius: Double = 24

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .blur(radius: phase.isIdentity ? 0 : radius)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

extension Transition where Self == SWBlurTransition {
    /// Blurry-to-sharp fade.
    static var swBlur: Self { .init() }
    /// Blurry-to-sharp fade with a custom max radius.
    static func swBlur(radius: Double) -> Self { .init(radius: radius) }
}

// MARK: - Flip

/// Flips the view toward the viewer on insertion and away on removal.
struct SWFlipTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .rotation3DEffect(
                .degrees(phase.value * -85),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.4
            )
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

extension Transition where Self == SWFlipTransition {
    /// 3D flip around the horizontal axis.
    static var swFlip: Self { .init() }
}

// MARK: - Rotate3D

/// Rotates the view in 3D around a configurable axis.
struct SWRotate3DTransition: Transition {
    var angle: Angle = .degrees(90)
    var axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (x: 0, y: 1, z: 0)

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .rotation3DEffect(
                .degrees(phase.value * angle.degrees),
                axis: axis,
                perspective: 0.4
            )
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

extension Transition where Self == SWRotate3DTransition {
    /// 3D rotation around the vertical axis.
    static var swRotate3D: Self { .init() }
    /// 3D rotation with a custom angle and axis.
    static func swRotate3D(
        angle: Angle,
        axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    ) -> Self {
        .init(angle: angle, axis: axis)
    }
}

// MARK: - Swoosh

/// Flies in from behind the viewer: oversized, blurred and tilted,
/// then settles into place. Removal shrinks it back into the distance.
struct SWSwooshTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .scaleEffect(
                phase == .willAppear ? 2.4 : (phase == .didDisappear ? 0.4 : 1)
            )
            .rotation3DEffect(
                .degrees(phase.value * 20),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.3
            )
            .blur(radius: phase.isIdentity ? 0 : 8)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

extension Transition where Self == SWSwooshTransition {
    /// Back-to-front 3D fly-in.
    static var swSwoosh: Self { .init() }
}

// MARK: - Boing

/// Drops in from above and lands with an elastic squash-and-stretch.
/// Pair with a bouncy spring for the full cartoon feel.
struct SWBoingTransition: Transition {
    var distance: CGFloat = 80

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .scaleEffect(
                x: phase.isIdentity ? 1 : 0.9,
                y: phase.isIdentity ? 1 : 1.25,
                anchor: .bottom
            )
            .offset(y: phase.isIdentity ? 0 : -distance)
            .opacity(phase == .willAppear ? 0 : 1)
    }
}

extension Transition where Self == SWBoingTransition {
    /// Elastic drop-in. Use with `.spring(duration: 0.6, bounce: 0.5)`.
    static var swBoing: Self { .init() }
    /// Elastic drop-in from a custom height.
    static func swBoing(distance: CGFloat) -> Self { .init(distance: distance) }
}

// MARK: - Skid

/// Slides in from the leading edge, shearing in the direction of motion
/// like it is skidding to a stop. A bouncy spring makes the shear whip
/// back and forth naturally as the offset overshoots.
struct SWSkidTransition: Transition {
    var distance: CGFloat = 160

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .modifier(SWSkewEffect(skew: phase.isIdentity ? 0 : -0.35))
            .offset(x: phase.isIdentity ? 0 : -distance)
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

/// Horizontal shear, animatable for use inside transitions.
private struct SWSkewEffect: GeometryEffect {
    var skew: CGFloat

    var animatableData: CGFloat {
        get { skew }
        set { skew = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        // Shear around the vertical midline so the view doesn't drift.
        let shear = CGAffineTransform(a: 1, b: 0, c: skew, d: 1,
                                      tx: -skew * size.height / 2, ty: 0)
        return ProjectionTransform(shear)
    }
}

extension Transition where Self == SWSkidTransition {
    /// Shearing slide-in. Use with `.spring(duration: 0.6, bounce: 0.5)`.
    static var swSkid: Self { .init() }
    /// Shearing slide-in from a custom distance.
    static func swSkid(distance: CGFloat) -> Self { .init(distance: distance) }
}

// MARK: - Move (angle)

/// Moves the view in from an arbitrary angle instead of just an edge.
/// 0° enters from trailing, 90° from the bottom, 180° from leading,
/// 270° from the top.
struct SWMoveTransition: Transition {
    var angle: Angle
    var distance: CGFloat = 400

    func body(content: Content, phase: TransitionPhase) -> some View {
        let dx = CGFloat(cos(angle.radians)) * distance
        let dy = CGFloat(sin(angle.radians)) * distance
        return content
            .offset(
                x: phase.isIdentity ? 0 : dx,
                y: phase.isIdentity ? 0 : dy
            )
            .opacity(phase.isIdentity ? 1 : 0)
    }
}

extension Transition where Self == SWMoveTransition {
    /// Directional move from an arbitrary angle.
    static func swMove(angle: Angle, distance: CGFloat = 400) -> Self {
        .init(angle: angle, distance: distance)
    }
}

// MARK: - Iris

/// Reveals the view through a growing circle, like a camera iris.
struct SWIrisTransition: Transition {
    var origin: UnitPoint = .center

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .mask {
                SWIrisShape(
                    progress: phase.isIdentity ? 1 : 0,
                    origin: origin
                )
            }
    }
}

/// Circle whose radius grows from `origin` to cover the whole rect.
private struct SWIrisShape: Shape {
    var progress: CGFloat
    var origin: UnitPoint

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.width * origin.x, y: rect.height * origin.y)
        // Furthest corner distance = radius needed for full coverage.
        let maxRadius = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
        .map { hypot($0.x - center.x, $0.y - center.y) }
        .max() ?? 0

        let radius = maxRadius * max(0, progress)
        return Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }
}

extension Transition where Self == SWIrisTransition {
    /// Growing-circle reveal from the center.
    static var swIris: Self { .init() }
    /// Growing-circle reveal from a custom origin.
    static func swIris(origin: UnitPoint) -> Self { .init(origin: origin) }
}

// MARK: - Wipe (angle)

/// Reveals the view with a straight edge sweeping across at any angle.
struct SWWipeTransition: Transition {
    var angle: Angle = .degrees(45)

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .mask {
                SWWipeShape(
                    progress: phase.isIdentity ? 1 : 0,
                    angle: angle
                )
            }
    }
}

/// Half-plane that sweeps across the rect along `angle`.
private struct SWWipeShape: Shape {
    var progress: CGFloat
    var angle: Angle

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(max(progress, 0), 1)
        guard clamped > 0 else { return Path() }

        let dir = CGPoint(x: cos(angle.radians), y: sin(angle.radians))
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
        // Project corners onto the sweep direction to find travel range.
        let dots = corners.map { $0.x * dir.x + $0.y * dir.y }
        let minD = dots.min() ?? 0
        let maxD = dots.max() ?? 0
        let edge = minD + (maxD - minD) * clamped

        // Quad covering everything behind the sweep edge.
        let reach = hypot(rect.width, rect.height) * 2
        let normal = CGPoint(x: -dir.y, y: dir.x)
        let edgeCenter = CGPoint(x: dir.x * edge, y: dir.y * edge)

        let p1 = CGPoint(x: edgeCenter.x + normal.x * reach, y: edgeCenter.y + normal.y * reach)
        let p2 = CGPoint(x: edgeCenter.x - normal.x * reach, y: edgeCenter.y - normal.y * reach)
        let p3 = CGPoint(x: p2.x - dir.x * reach, y: p2.y - dir.y * reach)
        let p4 = CGPoint(x: p1.x - dir.x * reach, y: p1.y - dir.y * reach)

        var path = Path()
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.addLine(to: p4)
        path.closeSubpath()
        return path
    }
}

extension Transition where Self == SWWipeTransition {
    /// Diagonal sweep reveal.
    static var swWipe: Self { .init() }
    /// Sweep reveal along a custom angle.
    static func swWipe(angle: Angle) -> Self { .init(angle: angle) }
}

// MARK: - Blinds

/// Reveals the view through horizontal slats, like window blinds opening.
struct SWBlindsTransition: Transition {
    var slatHeight: CGFloat = 24

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .mask {
                SWBlindsShape(
                    progress: phase.isIdentity ? 1 : 0,
                    slatHeight: slatHeight
                )
            }
    }
}

/// Rows of bars, each growing from zero to `slatHeight`.
private struct SWBlindsShape: Shape {
    var progress: CGFloat
    var slatHeight: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(max(progress, 0), 1)
        var path = Path()
        var y: CGFloat = 0
        while y < rect.height {
            path.addRect(CGRect(
                x: 0, y: y,
                width: rect.width,
                height: slatHeight * clamped
            ))
            y += slatHeight
        }
        return path
    }
}

extension Transition where Self == SWBlindsTransition {
    /// Window-blinds reveal.
    static var swBlinds: Self { .init() }
    /// Window-blinds reveal with custom slat height.
    static func swBlinds(slatHeight: CGFloat) -> Self { .init(slatHeight: slatHeight) }
}

// MARK: - Clock

/// Reveals the view with a clockwise sweep around the center.
struct SWClockTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .mask {
                SWClockShape(progress: phase.isIdentity ? 1 : 0)
            }
    }
}

/// Pie sector sweeping from 12 o'clock through a full revolution.
private struct SWClockShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(max(progress, 0), 1)
        guard clamped > 0 else { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = hypot(rect.width, rect.height) / 2

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * clamped),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

extension Transition where Self == SWClockTransition {
    /// Clockwise sweep reveal.
    static var swClock: Self { .init() }
}

// MARK: - Flicker

/// Toggles visibility a few times before settling, like a faulty
/// fluorescent tube. Use a `.linear` animation for even flicker timing.
struct SWFlickerTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .modifier(SWFlickerModifier(progress: phase.isIdentity ? 1 : 0))
    }
}

/// Maps continuous progress onto a deterministic on/off square wave.
private struct SWFlickerModifier: ViewModifier, Animatable {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    // On/off pattern sampled across progress; ends fully on.
    private static let pattern: [Bool] = [
        false, true, false, false, true, false, true, false, true, true
    ]

    func body(content: Content) -> some View {
        content.opacity(currentOpacity)
    }

    private var currentOpacity: CGFloat {
        if progress >= 0.99 { return 1 }
        if progress <= 0 { return 0 }
        let index = min(
            Int(progress * CGFloat(Self.pattern.count)),
            Self.pattern.count - 1
        )
        return Self.pattern[index] ? 1 : 0
    }
}

extension Transition where Self == SWFlickerTransition {
    /// Faulty-light flicker. Use with `.linear(duration: 0.5)`.
    static var swFlicker: Self { .init() }
}

// MARK: - Film Exposure

/// Develops from a dark, desaturated frame into the full image,
/// like film being exposed.
struct SWFilmExposureTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .brightness(phase.isIdentity ? 0 : -1)
            .saturation(phase.isIdentity ? 1 : 0.2)
    }
}

extension Transition where Self == SWFilmExposureTransition {
    /// Dark-to-developed film exposure.
    static var swFilmExposure: Self { .init() }
}

// MARK: - Snapshot

/// Flashes in from an overexposed white frame, like a camera flash.
struct SWSnapshotTransition: Transition {
    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .brightness(phase.isIdentity ? 0 : 1)
            .opacity(phase == .didDisappear ? 0 : 1)
    }
}

extension Transition where Self == SWSnapshotTransition {
    /// Overexposed camera-flash entrance.
    static var swSnapshot: Self { .init() }
}

// MARK: - Glare

/// Diagonal wipe with a bright streak of light tracing the reveal edge.
struct SWGlareTransition: Transition {
    var angle: Angle = .degrees(45)

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .modifier(SWGlareModifier(
                progress: phase.isIdentity ? 1 : 0,
                angle: angle
            ))
    }
}

/// Wipe mask plus a moving highlight band at the sweep edge.
private struct SWGlareModifier: ViewModifier, Animatable {
    var progress: CGFloat
    var angle: Angle

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask {
                SWWipeShape(progress: progress, angle: angle)
            }
            .overlay {
                GeometryReader { geo in
                    let travel = hypot(geo.size.width, geo.size.height)
                    let bandWidth = travel * 0.35
                    // Streak follows the wipe edge and fades at both ends.
                    let along = (progress - 0.5) * travel
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.9), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: bandWidth, height: travel * 2)
                        .rotationEffect(angle + .degrees(90))
                        .position(
                            x: geo.size.width / 2 + along * CGFloat(cos(angle.radians)),
                            y: geo.size.height / 2 + along * CGFloat(sin(angle.radians))
                        )
                        .opacity(Double(sin(min(max(progress, 0), 1) * .pi)))
                        .blendMode(.screen)
                }
                .allowsHitTesting(false)
                .clipped()
            }
    }
}

extension Transition where Self == SWGlareTransition {
    /// Diagonal wipe with a light streak.
    static var swGlare: Self { .init() }
    /// Wipe-with-streak along a custom angle.
    static func swGlare(angle: Angle) -> Self { .init(angle: angle) }
}

// MARK: - Dissolve

/// Dissolves the view into a grid of randomly disappearing cells,
/// pixel-dissolve style. The ShipSwift take on Pow's "vanish".
struct SWDissolveTransition: Transition {
    var cellSize: CGFloat = 8

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .modifier(SWDissolveModifier(
                progress: phase.isIdentity ? 1 : 0,
                cellSize: cellSize
            ))
    }
}

/// Canvas mask where each grid cell hides once progress drops below
/// its deterministic per-cell threshold.
private struct SWDissolveModifier: ViewModifier, Animatable {
    var progress: CGFloat
    var cellSize: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let clamped = min(max(progress, 0), 1)
        content
            .mask {
                Canvas { context, size in
                    let cols = Int(ceil(size.width / cellSize))
                    let rows = Int(ceil(size.height / cellSize))
                    for row in 0..<rows {
                        for col in 0..<cols {
                            // Deterministic pseudo-random threshold per cell.
                            let seed = sin(Double(row * 73 + col * 151) + 1.23) * 43758.5453
                            let threshold = CGFloat(seed - floor(seed))
                            if threshold < clamped {
                                context.fill(
                                    Path(CGRect(
                                        x: CGFloat(col) * cellSize,
                                        y: CGFloat(row) * cellSize,
                                        width: cellSize,
                                        height: cellSize
                                    )),
                                    with: .color(.black)
                                )
                            }
                        }
                    }
                }
            }
            // Soften the last few surviving cells.
            .opacity(clamped < 0.12 ? clamped / 0.12 : 1)
    }
}

extension Transition where Self == SWDissolveTransition {
    /// Pixel-dissolve into random cells. Use with `.linear(duration: 0.5)`.
    static var swDissolve: Self { .init() }
    /// Pixel-dissolve with a custom cell size.
    static func swDissolve(cellSize: CGFloat) -> Self { .init(cellSize: cellSize) }
}

// MARK: - Showcase

/// All transitions with their display names and recommended animations.
enum SWTransitionKind: String, CaseIterable, Identifiable {
    case boing = "Boing"
    case skid = "Skid"
    case swoosh = "Swoosh"
    case flip = "Flip"
    case rotate3D = "Rotate 3D"
    case move = "Move"
    case blur = "Blur"
    case iris = "Iris"
    case wipe = "Wipe"
    case blinds = "Blinds"
    case clock = "Clock"
    case glare = "Glare"
    case dissolve = "Dissolve"
    case flicker = "Flicker"
    case filmExposure = "Film Exposure"
    case snapshot = "Snapshot"

    var id: String { rawValue }

    var transition: AnyTransition {
        switch self {
        case .blur: AnyTransition(.swBlur)
        case .flip: AnyTransition(.swFlip)
        case .rotate3D: AnyTransition(.swRotate3D)
        case .swoosh: AnyTransition(.swSwoosh)
        case .boing: AnyTransition(.swBoing)
        case .skid: AnyTransition(.swSkid)
        case .move: AnyTransition(.swMove(angle: .degrees(135)))
        case .iris: AnyTransition(.swIris)
        case .wipe: AnyTransition(.swWipe)
        case .blinds: AnyTransition(.swBlinds)
        case .clock: AnyTransition(.swClock)
        case .glare: AnyTransition(.swGlare)
        case .dissolve: AnyTransition(.swDissolve)
        case .flicker: AnyTransition(.swFlicker)
        case .filmExposure: AnyTransition(.swFilmExposure)
        case .snapshot: AnyTransition(.swSnapshot)
        }
    }

    /// Animation that shows this transition at its best.
    var animation: Animation {
        switch self {
        case .boing, .skid, .swoosh:
            .spring(duration: 0.6, bounce: 0.5)
        case .flicker, .dissolve, .wipe, .blinds, .clock, .glare, .iris:
            .linear(duration: 0.55)
        case .filmExposure:
            .easeInOut(duration: 0.8)
        default:
            .smooth(duration: 0.5)
        }
    }
}

struct SWTransitionShowcase: View {
    @State private var kind: SWTransitionKind = .boing
    @State private var visible = true

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 8)]

    var body: some View {
        VStack(spacing: 10) {
            // Stage — takes all remaining vertical space.
            // Demo image: Bubble Nebula, NASA/Hubble via Unsplash (free license).
            GeometryReader { geo in
                if visible {
                    demoCard()
                        .transition(kind.transition)
                    // Identity per kind: switching effects swaps the card,
                    // so the old card exits with its own transition and the
                    // new card enters with the newly selected one.
                        .id(kind)
                        .padding(.top)
                }
            }
            // Transition picker
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(SWTransitionKind.allCases) { item in
                    Button {
                        if kind == item {
                            replay()
                        } else {
                            // Must be its own transaction: removing the card in
                            // the same transaction as a kind change would replay
                            // the exit with the previous transition (SwiftUI uses
                            // the outgoing view's last-rendered transition).
                            withAnimation(item.animation) {
                                kind = item
                            }
                        }
                    } label: {
                        Text(item.rawValue)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                kind == item
                                    ? AnyShapeStyle(.tint)
                                    : AnyShapeStyle(.quinary),
                                in: .capsule
                            )
                            .foregroundStyle(kind == item ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

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
        .navigationTitle("Transitions")
        .toolbarTitleDisplayMode(.inline)
    }

    private func demoCard() -> some View {
        Image(.transitionDemo)
            .resizable()
            .scaledToFit()
            .overlay(alignment: .bottom) {
                VStack(spacing: 3) {
                    Text(kind.rawValue)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text(".transition(.sw\(kind.rawValue.replacingOccurrences(of: " ", with: "")))")
                        .font(.caption.monospaced())
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 30)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 30)
    }

    private func replay() {
        withAnimation(kind.animation) {
            visible = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(750))
            withAnimation(kind.animation) {
                visible = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SWTransitionShowcase()
    }
}
