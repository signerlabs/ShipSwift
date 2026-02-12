//
//  SWAlert.swift
//  ShipSwift
//
//  Global alert manager + view component (self-contained)
//
//  ============================================================
//  Global Alert Manager
//  ============================================================
//
//  Usage:
//  1. Add .swAlert() modifier at the App entry point:
//
//     @main
//     struct MyApp: App {
//         var body: some Scene {
//             WindowGroup {
//                 ContentView()
//                     .swAlert()
//             }
//         }
//     }
//
//  2. Show alerts from anywhere:
//
//     // Preset types (recommended)
//     SWAlertManager.shared.show(.success, message: "Saved successfully")
//     SWAlertManager.shared.show(.error, message: "Operation failed")
//
//     // LocalizedStringKey (recommended for static text, auto-extracted to String Catalog)
//     SWAlertManager.shared.show(.success, message: MyAlertMessage.saveSuccess)
//
//     // Custom style
//     SWAlertManager.shared.show(
//         icon: "star.fill",
//         message: "Custom message",
//         textColor: .yellow,
//         duration: .seconds(3)
//     )
//
//     // Manual dismiss
//     SWAlertManager.shared.dismiss()
//
//  Preset types:
//  - .info    : Informational (primary color)
//  - .success : Green success
//  - .warning : Orange warning
//  - .error   : Red error
//
//  Localization best practice:
//  Create a message enum in your project for Xcode String Catalog auto-extraction:
//
//     enum MyAlertMessage {
//         static let saveSuccess: LocalizedStringKey = "Saved successfully"
//         static let saveFailed: LocalizedStringKey = "Save failed"
//     }
//
//     SWAlertManager.shared.show(.success, message: MyAlertMessage.saveSuccess)
//
//  ============================================================

import SwiftUI

// MARK: - SWAlertType

enum SWAlertType {
    case info
    case success
    case warning
    case error

    var icon: String {
        switch self {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.circle.fill"
        }
    }

    var textColor: Color {
        switch self {
        case .info: .primary
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }

    var backgroundStyle: AnyShapeStyle {
        AnyShapeStyle(.ultraThinMaterial)
    }

    var borderColor: Color {
        switch self {
        case .info: .secondary.opacity(0.6)
        case .success: .green.opacity(0.6)
        case .warning: .orange.opacity(0.6)
        case .error: .red.opacity(0.6)
        }
    }
}

// MARK: - SWAlertManager

@MainActor
@Observable
final class SWAlertManager {
    static let shared = SWAlertManager()

    // MARK: - State

    private(set) var isShowing = false
    private(set) var icon = SWAlertType.info.icon
    private(set) var message: LocalizedStringKey = ""
    private(set) var textColor = SWAlertType.info.textColor
    private(set) var backgroundStyle = SWAlertType.info.backgroundStyle
    private(set) var borderColor = SWAlertType.info.borderColor

    private var dismissTask: Task<Void, Never>?

    private init() {}

    // MARK: - Public Methods (LocalizedStringKey)

    /// Show alert with preset type (LocalizedStringKey, recommended for static text)
    func show(_ type: SWAlertType, message: LocalizedStringKey, duration: Duration = .seconds(2)) {
        showInternal(
            icon: type.icon,
            message: message,
            textColor: type.textColor,
            backgroundStyle: type.backgroundStyle,
            borderColor: type.borderColor,
            duration: duration
        )
    }

    /// Show alert with custom style (LocalizedStringKey)
    func show(
        icon: String,
        message: LocalizedStringKey,
        textColor: Color = .white,
        backgroundStyle: AnyShapeStyle = AnyShapeStyle(.black),
        borderColor: Color = .secondary,
        duration: Duration = .seconds(2)
    ) {
        showInternal(
            icon: icon,
            message: message,
            textColor: textColor,
            backgroundStyle: backgroundStyle,
            borderColor: borderColor,
            duration: duration
        )
    }

    // MARK: - Public Methods (String)

    /// Show alert with preset type (String, for dynamic text like API errors)
    func show(_ type: SWAlertType, message: String, duration: Duration = .seconds(2)) {
        showInternal(
            icon: type.icon,
            message: LocalizedStringKey(message),
            textColor: type.textColor,
            backgroundStyle: type.backgroundStyle,
            borderColor: type.borderColor,
            duration: duration
        )
    }

    /// Show alert with custom style (String)
    func show(
        icon: String,
        message: String,
        textColor: Color = .white,
        backgroundStyle: AnyShapeStyle = AnyShapeStyle(.black),
        borderColor: Color = .secondary,
        duration: Duration = .seconds(2)
    ) {
        showInternal(
            icon: icon,
            message: LocalizedStringKey(message),
            textColor: textColor,
            backgroundStyle: backgroundStyle,
            borderColor: borderColor,
            duration: duration
        )
    }

    // MARK: - Internal

    private func showInternal(
        icon: String,
        message: LocalizedStringKey,
        textColor: Color,
        backgroundStyle: AnyShapeStyle,
        borderColor: Color,
        duration: Duration
    ) {
        dismissTask?.cancel()

        self.icon = icon
        self.message = message
        self.textColor = textColor
        self.backgroundStyle = backgroundStyle
        self.borderColor = borderColor

        withAnimation { isShowing = true }

        dismissTask = Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            withAnimation { isShowing = false }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation { isShowing = false }
    }
}

// MARK: - Alert View

private struct SWAlertView: View {
    let alertManager = SWAlertManager.shared

    var body: some View {
        if alertManager.isShowing {
            HStack(spacing: 6) {
                Image(systemName: alertManager.icon)
                    .font(.footnote)
                Text(alertManager.message)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(alertManager.textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(alertManager.backgroundStyle)
                    .strokeBorder(alertManager.borderColor, lineWidth: 0.5)
            }
            .transition(.scale.combined(with: .opacity))
            .onTapGesture { alertManager.dismiss() }
        }
    }
}

// MARK: - View Modifier

private struct SWAlertModifier: ViewModifier {
    let alertManager = SWAlertManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                SWAlertView()
                    .padding(.top, 40)
            }
            .animation(.spring(duration: 0.3), value: alertManager.isShowing)
    }
}

// MARK: - View Extension

extension View {
    /// Add global alert support
    ///
    /// Use at the App entry point:
    /// ```swift
    /// @main
    /// struct MyApp: App {
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///                 .swAlert()
    ///         }
    ///     }
    /// }
    /// ```
    func swAlert() -> some View {
        modifier(SWAlertModifier())
    }
}

// MARK: - Preview

#Preview("Info") {
    Color.gray
        .ignoresSafeArea()
        .swAlert()
        .onAppear {
            SWAlertManager.shared.show(.info, message: "This is an info message")
        }
}

#Preview("Success") {
    Color.gray
        .ignoresSafeArea()
        .swAlert()
        .onAppear {
            SWAlertManager.shared.show(.success, message: "Saved successfully")
        }
}

#Preview("Error") {
    Color.gray
        .ignoresSafeArea()
        .swAlert()
        .onAppear {
            SWAlertManager.shared.show(.error, message: "Operation failed, please retry")
        }
}
