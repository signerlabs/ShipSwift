//
//  SWLoading.swift
//  ShipSwift
//
//  Page-level loading manager + view component (self-contained)
//
//  ============================================================
//  Page-level Loading Manager
//  ============================================================
//
//  Usage:
//  1. Add .swPageLoading(.home) modifier to your view
//  2. Show: SWLoadingManager.shared.show(page: .home, message: "Loading...")
//  3. Hide: SWLoadingManager.shared.hide(page: .home)
//
//  Example:
//
//     struct HomeView: View {
//         var body: some View {
//             content
//                 .swPageLoading(.home)
//         }
//
//         func fetchData() async {
//             SWLoadingManager.shared.show(page: .home, message: "Loading...")
//             defer { SWLoadingManager.shared.hide(page: .home) }
//
//             do {
//                 let data = try await api.fetchData()
//                 // handle data...
//             } catch {
//                 // handle error...
//             }
//         }
//     }
//
//  ============================================================

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

#Preview("Page Loading - Default") {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        Text("Page Content")
            .font(.largeTitle)
            .foregroundStyle(.white)
    }
    .swPageLoading(.home)
    .onAppear {
        SWLoadingManager.shared.show(page: .home, message: "Loading data...")
    }
}

#Preview("Page Loading - With Icon") {
    ZStack {
        Color.gray.opacity(0.2)
        Text("Content")
    }
    .swPageLoading(.settings)
    .onAppear {
        SWLoadingManager.shared.show(
            page: .settings,
            message: "Syncing data...",
            systemImage: "arrow.triangle.2.circlepath"
        )
    }
}
