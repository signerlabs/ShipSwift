//
//  RootTabView.swift
//  ShipSwift
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = "home"
    @State private var scrollTarget: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: "home") {
                HomeView(selectedTab: $selectedTab, scrollTarget: $scrollTarget)
            } label: {
                Label {
                    Text("ShipSwift")
                } icon: {
                    Image(systemName: selectedTab == "home" ? "house.fill" : "house")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "chat") {
                ChatView()
            } label: {
                Label {
                    Text("Chat")
                } icon: {
                    Image(systemName: selectedTab == "chat" ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "component") {
                ComponentView(scrollTarget: $scrollTarget)
            } label: {
                Label {
                    Text("Component")
                } icon: {
                    Image(systemName: selectedTab == "component" ? "square.grid.2x2.fill" : "square.grid.2x2")
                }
                .environment(\.symbolVariants, .none)
            }
        }
        .sensoryFeedback(.increase, trigger: selectedTab)
    }
}

#Preview {
    RootTabView()
}
