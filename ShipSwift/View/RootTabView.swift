//
//  RootTabView.swift
//  ShipSwift
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = "animation"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: "animation") {
                AnimationView()
            } label: {
                Label {
                    Text("Animation")
                } icon: {
                    Image(systemName: selectedTab == "animation" ? "sparkles" : "sparkles")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "charts") {
                ChartView()
            } label: {
                Label {
                    Text("Charts")
                } icon: {
                    Image(systemName: selectedTab == "charts" ? "chart.bar.fill" : "chart.bar")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "components") {
                ComponentView()
            } label: {
                Label {
                    Text("Components")
                } icon: {
                    Image(systemName: selectedTab == "components" ? "square.grid.2x2.fill" : "square.grid.2x2")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "modules") {
                ModuleView()
            } label: {
                Label {
                    Text("Modules")
                } icon: {
                    Image(systemName: selectedTab == "modules" ? "puzzlepiece.extension.fill" : "puzzlepiece.extension")
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
