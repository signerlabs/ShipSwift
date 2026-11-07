//
//  SWOnboardingView.swift
//  ShipSwift
//
//  Multi-page onboarding view with swipe-to-navigate support, a "Continue / Get Started"
//  button and a "Skip" button at the bottom. Page content is defined by the SWOnboardingPage
//  enum (icon / title / description) — add or remove cases freely.
//
//  Usage:
//    // 1. Present the onboarding at app launch or first run; handle completion/skip via onComplete:
//    SWOnboardingView(onComplete: {
//        hasSeenOnboarding = true
//    })
//
//    // 2. Customize pages: modify the SWOnboardingPage enum, add/remove cases and provide icon / title / description:
//    enum SWOnboardingPage: CaseIterable {
//        case shipFast
//        case components
//        case modular
//        case launch
//        // To add a new page, simply add a case and implement the three computed properties
//    }
//
//    // 3. Use with fullScreenCover:
//    .fullScreenCover(isPresented: $showOnboarding) {
//        SWOnboardingView(onComplete: { showOnboarding = false })
//    }
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

// MARK: - Onboarding Main View
struct SWOnboardingView: View {
    let onComplete: () -> Void

    private let pages = SWOnboardingPage.allCases
    @State private var currentPage = 0

    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: 80))
                            .foregroundStyle(.tint)
                        Text(page.title)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(page.description)
                            .foregroundStyle(.secondary)

                        Spacer()
                        Spacer()
                    }
                    .tag(index)
                    .padding(.horizontal)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            #endif

            // Bottom confirm button
            Button {
                if !isLastPage {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onComplete()
                }
            } label: {
                Text(isLastPage ? "Get Started" : "Continue")
            }
            .buttonStyle(.swPrimary)
            .padding(.horizontal)
            .padding(.bottom)

            // Bottom skip button (hidden on the last page, where the main button finishes)
            Button {
                onComplete()
            } label: {
                Text("Skip")
                    .foregroundStyle(.secondary)
            }
            .opacity(isLastPage ? 0 : 1)
            .disabled(isLastPage)
            .accessibilityHidden(isLastPage)
        }
    }
}

// MARK: - Onboarding Page Model
enum SWOnboardingPage: CaseIterable {
    case shipFast
    case components
    case modular
    case launch

    var icon: String {
        switch self {
        case .shipFast: "cpu.fill"
        case .components: "doc.text.fill"
        case .modular: "terminal.fill"
        case .launch: "paperplane.fill"
        }
    }

    var title: String {
        switch self {
        case .shipFast: "AI-First Development"
        case .components: "Production-Ready Skills"
        case .modular: "One Command Setup"
        case .launch: "Ship 10x Faster"
        }
    }

    var description: String {
        switch self {
        case .shipFast: "Skills structured for AI models — Claude, Cursor, Windsurf get production-grade context instantly."
        case .components: "Auth, camera, AI chat, in-app purchase — every skill battle-tested in real App Store apps."
        case .modular: "Connect via MCP with one command. No downloads, no setup, no dependencies to manage."
        case .launch: "Stop rebuilding auth and payments from scratch. Focus on what makes your app unique."
        }
    }
}

// MARK: - Preview
#Preview("Onboarding") {
    SWOnboardingView(onComplete: { print("Done") })
}
