//
//  SWRootTabView.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/15.
//

import SwiftUI

struct SWRootTabView: View {
    @State private var selectedTab = "home"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: "home") {
                EmptyView()
            } label: {
                Label {
                    Text("Home")
                } icon: {
                    Image(systemName: selectedTab == "home" ? "house.fill" : "house")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "outfit") {
                EmptyView()
            } label: {
                Label {
                    Text("Outfit")
                } icon: {
                    Image(systemName: selectedTab == "outfit" ? "tshirt.fill" : "tshirt")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "setting") {
                EmptyView()
            } label: {
                Label {
                    Text("Setting")
                } icon: {
                    Image(systemName: selectedTab == "setting" ? "gearshape.fill" : "gearshape")
                }
                .environment(\.symbolVariants, .none)
            }
        }
        .sensoryFeedback(.increase, trigger: selectedTab)
    }
}

#Preview {
    SWRootTabView()
}
