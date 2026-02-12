//
//  ShipSwiftApp.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/15.
//

import SwiftUI

@main
struct ShipSwiftApp: App {
    @State private var storeManager = SWStoreManager.shared

    var body: some Scene {
        WindowGroup {
            SWRootTabView()
                .environment(storeManager)
                .swAlert()
        }
    }
}
