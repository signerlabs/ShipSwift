//
//  ShipSwiftApp.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/15.
//

import SwiftUI

@main
struct ShipSwiftApp: App {
    @State private var storeManager = slStoreManager.shared

    var body: some Scene {
        WindowGroup {
            slRootTabView()
                .environment(storeManager)
        }
    }
}
