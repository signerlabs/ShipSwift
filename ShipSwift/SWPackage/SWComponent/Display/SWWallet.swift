//
//  SWWallet.swift
//  ShipSwift
//
//  A playful wallet "pocket" that holds a stack of payment cards. Three (or
//  more) cards are tucked into an olive-green pouch from the top opening: the
//  upper half of each card peeks out while the lower half slides behind the
//  wallet's front panel, creating a real "card inserted into a pocket" look.
//  The front panel shows the combined total balance plus a "Total Balance"
//  caption and an eye toggle that reveals or hides every amount at once.
//
//  Two states, driven by a single `isRevealed` flag:
//    1. Hidden (default) — cards are tucked deep into the pouch and stacked on
//       top of each other; the total reads as a row of bullets (••••••) and the
//       eye button shows `eye.slash`.
//    2. Revealed — cards spring out one after another into a staggered ladder
//       (first card highest, last card nearest the pocket opening); the total
//       morphs into the real sum (thousands-separated) and the eye button shows
//       `eye`.
//
//  The staggered "pop out" is built from a per-card `.animation` modifier with a
//  `.delay(index * 0.07)`, so each card bounces out slightly after the previous
//  one. Number changes use `.contentTransition(.numericText())` so the bullets
//  and digits cross-fade smoothly.
//
//  Layering (ZStack, bottom to top):
//    1. Card layer — a `RoundedRectangle` per card carrying a bold text
//       wordmark and its balance. The lower half is intentionally covered by the
//       front panel. `zIndex` keeps the ladder stacked correctly.
//    2. Wallet front panel (the pocket) — an `UnevenRoundedRectangle` filled
//       with `walletColor`, overlapping the lower half of the cards. Its top
//       edge is the pocket opening. The panel carries: white dashed stitching
//       inset along its edge, the big rounded total balance + caption, and the
//       eye toggle button at the bottom center.
//
//  Brand note: wordmarks are rendered as plain bold `Text` only — no official
//  brand logo image assets are bundled (this is a public repo). Swap the
//  `SWWalletCard.sample` data for your own accounts.
//
//  Usage:
//    // Default sample cards (Stripe / Wise / PayPal)
//    SWWallet()
//
//    // Custom cards + wallet color
//    SWWallet(
//        cards: [
//            SWWalletCard(name: "Cash",   balance: 1200, tint: .green,  foreground: .white),
//            SWWalletCard(name: "Savings", balance: 8400, tint: .blue,   foreground: .white)
//        ],
//        currencyCode: "USD",
//        walletColor: Color(red: 0.16, green: 0.21, blue: 0.09)
//    )
//
//  Note on `currencyCode`:
//    Amounts are formatted with `.currency(code:)`, so the symbol and grouping
//    follow the supplied ISO currency code and the device locale.
//
//  Created by Wei Zhong on 5/30/26.
//

import SwiftUI

// MARK: - SWWalletCard

/// A single payment card held inside an `SWWallet`.
public struct SWWalletCard: Identifiable {
    public let id = UUID()

    /// Wordmark shown on the card (e.g. "Stripe"). Rendered as plain bold text.
    public var name: String

    /// Card balance, summed into the wallet total.
    public var balance: Double

    /// Card background fill color.
    public var tint: Color

    /// Foreground (text) color used for the wordmark and amount.
    public var foreground: Color

    /// Create a wallet card.
    /// - Parameters:
    ///   - name: Wordmark text shown on the card
    ///   - balance: Card balance (summed into the wallet total)
    ///   - tint: Card background fill color
    ///   - foreground: Text color for wordmark and amount
    public init(name: String, balance: Double, tint: Color, foreground: Color) {
        self.name = name
        self.balance = balance
        self.tint = tint
        self.foreground = foreground
    }
}

public extension SWWalletCard {
    /// The three sample cards (Stripe / Wise / PayPal) used by `SWWallet()`.
    static var sample: [SWWalletCard] {
        [
            SWWalletCard(
                name: "stripe",
                balance: 32_495,
                tint: Color(red: 0.40, green: 0.30, blue: 0.90), // Stripe purple
                foreground: .white
            ),
            SWWalletCard(
                name: "Wise",
                balance: 45_654,
                tint: Color(red: 0.62, green: 0.93, blue: 0.43), // Wise green
                foreground: Color(red: 0.10, green: 0.16, blue: 0.10)
            ),
            SWWalletCard(
                name: "PayPal",
                balance: 345_865,
                tint: Color(red: 0.95, green: 0.96, blue: 0.97), // PayPal light
                foreground: Color(red: 0.10, green: 0.28, blue: 0.66) // PayPal blue
            )
        ]
    }
}

// MARK: - SWWallet

public struct SWWallet: View {
    // MARK: - Properties

    /// Cards tucked into the wallet, top to bottom.
    private let cards: [SWWalletCard]

    /// ISO currency code used to format amounts (e.g. "USD").
    private let currencyCode: String

    /// Wallet pouch / front-panel fill color (olive green by default).
    private let walletColor: Color

    /// Whether amounts are revealed. Starts hidden so the wallet opens "closed".
    @State private var isRevealed = false

    // MARK: - Layout Constants

    /// Overall card width.
    private let cardWidth: CGFloat = 250
    /// Overall card height (the front card; back cards are scaled down).
    private let cardHeight: CGFloat = 150
    /// Front-card top offset when collapsed — cards sit low, tucked into the
    /// pocket with only their top edges showing.
    private let collapsedBase: CGFloat = 100
    /// Front-card top offset when revealed — cards pop UP out of the pocket.
    private let revealedBase: CGFloat = 4
    /// Vertical step between card tops when collapsed — small, so the cards stay
    /// stacked but every card's top edge stays visible.
    private let hiddenStep: CGFloat = 16
    /// Vertical step between card tops when revealed — larger, so the cards fan
    /// out into a ladder.
    private let revealStep: CGFloat = 42
    /// Per-step shrink toward the back when collapsed (front card = full size).
    private let hiddenScaleStep: CGFloat = 0.05
    /// Per-step shrink toward the back when revealed (front card = full size).
    private let revealScaleStep: CGFloat = 0.11
    /// Height of the wallet front panel.
    private let pocketHeight: CGFloat = 190
    /// Fixed top offset of the wallet front panel. The wallet never moves — the
    /// cards pop up out of it when revealed.
    private let pocketTop: CGFloat = 150

    // MARK: - Initializer

    /// Create a wallet card stack.
    /// - Parameters:
    ///   - cards: Cards tucked into the wallet (top to bottom). Defaults to the
    ///     Stripe / Wise / PayPal sample set.
    ///   - currencyCode: ISO currency code used to format amounts.
    ///   - walletColor: Wallet pouch / front-panel fill color.
    public init(
        cards: [SWWalletCard] = SWWalletCard.sample,
        currencyCode: String = "USD",
        walletColor: Color = Color(red: 0.16, green: 0.21, blue: 0.09)
    ) {
        self.cards = cards
        self.currencyCode = currencyCode
        self.walletColor = walletColor
    }

    // MARK: - Derived Values

    /// Sum of every card balance, shown on the front panel when revealed.
    private var totalBalance: Double {
        cards.reduce(0) { $0 + $1.balance }
    }

    // MARK: - Body

    public var body: some View {
        ZStack(alignment: .top) {
            // 1. Card layer — cards stay visible while collapsed, then fan into a
            //    front-largest / back-smallest ladder when revealed. The front
            //    card (largest index) is full size and sits lowest; cards further
            //    back shrink and rise, so a back card never covers the one in front.
            //    Keyed by position: `SWWalletCard.id` is a fresh UUID per instance,
            //    so cards rebuilt by the caller would otherwise restart their views.
            ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                cardView(card)
                    .scaleEffect(cardScale(index), anchor: .top)
                    .offset(y: cardOffsetY(index))
                    // Larger index = nearer the front, so it draws on top.
                    .zIndex(Double(index))
                    // Per-card bounce with an increasing delay → "pop out one by one".
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.62)
                            .delay(Double(index) * 0.07),
                        value: isRevealed
                    )
            }

            // 2. Wallet front panel — fixed in place. It always covers the lower
            //    part of the cards; the cards pop up out of it when revealed.
            pocketFront
                .offset(y: pocketTop)
                .zIndex(Double(cards.count) + 10)
        }
        .frame(width: cardWidth + 40, height: pocketTop + pocketHeight + 10)
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Card Layout

    /// Vertical position of a card's top edge. Index increases toward the front,
    /// so the front card sits lowest. When revealed the whole stack moves UP out
    /// of the (fixed) pocket and fans out with a larger step.
    private func cardOffsetY(_ index: Int) -> CGFloat {
        let base = isRevealed ? revealedBase : collapsedBase
        let step = isRevealed ? revealStep : hiddenStep
        return base + CGFloat(index) * step
    }

    /// Scale of a card. The front card (largest index) is full size; each step
    /// toward the back shrinks the card, so a back card can't cover the card in
    /// front of it.
    private func cardScale(_ index: Int) -> CGFloat {
        let backness = CGFloat(cards.count - 1 - index)
        return 1.0 - backness * (isRevealed ? revealScaleStep : hiddenScaleStep)
    }

    // MARK: - Card View

    /// A single payment card: wordmark top-left, amount top-right.
    private func cardView(_ card: SWWalletCard) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(card.tint)
            .frame(width: cardWidth, height: cardHeight)
            .overlay(alignment: .topLeading) {
                HStack {
                    // Wordmark — plain bold text, no brand logo image assets.
                    Text(card.name)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(card.foreground)

                    Spacer()

                    // Amount — bullets when hidden, real figure when revealed.
                    Text(amountText(card.balance))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(card.foreground.opacity(0.85))
                        .contentTransition(.numericText())
                }
                .padding(18)
            }
            .overlay(
                // Subtle inner edge so cards read as distinct when overlapping.
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
    }

    // MARK: - Pocket Front Panel

    private var pocketFront: some View {
        ZStack {
            // Pocket shape — small top corners, large bottom corners → pouch feel.
            UnevenRoundedRectangle(
                topLeadingRadius: 14,
                bottomLeadingRadius: 40,
                bottomTrailingRadius: 40,
                topTrailingRadius: 14,
                style: .continuous
            )
            .fill(walletColor)
            .shadow(color: .black.opacity(0.20), radius: 10, x: 0, y: 6)

            // White dashed stitching inset a few points from the edge.
            UnevenRoundedRectangle(
                topLeadingRadius: 10,
                bottomLeadingRadius: 34,
                bottomTrailingRadius: 34,
                topTrailingRadius: 10,
                style: .continuous
            )
            .stroke(
                .white.opacity(0.22),
                style: StrokeStyle(lineWidth: 1, dash: [4, 3])
            )
            .padding(6)

            // Panel content: total balance, caption, and the eye toggle.
            VStack(spacing: 6) {
                Spacer(minLength: 12)

                Text(totalText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .monospacedDigit()

                Text("Total Balance")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer(minLength: 8)

                // Eye toggle — flips the whole wallet between hidden / revealed.
                Button {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
                        isRevealed.toggle()
                    }
                } label: {
                    Image(systemName: isRevealed ? "eye" : "eye.slash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRevealed ? "Hide Balances" : "Show Balances")
                .padding(.bottom, 14)
            }
            .padding(.horizontal, 20)
        }
        .frame(width: cardWidth + 40, height: pocketHeight)
    }

    // MARK: - Formatting

    /// Bullets when hidden, otherwise the grouped total balance figure.
    private var totalText: String {
        isRevealed
            ? totalBalance.formatted(.currency(code: currencyCode).precision(.fractionLength(0)))
            : "••••••"
    }

    /// Bullets when hidden, otherwise a single card's grouped amount.
    private func amountText(_ value: Double) -> String {
        isRevealed
            ? value.formatted(.currency(code: currencyCode).precision(.fractionLength(0)))
            : "••••"
    }
}

// MARK: - Preview

#Preview {
    SWWallet()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.93, green: 0.94, blue: 0.91))
}
