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
                // Onboarding — fullScreenCover (dismissed via onComplete)
                Button {
                    showOnboarding = true
                } label: {
                    Label("SWOnboardingView", systemImage: "hand.wave.fill")
                }
                
                // Setting — NavigationLink push
                NavigationLink {
                    SWSettingView()
                } label: {
                    Label("SWSettingView", systemImage: "gearshape.fill")
                }
                
                // Order — fullScreenCover + dismiss button
                Button {
                    showOrder = true
                } label: {
                    Label("SWOrderView", systemImage: "cup.and.saucer.fill")
                }
                
                // RootTabView — sheet
                Button {
                    showRootTab = true
                } label: {
                    Label("SWRootTabView", systemImage: "rectangle.split.3x1.fill")
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
