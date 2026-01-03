//
//  slOnboarding.swift
//  UtilityMax
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

// MARK: - Onboarding 主视图
struct slOnboarding<Content: View>: View {
    let pageCount: Int
    let onComplete: () -> Void
    let content: (Int) -> Content

    @State private var currentPage = 0

    init(
        pageCount: Int,
        onComplete: @escaping () -> Void,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.pageCount = pageCount
        self.onComplete = onComplete
        self.content = content
    }

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pageCount, id: \.self) { index in
                    content(index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // 底部确认按钮
            Button {
                if currentPage < pageCount - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    onComplete()
                }
            } label: {
                Text(currentPage < pageCount - 1 ? "Continue" : "Get Started")
            }
            .buttonStyle(.slPrimary)
            .padding(.bottom)

            // 底部跳过按钮
            Button {
                onComplete()
            } label: {
                Text("Skip")
                    .foregroundStyle(.secondary)
            }
            .opacity(currentPage < pageCount - 1 ? 1 : 0)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview
#Preview("Onboarding") {
    slOnboarding(pageCount: 3, onComplete: { print("Done") }) { index in
        VStack(spacing: 24) {
            Spacer()

            switch index {
            case 0:
                Image(systemName: "hand.wave")
                    .font(.system(size: 80))
                    .foregroundStyle(.accent)
                Text("Welcome")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Get started with our app")
                    .foregroundStyle(.secondary)
            case 1:
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 80))
                    .foregroundStyle(.accent)
                Text("Track Progress")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Monitor your daily activities")
                    .foregroundStyle(.secondary)
            default:
                Image(systemName: "person.2")
                    .font(.system(size: 80))
                    .foregroundStyle(.accent)
                Text("Stay Connected")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Share with friends and family")
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Spacer()
        }
    }
}
