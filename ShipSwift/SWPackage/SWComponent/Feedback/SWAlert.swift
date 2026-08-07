//
//  SWAlert.swift
//  ShipSwift
//
//  Global alert overlay that displays toast-style notifications at the top of
//  the screen. Supports four preset styles (info, success, warning, error)
//  and fully custom styling. Auto-dismisses after a configurable duration.
//
//  Presentation (2026-08-07): on iOS the toast renders in a dedicated
//  top-level UIWindow (windowLevel = .alert + 1, hit-test passthrough), so it
//  is never covered by sheets or fullScreenCovers — alerts fired from inside
//  a sheet show instantly, no need to wait for the dismiss animation.
//  On macOS it stays a root-view overlay (no full-screen sheet occlusion there).
//  Public API is unchanged.
//
//  Usage:
//    1. Attach the modifier at your App entry point (once):
//
//       @main
//       struct MyApp: App {
//           var body: some Scene {
//               WindowGroup {
//                   ContentView()
//                       .swAlert()
//               }
//           }
//       }
//
//    2. Show an alert from anywhere using the singleton:
//
//       // Preset types: .info, .success, .warning, .error
//       SWAlertManager.shared.show(.success, message: "Saved!")
//       SWAlertManager.shared.show(.error, message: "Something went wrong")
//
//       // With custom duration
//       SWAlertManager.shared.show(.warning, message: "Slow connection", duration: .seconds(5))
//
//       // Dynamic string (e.g. from API error)
//       SWAlertManager.shared.show(.error, message: errorString)
//
//       // Fully custom style
//       SWAlertManager.shared.show(
//           icon: "star.fill",
//           message: "Custom alert",
//           textColor: .yellow,
//           backgroundStyle: AnyShapeStyle(.black),
//           borderColor: .yellow
//       )
//
//    3. Dismiss programmatically (optional — alerts auto-dismiss):
//
//       SWAlertManager.shared.dismiss()
//
//  SWAlertType cases:
//    .info    — blue info circle icon, primary text color
//    .success — green checkmark icon, green text color
//    .warning — orange triangle icon, orange text color
//    .error   — red x-mark icon, red text color
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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

// MARK: - Top-Level Window Host (iOS)

#if canImport(UIKit)
/// Passthrough window: only the toast itself receives touches;
/// everything else falls through to the windows below.
private final class SWAlertPassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        // The hosting controller's container view itself = empty area → pass through
        return view == rootViewController?.view ? nil : view
    }
}

/// Dedicated top-level window (windowLevel above system alerts) so sheets and
/// fullScreenCovers can never cover the toast. Mounted once, app-lifetime.
@MainActor
private enum SWAlertWindowHost {
    static var window: UIWindow?

    static func mountIfNeeded() {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first(where: { $0.activationState == .foregroundActive })
                  ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }
        let host = UIHostingController(rootView: SWAlertOverlayRoot())
        host.view.backgroundColor = .clear
        let window = SWAlertPassthroughWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false
        self.window = window
    }
}

/// Root view inside the dedicated window: reads the singleton, top-aligned.
private struct SWAlertOverlayRoot: View {
    let alertManager = SWAlertManager.shared

    var body: some View {
        VStack {
            SWAlertView()
                .padding(.top, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(duration: 0.3), value: alertManager.isShowing)
    }
}
#endif

// MARK: - View Modifier

private struct SWAlertModifier: ViewModifier {
    let alertManager = SWAlertManager.shared

    func body(content: Content) -> some View {
        #if canImport(UIKit)
        // iOS: render in a dedicated top-level window — never covered by
        // sheets/fullScreenCovers, no need to delay until dismiss animations end.
        content
            .onAppear { SWAlertWindowHost.mountIfNeeded() }
        #else
        // macOS: keep the root-view overlay (sheets attach inside the window
        // there, so full-screen occlusion is not a concern).
        content
            .overlay(alignment: .top) {
                SWAlertView()
                    .padding(.top, 40)
            }
            .animation(.spring(duration: 0.3), value: alertManager.isShowing)
        #endif
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

#Preview {
    VStack(spacing: 20) {
        Button("Info") {
            SWAlertManager.shared.show(.info, message: "This is an info message")
        }
        .buttonStyle(.bordered)
        
        Button("Success") {
            SWAlertManager.shared.show(.success, message: "Saved successfully")
        }
        .buttonStyle(.bordered)

        Button("Warning") {
            SWAlertManager.shared.show(.warning, message: "Slow connection")
        }
        .buttonStyle(.bordered)

        Button("Error") {
            SWAlertManager.shared.show(.error, message: "Operation failed, please retry")
        }
        .buttonStyle(.bordered)

        Button("Custom") {
            SWAlertManager.shared.show(
                icon: "star.fill",
                message: "Custom alert style",
                textColor: .yellow,
                backgroundStyle: AnyShapeStyle(.black),
                borderColor: .yellow
            )
        }
        .buttonStyle(.bordered)
    }
    .font(.headline)
    .frame(maxWidth: .infinity)
    .swAlert()
}
