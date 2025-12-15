//
//  slOnboardingView.swift
//  full-pack
//
//  Created by Wei on 2025/5/27.
//

import SwiftUI

struct slOnboardingView: View {
    @State private var currentPage = 0
    @Environment(slUserManager.self) private var userManager
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                onboardingPage(title: "Snap & Sort Anything",
                               description: "Extract items from any background",
                               image: .welcome0)
                .tag(0)
                onboardingPage(title: "Pack Smart For Any Occasion",
                               description: "Packing list and reminders before you lock the door",
                               image: .welcome1)
                .tag(1)
                onboardingPage(title: "Outfit Planning",
                               description: "Plan your daily outfit on a drag-and-drop canvas",
                               image: .welcome2)
                .tag(2)
                onboardingPage(title: "Fast & Local",
                               description: "Zero data collection, your data stays on your device",
                               image: .welcome3)
                .tag(3)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            Button {
                if currentPage < 3 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    userManager.completeFirstLaunch()
                }
            } label: {
                Text(currentPage < 3 ? "Continue" : "Pack It Up")
            }
            .buttonStyle(.slPrimary)
            .padding()
        }
    }
    
    private func onboardingPage(title: LocalizedStringResource, description: LocalizedStringResource, image: ImageResource) -> some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(description)
                .foregroundStyle(.secondary)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Image(image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
        }
        .padding()
    }
}

#Preview {
    slOnboardingView()
        .environment(slUserManager())
}
