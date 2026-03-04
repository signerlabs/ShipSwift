//
//  ShipSwiftApp.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/15.
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import TikTokBusinessSDK

@main
struct ShipSwiftApp: App {
    @State private var storeManager = SWStoreManager.shared
    @State private var userManager = SWUserManager()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        configureAmplify()
        configureStore()
        configureTikTok()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(storeManager)
                .environment(userManager)
                .swAlert()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                SWTikTokTrackingManager.shared.requestTrackingAuthorization()
            }
        }
    }

    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure(with: .amplifyOutputs)
        } catch {
            swDebugLog("Failed to configure Amplify: \(error)")
        }
    }

    private func configureTikTok() {
        guard let config = TikTokConfig(
            accessToken: SWSecrets.TikTok.accessToken,
            appId: SWSecrets.TikTok.appId,
            tiktokAppId: SWSecrets.TikTok.tiktokAppId
        ) else { return }
        #if DEBUG
        config.enableDebugMode()
        #endif
        TikTokBusiness.initializeSdk(config)

        SWTikTokTrackingManager.shared.configure { eventName, properties in
            let event = TikTokBaseEvent(eventName: eventName)
            properties?.forEach { event.addProperty(withKey: $0.key, value: $0.value) }
            TikTokBusiness.trackTTEvent(event)
        }
    }

    private func configureStore() {
        storeManager.config.lifetimeProductID = "com.signerlabs.shipswift.lifetime"
        storeManager.config.title = "ShipSwift Pro"
        storeManager.config.privacyPolicyURL = "https://shipswift.app/privacy"
        storeManager.config.termsOfServiceURL = "https://shipswift.app/terms"
        storeManager.config.features = [
            .init(icon: "cpu.fill", text: "AI-optimized recipes for Claude, Cursor & Windsurf"),
            .init(icon: "checkmark.seal.fill", text: "Full-stack iOS + AWS backend, battle-tested"),
            .init(icon: "terminal.fill", text: "One MCP command — zero downloads, instant access"),
            .init(icon: "arrow.triangle.branch", text: "Lifetime updates & new recipes included"),
        ]
    }
}
