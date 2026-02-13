//
//  SWLoading.swift
//  ShipSwift
//
//  Page-level fullscreen loading overlay with blur material background,
//  customizable message text, optional SF Symbol icon with pulse animation,
//  and a progress indicator. Each page has independent loading state managed
//  through the SWLoadingPage enum.
//
//  Usage:
//    1. Register your pages in the SWLoadingPage enum:
//
//       enum SWLoadingPage: String {
//           case home
//           case settings
//           case profile
//       }
//
//    2. Attach the modifier to the view that should show the overlay:
//
//       var body: some View {
//           MyPageContent()
//               .swPageLoading(.home)
//       }
//
//    3. Show / update / hide from anywhere via the singleton:
//
//       // Show with default message
//       SWLoadingManager.shared.show(page: .home)
//
//       // Show with custom message and icon
//       SWLoadingManager.shared.show(
//           page: .home,
//           message: "Syncing data...",
//           systemImage: "arrow.triangle.2.circlepath"
//       )
//
//       // Update the message while loading
//       SWLoadingManager.shared.updateMessage(page: .home, message: "Almost done...")
//
//       // Hide the overlay
//       SWLoadingManager.shared.hide(page: .home)
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

// MARK: - Page Loading State

/// Represents the loading state for a specific page
struct SWPageLoadingState {
    var isShowing: Bool = false
    var message: String = "Loading..."
    var systemImage: String? = nil
}

// MARK: - Page Identifier

/// Page identifier enum - Add your page cases here
enum SWLoadingPage: String {
    case home
    case settings
    case profile
    // Add more pages as needed
}

// MARK: - SWLoadingManager

@MainActor
@Observable
final class SWLoadingManager {
    static let shared = SWLoadingManager()

    private var pageStates: [SWLoadingPage: SWPageLoadingState] = [:]

    private init() {}

    // MARK: - Page-level Loading

    /// Show page loading overlay
    func show(page: SWLoadingPage, message: String = "Loading...", systemImage: String? = nil) {
        pageStates[page] = SWPageLoadingState(isShowing: true, message: message, systemImage: systemImage)
    }

    /// Update page loading message
    func updateMessage(page: SWLoadingPage, message: String) {
        pageStates[page]?.message = message
    }

    /// Hide page loading overlay
    func hide(page: SWLoadingPage) {
        pageStates[page]?.isShowing = false
    }

    /// Get page loading state
    func state(for page: SWLoadingPage) -> SWPageLoadingState {
        pageStates[page] ?? SWPageLoadingState()
    }
}

// MARK: - Page Loading View

struct SWPageLoadingView: View {
    let page: SWLoadingPage

    private var state: SWPageLoadingState {
        SWLoadingManager.shared.state(for: page)
    }

    var body: some View {
        if state.isShowing {
            VStack(spacing: 24) {
                // Icon
                if let systemImage = state.systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.primary.opacity(0.8))
                        .symbolEffect(.pulse, options: .repeating)
                }

                // Message + progress indicator
                VStack(spacing: 12) {
                    Text(state.message)
                        .font(.headline)
                        .foregroundStyle(.primary.opacity(0.9))
                        .multilineTextAlignment(.center)

                    ProgressView()
                        .tint(.primary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThinMaterial)
            .ignoresSafeArea(.all)
            .transition(.opacity)
        }
    }
}

// MARK: - View Modifier

private struct SWPageLoadingModifier: ViewModifier {
    let page: SWLoadingPage

    private var state: SWPageLoadingState {
        SWLoadingManager.shared.state(for: page)
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                SWPageLoadingView(page: page)
            }
            .animation(.easeInOut(duration: 0.25), value: state.isShowing)
    }
}

// MARK: - View Extension

extension View {
    /// Add page-level loading support (fullscreen blur overlay)
    func swPageLoading(_ page: SWLoadingPage) -> some View {
        modifier(SWPageLoadingModifier(page: page))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Page Content")
                .font(.largeTitle)
                .foregroundStyle(.white)

            Button("Show Default Loading") {
                SWLoadingManager.shared.show(page: .home, message: "Loading data...")
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    SWLoadingManager.shared.hide(page: .home)
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Show Loading with Icon") {
                SWLoadingManager.shared.show(
                    page: .home,
                    message: "Syncing data...",
                    systemImage: "arrow.triangle.2.circlepath"
                )
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    SWLoadingManager.shared.hide(page: .home)
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Hide Loading") {
                SWLoadingManager.shared.hide(page: .home)
            }
            .buttonStyle(.bordered)
        }
    }
    .swPageLoading(.home)
}
