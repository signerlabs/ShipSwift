//
//  slLoadingManager.swift
//  ShipSwift
//
//  Created by Claude on 2026/1/5.
//  Copyright © 2026 Signer Labs. All rights reserved.
//
//  ============================================================
//  Page-level Loading Manager
//  ============================================================
//
//  Usage:
//  1. Add .slPageLoading(.home) modifier to your view
//  2. Show: slLoadingManager.shared.show(page: .home, message: "Loading...")
//  3. Hide: slLoadingManager.shared.hide(page: .home)
//
//  Example:
//
//     struct HomeView: View {
//         var body: some View {
//             content
//                 .slPageLoading(.home)
//         }
//
//         func fetchData() async {
//             slLoadingManager.shared.show(page: .home, message: "Loading...")
//             defer { slLoadingManager.shared.hide(page: .home) }
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

/// Page Loading State
struct slPageLoadingState {
    var isShowing: Bool = false
    var message: String = "Loading..."
    var systemImage: String? = nil
}

/// Page Identifier - Add your page cases here
enum slLoadingPage: String {
    case home
    case settings
    case profile
    // Add more pages as needed
}

@MainActor
@Observable
final class slLoadingManager {
    static let shared = slLoadingManager()

    // Page-level Loading states
    private var pageStates: [slLoadingPage: slPageLoadingState] = [:]

    private init() {}

    // MARK: - Page-level Loading

    /// Show page Loading
    func show(page: slLoadingPage, message: String = "Loading...", systemImage: String? = nil) {
        pageStates[page] = slPageLoadingState(isShowing: true, message: message, systemImage: systemImage)
    }

    /// Update page Loading message
    func updateMessage(page: slLoadingPage, message: String) {
        pageStates[page]?.message = message
    }

    /// Hide page Loading
    func hide(page: slLoadingPage) {
        pageStates[page]?.isShowing = false
    }

    /// Get page Loading state
    func state(for page: slLoadingPage) -> slPageLoadingState {
        pageStates[page] ?? slPageLoadingState()
    }
}
