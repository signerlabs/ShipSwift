//
//  SWRotatingQuote.swift
//  ShipSwift
//
//  Auto-rotating quote display that cycles through an array of quotes with animated
//  transitions. Shows the quote text and an author name aligned to the bottom-right.
//  Uses a hidden placeholder of the longest quote to maintain stable layout height.
//
//  Usage:
//    // Basic usage — multiple quotes rotation
//    SWRotatingQuote(
//        quotes: [
//            "Stay hungry, stay foolish.",
//            "The only way to do great work is to love what you do.",
//            "Innovation distinguishes between a leader and a follower."
//        ],
//        author: "Steve Jobs"
//    )
//
//    // Custom font, interval, and color
//    SWRotatingQuote(
//        quotes: [
//            "Those times when you get up early...",
//            "That is actually the dream."
//        ],
//        author: "Kobe Bryant",
//        interval: 3.0,
//        quoteFont: .body,
//        authorFont: .callout,
//        fontDesign: .serif,
//        foregroundStyle: .primary
//    )
//
//    // Single quote (no rotation, displayed statically)
//    SWRotatingQuote(
//        quotes: ["Stay hungry, stay foolish."],
//        author: "Steve Jobs"
//    )
//
//  Parameters:
//    - quotes: [LocalizedStringResource]  — Array of quotes (at least 1)
//    - author: LocalizedStringResource    — Author name
//    - interval: TimeInterval             — Rotation interval in seconds (default 5.0)
//    - quoteFont: Font                    — Quote font (default .subheadline)
//    - authorFont: Font                   — Author font (default .headline)
//    - fontDesign: Font.Design            — Font design (default .rounded)
//    - foregroundStyle: Color             — Text color (default .secondary)
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

/// A component that rotates through multiple quote texts, supporting custom author and rotation interval
struct SWRotatingQuote: View {

    // MARK: - Configuration

    /// Array of quote texts
    let quotes: [LocalizedStringResource]

    /// Author name (displayed at bottom-right)
    let author: LocalizedStringResource

    /// Text rotation interval (seconds)
    let interval: TimeInterval

    /// Quote text font
    let quoteFont: Font

    /// Author font
    let authorFont: Font

    /// Font design
    let fontDesign: Font.Design

    /// Text color
    let foregroundStyle: Color

    // MARK: - State

    @State private var currentTextIndex = 0
    @State private var textRotationTimer: Timer?

    // MARK: - Initializer

    /// Creates a rotating quote text component
    /// - Parameters:
    ///   - quotes: Array of quote texts (at least 1 required)
    ///   - author: Author name
    ///   - interval: Text rotation interval, default 5 seconds
    ///   - quoteFont: Quote text font, default .subheadline
    ///   - authorFont: Author font, default .headline
    ///   - fontDesign: Font design, default .rounded
    ///   - foregroundStyle: Text color, default .secondary
    init(
        quotes: [LocalizedStringResource],
        author: LocalizedStringResource,
        interval: TimeInterval = 5.0,
        quoteFont: Font = .subheadline,
        authorFont: Font = .headline,
        fontDesign: Font.Design = .rounded,
        foregroundStyle: Color = .secondary
    ) {
        self.quotes = quotes
        self.author = author
        self.interval = interval
        self.quoteFont = quoteFont
        self.authorFont = authorFont
        self.fontDesign = fontDesign
        self.foregroundStyle = foregroundStyle
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Hidden placeholder text using the longest quote to determine height
            VStack(alignment: .leading) {
                Text(longestQuote)
                    .font(quoteFont)
                    .contentTransition(.numericText())

                Spacer()

                HStack {
                    Spacer()

                    Text(author)
                        .font(authorFont)
                }
            }
            .opacity(0)

            // Actual displayed content
            VStack(alignment: .leading) {
                Text(quotes[safe: currentTextIndex] ?? quotes[0])
                    .font(quoteFont)
                    .contentTransition(.numericText())

                Spacer()

                HStack {
                    Spacer()

                    Text(author)
                        .font(authorFont)
                }
            }
            .foregroundStyle(foregroundStyle)
        }
        .fontDesign(fontDesign)
        .onAppear { startTextRotation() }
        .onDisappear { stopTextRotation() }
    }

    // MARK: - Helper Properties

    /// Find the longest quote text (used for placeholder)
    private var longestQuote: LocalizedStringResource {
        quotes.max { quote1, quote2 in
            String(localized: quote1).count < String(localized: quote2).count
        } ?? quotes[0]
    }

    // MARK: - Timer Management

    private func startTextRotation() {
        // No rotation needed if there is only one quote
        guard quotes.count > 1 else { return }

        // Invalidate any previous timer
        textRotationTimer?.invalidate()

        textRotationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                withAnimation {
                    let maxIndex = quotes.count - 1
                    currentTextIndex = (currentTextIndex + 1) % (maxIndex + 1)
                }
            }
        }
    }

    private func stopTextRotation() {
        textRotationTimer?.invalidate()
        textRotationTimer = nil
    }
}

// MARK: - Array Safe Access Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 32) {
            // Multiple quotes rotation
            List {
                Section {
                    SWRotatingQuote(
                        quotes: [
                            "Those times when you get up early, and you work hard, those times when you stay up late, and you work hard.",
                            "Those times when you don't feel like working, you're too tired, you don't want to push yourself, but you do it anyway.",
                            "That is actually the dream.\n It's not the destination, it's the journey."
                        ],
                        author: "Kobe Bryant"
                    )
                }
                .listRowBackground(Color.clear)
            }
            .frame(height: 200)

            Divider()

            // Single quote (no rotation)
            List {
                Section {
                    SWRotatingQuote(
                        quotes: [
                            "Stay hungry, stay foolish."
                        ],
                        author: "Steve Jobs",
                        quoteFont: .title3,
                        authorFont: .title2
                    )
                }
                .listRowBackground(Color.clear)
            }
            .frame(height: 200)

            Divider()

            // Custom style
            List {
                Section {
                    SWRotatingQuote(
                        quotes: [
                            "The only way to do great work is to love what you do.",
                            "Innovation distinguishes between a leader and a follower.",
                            "Your time is limited, don't waste it living someone else's life."
                        ],
                        author: "Steve Jobs",
                        interval: 3.0,
                        quoteFont: .body,
                        authorFont: .callout,
                        fontDesign: .serif,
                        foregroundStyle: .primary
                    )
                }
                .listRowBackground(Color.clear)
            }
            .frame(height: 200)
        }
    }
}
