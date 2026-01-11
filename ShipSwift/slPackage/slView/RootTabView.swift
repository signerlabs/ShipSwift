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
            Tab("Home", systemImage: "house", value: "home") {
                EmptyView()
            }
            
            Tab("Outfit", systemImage: "tshirt", value: "outfit") {
                EmptyView()
            }
            
            Tab("Setting", systemImage: "gearshape.fill", value: "setting") {
                EmptyView()
            }
        }
        .sensoryFeedback(.increase, trigger: selectedTab)
    }
}

#Preview {
    RootTabView()
}
