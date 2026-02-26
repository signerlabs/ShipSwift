//
//  ShipSwiftApp.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/15.
//

import SwiftUI

@main
struct ShipSwiftApp: App {
    // StoreManager disabled for App Store review — showcase app has no real subscriptions
//    @State private var storeManager = SWStoreManager.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                // .environment(storeManager)
                .swAlert()
        }
    }
}
