//
//  slLoading.swift
//  ShipSwift
//
//  Created by Claude on 2026/1/5.
//  Copyright © 2026 Signer Labs. All rights reserved.
//
//  ============================================================
//  Page-level Loading View - Fullscreen blur overlay
//  ============================================================
//
//  Usage:
//  1. Add .slPageLoading(.home) to your view
//  2. Show: slLoadingManager.shared.show(page: .home, message: "...", systemImage: "...")
//  3. Hide: slLoadingManager.shared.hide(page: .home)
//
//  ============================================================

import SwiftUI

// MARK: - Page Loading View

struct slPageLoadingView: View {
    let page: slLoadingPage

    private var state: slPageLoadingState {
        slLoadingManager.shared.state(for: page)
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

                // Message + Progress indicator
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

private struct slPageLoadingModifier: ViewModifier {
    let page: slLoadingPage

    private var state: slPageLoadingState {
        slLoadingManager.shared.state(for: page)
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                slPageLoadingView(page: page)
            }
            .animation(.easeInOut(duration: 0.25), value: state.isShowing)
    }
}

// MARK: - View Extension

extension View {
    /// Add page-level Loading support (fullscreen blur overlay)
    func slPageLoading(_ page: slLoadingPage) -> some View {
        modifier(slPageLoadingModifier(page: page))
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
    .slPageLoading(.home)
    .onAppear {
        slLoadingManager.shared.show(page: .home, message: "Loading data...")
    }
}

#Preview("Page Loading - With Icon") {
    ZStack {
        Color.gray.opacity(0.2)
        Text("Content")
    }
    .slPageLoading(.settings)
    .onAppear {
        slLoadingManager.shared.show(
            page: .settings,
            message: "Syncing data...",
            systemImage: "arrow.triangle.2.circlepath"
        )
    }
}

#Preview("Page Loading - AI Analysis") {
    ZStack {
        Color.gray.opacity(0.2)
        Text("Content")
    }
    .slPageLoading(.profile)
    .onAppear {
        slLoadingManager.shared.show(
            page: .profile,
            message: "AI analyzing...",
            systemImage: "sparkles"
        )
    }
}
