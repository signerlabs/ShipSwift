//
//  SWTransitionShowcase.swift
//  ShipSwift
//
//  Gallery page for SWTransition: a demo card that replays any of the 16
//  transitions picked from a grid of buttons.
//
//  Demo / showcase only — not a reusable SWPackage component.
//

import SwiftUI

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
