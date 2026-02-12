//
//  RootTabView.swift
//  ShipSwift
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = "pages"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: "pages") {
                PageView()
            } label: {
                Label {
                    Text("Pages")
                } icon: {
                    Image(systemName: selectedTab == "pages" ? "doc.richtext.fill" : "doc.richtext")
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
