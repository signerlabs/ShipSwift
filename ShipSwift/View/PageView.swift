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
                Section {
                    Button {
                        showOnboarding = true
                    } label: {
                        Label("Onboarding", systemImage: "hand.wave.fill")
                    }
                } footer: {
                    Text("Multi-page welcome flow with swipe navigation and skip support. Presented as fullScreenCover.")
                }

                Section {
                    NavigationLink {
                        SWSettingView()
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                } footer: {
                    Text("Generic settings page with language switch, share, legal links, and account actions. Pushed via NavigationLink.")
                }

                Section {
                    Button {
                        showOrder = true
                    } label: {
                        Label("Order", systemImage: "cup.and.saucer.fill")
                    }
                } footer: {
                    Text("Animated drink customization demo with flavor/size selectors and cup animations. Presented as fullScreenCover.")
                }

                Section {
                    Button {
                        showRootTab = true
                    } label: {
                        Label("Tab", systemImage: "rectangle.split.3x1.fill")
                    }
                } footer: {
                    Text("TabView template with selected/unselected icons and haptic feedback. Presented as sheet.")
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
