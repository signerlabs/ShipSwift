//
//  RootTabView.swift
//  ShipSwift
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = "home"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: "home") {
                HomeView(selectedTab: $selectedTab)
            } label: {
                Label {
                    Text("ShipSwift")
                } icon: {
                    Image(systemName: selectedTab == "home" ? "house.fill" : "house")
                }
                .environment(\.symbolVariants, .none)
            }
            
            Tab(value: "module") {
                ModuleView()
            } label: {
                Label {
                    Text("Module")
                } icon: {
                    Image(systemName: selectedTab == "module" ? "puzzlepiece.extension.fill" : "puzzlepiece.extension")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "animation") {
                AnimationView()
            } label: {
                Label {
                    Text("Animation")
                } icon: {
                    Image(systemName: selectedTab == "animation" ? "sparkles.tv.fill" : "sparkles.tv")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "chart") {
                ChartView()
            } label: {
                Label {
                    Text("Chart")
                } icon: {
                    Image(systemName: selectedTab == "chart" ? "chart.bar.fill" : "chart.bar")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "component") {
                ComponentView()
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
