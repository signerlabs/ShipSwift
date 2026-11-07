//
//  SWChangeEffectShowcase.swift
//  ShipSwift
//
//  Gallery page for SWChangeEffect: one tappable row per effect
//  (shake, jump, spin, ping, spray, rise, shine, haptic).
//
//  Demo / showcase only — not a reusable SWPackage component.
//

import SwiftUI

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
