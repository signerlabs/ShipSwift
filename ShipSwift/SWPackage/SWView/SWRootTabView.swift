//
//  SWRootTabView.swift
//  ShipSwift
//
//  Root TabView template using the iOS 18+ Tab API, with selected/unselected icon
//  switching, native search tab, and haptic feedback. Uses
//  .environment(\.symbolVariants, .none) to prevent the system from auto-filling icons.
//
//  Usage:
//    // 1. Use directly as the app root view:
//    @main struct MyApp: App {
//        var body: some Scene {
//            WindowGroup { SWRootTabView() }
//        }
//    }
//
//    // 2. Customize tabs: modify the Tab entries inside the TabView. Each tab follows this pattern:
//    Tab(value: "tabID") {
//        YourContentView()           // Replace with your page
//    } label: {
//        Label {
//            Text("Tab Name")
//        } icon: {
//            Image(systemName: selectedTab == "tabID" ? "icon.fill" : "icon")
//        }
//        .environment(\.symbolVariants, .none)
//    }
//
//    // 3. Add or remove tabs: simply add or delete Tab entries in the TabView closure.
//    //    Set the selectedTab default value to the first tab's value string.
//
//    // 4. Search tab: uses .searchable() on NavigationStack for native search bar.
//    //    Replace ContentUnavailableView with your search results view.
//
//    // 5. Haptic feedback: built in via .sensoryFeedback(.increase, trigger: selectedTab),
//    //    triggered automatically on tab switch.
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWRootTabView: View {
    @State private var selectedTab = "home"
    @State private var searchText = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: "home") {
                NavigationStack {
                    ScrollView {
                        Text("Home View")
                    }
                    .navigationTitle("Home")
                }
            } label: {
                Label {
                    Text("Home")
                } icon: {
                    Image(systemName: selectedTab == "home" ? "house.fill" : "house")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "outfit") {
                NavigationStack {
                    ScrollView {
                        Text("Outfit View")
                    }
                    .navigationTitle("Outfit")
                }
            } label: {
                Label {
                    Text("Outfit")
                } icon: {
                    Image(systemName: selectedTab == "outfit" ? "tshirt.fill" : "tshirt")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "setting") {
                NavigationStack {
                    ScrollView {
                        Text("Setting View")
                    }
                    .navigationTitle("Setting")
                }
            } label: {
                Label {
                    Text("Setting")
                } icon: {
                    Image(systemName: selectedTab == "setting" ? "gearshape.fill" : "gearshape")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "search") {
                NavigationStack {
                    ScrollView {
                        ContentUnavailableView.search(text: searchText)
                    }
                    .navigationTitle("Search")
                }
                .searchable(text: $searchText, prompt: "Search...")
            } label: {
                Label {
                    Text("Search")
                } icon: {
                    Image(systemName: "magnifyingglass")
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
