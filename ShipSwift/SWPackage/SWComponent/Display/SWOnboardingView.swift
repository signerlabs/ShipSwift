//
//  SWOnboardingView.swift
//  ShipSwift
//
//  Multi-page onboarding view with swipe-to-navigate support, a "Continue / Get Started"
//  button and a "Skip" button at the bottom. Page content is defined by the OnboardingPage
//  enum (icon / title / description) — add or remove cases freely.
//
//  Usage:
//    // 1. Present the onboarding at app launch or first run; handle completion/skip via onComplete:
//    SWOnboardingView(onComplete: {
//        hasSeenOnboarding = true
//    })
//
//    // 2. Customize pages: modify the OnboardingPage enum, add/remove cases and provide icon / title / description:
//    enum OnboardingPage: CaseIterable {
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

    private let pages = OnboardingPage.allCases
    @State private var currentPage = 0

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
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Bottom confirm button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onComplete()
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
            }
            .buttonStyle(.swPrimary)
            .padding(.bottom)

            // Bottom skip button
            Button {
                onComplete()
            } label: {
                Text("Skip")
                    .foregroundStyle(.secondary)
            }
            .opacity(currentPage < pages.count - 1 ? 0 : 1)
        }
        .safeAreaPadding(.horizontal)
    }
}

// MARK: - Onboarding Page Model
enum OnboardingPage: CaseIterable {
    case shipFast
    case components
    case modular
    case launch

    var icon: String {
        switch self {
        case .shipFast: "shippingbox.fill"
        case .components: "square.grid.2x2.fill"
        case .modular: "puzzlepiece.extension.fill"
        case .launch: "paperplane.fill"
        }
    }

    var title: String {
        switch self {
        case .shipFast: "Ship Faster"
        case .components: "50+ Components"
        case .modular: "Plug & Play"
        case .launch: "Idea to App Store"
        }
    }

    var description: String {
        switch self {
        case .shipFast: "Build production-ready iOS apps in days, not months."
        case .components: "Charts, animations, camera, auth, paywall — all ready to use."
        case .modular: "Every component is self-contained. Drop it in and it just works."
        case .launch: "Stop rebuilding the basics. Focus on what makes your app unique."
        }
    }
}

// MARK: - Preview
#Preview("Onboarding") {
    SWOnboardingView(onComplete: { print("Done") })
}
