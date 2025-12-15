//
//  RootTabView.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/15.
//

import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = "home"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: "home") {
                HomeView()
            }
            
            Tab("Outfit", systemImage: "tshirt", value: "outfit") {
                OutfitView()
            }
            
            Tab("Inventory", systemImage: "archivebox", value: "inventory") {
                InventoryView()
            }
            
            Tab("Settings", systemImage: "gearshape.fill", value: "settings") {
                SettingsView()
            }
        }
        .sensoryFeedback(.increase, trigger: selectedTab)
    }
}

#Preview {
    RootTabView()
}
