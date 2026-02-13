//
//  PageView.swift
//  ShipSwift
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct PageView: View {
    @State private var showOnboarding = false
    @State private var showOrder = false
    @State private var showRootTab = false
    
    var body: some View {
        NavigationStack {
            List {
                Button {
                    showOnboarding = true
                } label: {
                    ListItem(
                        title: "Onboarding",
                        icon: "hand.wave.fill",
                        description: "Multi-page welcome flow with swipe navigation and skip support. Presented as fullScreenCover."
                    )
                }

                NavigationLink {
                    SWSettingView()
                } label: {
                    ListItem(
                        title: "Settings",
                        icon: "gearshape.fill",
                        description: "Generic settings page with language switch, share, legal links, and account actions. Pushed via NavigationLink."
                    )
                }

                Button {
                    showOrder = true
                } label: {
                    ListItem(
                        title: "Order",
                        icon: "cup.and.saucer.fill",
                        description: "Animated drink customization demo with flavor/size selectors and cup animations. Presented as fullScreenCover."
                    )
                }

                Button {
                    showRootTab = true
                } label: {
                    ListItem(
                        title: "Tab",
                        icon: "rectangle.split.3x1.fill",
                        description: "TabView template with selected/unselected icons and haptic feedback. Presented as sheet."
                    )
                }
            }
            .navigationTitle("Pages")
            .fullScreenCover(isPresented: $showOnboarding) {
                SWOnboardingView(onComplete: { showOnboarding = false })
            }
            .fullScreenCover(isPresented: $showOrder) {
                ZStack(alignment: .topTrailing) {
                    SWOrderView()
                    Button {
                        showOrder = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
            }
            .sheet(isPresented: $showRootTab) {
                SWRootTabView()
            }
        }
    }
}

#Preview {
    PageView()
}
