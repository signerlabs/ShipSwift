//
//  RootTabView.swift
//  ShipSwift
//
//  App root — five tabs on iOS (Home / Modules / Animation / Charts / UI),
//  a NavigationSplitView sidebar with the same five destinations on macOS.
//  `selectedTab` is a plain string shared by both platforms, so HomeView's
//  category cards can switch tabs by assignment on either platform.
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = "home"

    var body: some View {
        #if os(iOS)
        iOSBody
        #else
        macOSBody
        #endif
    }
}

// MARK: - iOS Body

#if os(iOS)
extension RootTabView {
    var iOSBody: some View {
        TabView(selection: $selectedTab) {
            Tab(value: "home") {
                HomeView(selectedTab: $selectedTab)
            } label: {
                Label {
                    Text("tab.home")
                } icon: {
                    Image(systemName: selectedTab == "home" ? "house.fill" : "house")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "modules") {
                ModuleListView()
            } label: {
                Label {
                    Text("tab.modules")
                } icon: {
                    Image(systemName: selectedTab == "modules" ? "puzzlepiece.extension.fill" : "puzzlepiece.extension")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "animation") {
                AnimationListView()
            } label: {
                Label {
                    Text("tab.animation")
                } icon: {
                    Image(systemName: "sparkles")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "charts") {
                ChartListView()
            } label: {
                Label {
                    Text("tab.charts")
                } icon: {
                    Image(systemName: selectedTab == "charts" ? "chart.bar.fill" : "chart.bar")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "ui") {
                UIListView()
            } label: {
                Label {
                    Text("tab.ui")
                } icon: {
                    Image(systemName: selectedTab == "ui" ? "square.grid.2x2.fill" : "square.grid.2x2")
                }
                .environment(\.symbolVariants, .none)
            }
        }
        .sensoryFeedback(.increase, trigger: selectedTab)
    }
}
#endif

// MARK: - macOS Body

#if os(macOS)
extension RootTabView {
    /// Bridges the non-optional tab string to the sidebar's optional selection.
    private var sidebarSelection: Binding<String?> {
        Binding(
            get: { selectedTab },
            set: { selectedTab = $0 ?? "home" }
        )
    }

    var macOSBody: some View {
        NavigationSplitView {
            List(selection: sidebarSelection) {
                Label("tab.home", systemImage: "house.fill")
                    .tag("home")

                Section("Components") {
                    Label("tab.modules", systemImage: "square.3.layers.3d")
                        .tag("modules")
                    Label("tab.animation", systemImage: "sparkles")
                        .tag("animation")
                    Label("tab.charts", systemImage: "chart.bar")
                        .tag("charts")
                    Label("tab.ui", systemImage: "square.grid.2x2")
                        .tag("ui")
                }
            }
            .navigationTitle("ShipSwift")
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch selectedTab {
            case "modules":
                ModuleListView()
            case "animation":
                AnimationListView()
            case "charts":
                ChartListView()
            case "ui":
                UIListView()
            default:
                HomeView(selectedTab: $selectedTab)
            }
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
    }
}
#endif

// MARK: - Preview

#Preview {
    RootTabView()
}
