import SwiftUI

struct SWButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
    }

    @Environment(\.isEnabled) private var isEnabled

    let variant: Variant
    var showBorder: Bool = false
    var cornerRadius: CGFloat = SWRadius.card

    private var backgroundColor: Color {
        switch variant {
        case .primary: .accentColor
        case .secondary: .swSecondaryButtonBackground
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: .white
        case .secondary: .primary
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary: .accentColor.opacity(0.16)
        case .secondary: .swCardBorder
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor.opacity(configuration.isPressed ? 0.92 : 1))
            )
            .foregroundStyle(foregroundColor.opacity(isEnabled ? 1 : 0.7))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(showBorder ? borderColor : .clear, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed && isEnabled ? 0.99 : 1)
            .opacity(isEnabled ? 1 : 0.55)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SWButtonStyle {
    static var swPrimary: SWButtonStyle { .init(variant: .primary, showBorder: false, cornerRadius: SWRadius.card) }
    static var swSecondary: SWButtonStyle { .init(variant: .secondary, showBorder: true, cornerRadius: SWRadius.card) }

    static func swPrimary(showBorder: Bool = false, cornerRadius: CGFloat = SWRadius.card) -> SWButtonStyle {
        .init(variant: .primary, showBorder: showBorder, cornerRadius: cornerRadius)
    }

    static func swSecondary(showBorder: Bool = true, cornerRadius: CGFloat = SWRadius.card) -> SWButtonStyle {
        .init(variant: .secondary, showBorder: showBorder, cornerRadius: cornerRadius)
    }
}

// MARK: - Design Tokens

/// Spacing scale. Use these instead of inline magic numbers so the app
/// keeps one rhythm. New numbers should be added here first, not at callsites.
enum SWSpacing {
    static let pageBottomInset: CGFloat = 32
    static let sectionGap: CGFloat = 24
    static let cardPadding: CGFloat = 16
    static let iconTitleGap: CGFloat = 8
    static let titleDescriptionGap: CGFloat = 6
}

/// Radius scale, compressed to three tiers to stop 8 / 12 / 16 mixing.
enum SWRadius {
    static let small: CGFloat = 10
    static let card: CGFloat = 14
    static let large: CGFloat = 18
}

extension Font {
    /// Section header inside a page (above grouped content).
    static let swSectionTitle: Font = .title3.weight(.semibold)
    /// Card / row title.
    static let swCardTitle: Font = .headline
    /// Body / description text.
    static let swBody: Font = .subheadline
    /// Meta / caption text. Pair with `.foregroundStyle(.secondary)`.
    static let swMeta: Font = .caption
}

extension Color {
    static var swAccentCardBackground: Color {
        .accentColor.opacity(0.08)
    }

    static var swCardBorder: Color {
        .primary.opacity(0.08)
    }

    static var swCardBackground: Color {
        #if canImport(UIKit)
        Color(UIColor.secondarySystemGroupedBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }

    static var swSecondaryButtonBackground: Color {
        #if canImport(UIKit)
        Color(UIColor.secondarySystemBackground)
        #else
        Color(NSColor.windowBackgroundColor)
        #endif
    }
}

extension View {
    func swCardStyle(
        background: Color = .swCardBackground,
        borderColor: Color = .swCardBorder,
        cornerRadius: CGFloat = SWRadius.card,
        padding: CGFloat = SWSpacing.cardPadding
    ) -> some View {
        self
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    func swAccentCardStyle(
        cornerRadius: CGFloat = SWRadius.card,
        padding: CGFloat = SWSpacing.cardPadding
    ) -> some View {
        swCardStyle(
            background: .swAccentCardBackground,
            borderColor: .accentColor.opacity(0.12),
            cornerRadius: cornerRadius,
            padding: padding
        )
    }
}

#Preview("Button Styles") {
    VStack(spacing: 20) {
        Button("Primary Button") { }
            .buttonStyle(.swPrimary)

        Button("Secondary Button") { }
            .buttonStyle(.swSecondary)

        Button("Disabled") { }
            .buttonStyle(.swPrimary)
            .disabled(true)
    }
    .padding()
}

#Preview("Card Styles") {
    VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Standard Card")
                .font(.headline)
            Text("Use this for default surfaces across the app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .swCardStyle()

        VStack(alignment: .leading, spacing: 8) {
            Text("Accent Card")
                .font(.headline)
            Text("Use this for the occasional high-emphasis section.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .swAccentCardStyle()
    }
    .padding()
}
