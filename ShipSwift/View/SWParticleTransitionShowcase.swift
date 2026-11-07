//
//  SWParticleTransitionShowcase.swift
//  ShipSwift
//
//  Gallery page for SWParticleTransition: a demo card that replays the
//  poof / pop / anvil transitions picked from a segmented control.
//
//  Demo / showcase only — not a reusable SWPackage component.
//

import SwiftUI

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
