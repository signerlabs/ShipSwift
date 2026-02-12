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
//        case welcome
//        case trackProgress
//        case stayConnected
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
            .opacity(currentPage < pages.count - 1 ? 1 : 0)
        }
        .padding(.horizontal)
    }
}

// MARK: - Onboarding Page Model
enum OnboardingPage: CaseIterable {
    case welcome
    case trackProgress
    case stayConnected

    var icon: String {
        switch self {
        case .welcome: "hand.wave"
        case .trackProgress: "chart.line.uptrend.xyaxis"
        case .stayConnected: "person.2"
        }
    }

    var title: String {
        switch self {
        case .welcome: "Welcome"
        case .trackProgress: "Track Progress"
        case .stayConnected: "Stay Connected"
        }
    }

    var description: String {
        switch self {
        case .welcome: "Get started with our app"
        case .trackProgress: "Monitor your daily activities"
        case .stayConnected: "Share with friends and family"
        }
    }
}

// MARK: - Preview
#Preview("Onboarding") {
    SWOnboardingView(onComplete: { print("Done") })
}
