//
//  RootTabView.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/15.
//

import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = "page"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Page", systemImage: "house", value: "page") {
                PageView()
            }
            
            Tab("AnimationView", systemImage: "tshirt", value: "animation") {
                AnimationView()
            }
            
            Tab("Setting", systemImage: "gearshape.fill", value: "setting") {
                SettingView()
            }
        }
        .sensoryFeedback(.increase, trigger: selectedTab)
    }
}

#Preview {
    RootTabView()
}
