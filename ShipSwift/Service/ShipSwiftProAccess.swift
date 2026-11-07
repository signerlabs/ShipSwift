//
//  ShipSwiftProAccess.swift
//  ShipSwift
//
//  Showcase-app Pro access. ShipSwift Pro can be unlocked by the in-app
//  lifetime purchase (StoreKit, tracked by the library's SWStoreManager)
//  or by an active API key on the ShipSwift server (e.g. bought on
//  shipswift.app). This file adds the server half for the showcase app,
//  so SWStoreManager itself stays a generic StoreKit manager.
//
//  Usage:
//    if storeManager.hasProAccess { /* StoreKit or server Pro */ }
//    await storeManager.checkServerProStatus(idToken: idToken)
//    let key = await storeManager.syncPurchaseToServer(idToken: idToken)
//

import StoreKit
import SwiftUI

/// Server-side Pro state for the signed-in user.
@MainActor
@Observable
final class ShipSwiftProAccess {
    static let shared = ShipSwiftProAccess()

    /// Whether the server has an active Pro API key for this user
    var hasServerPro = false

    /// Cached API key from server
    var apiKey: String?

    private init() {}
}

extension SWStoreManager {

    /// Pro via an App Store purchase or an active key on the ShipSwift server.
    var hasProAccess: Bool { isPro || ShipSwiftProAccess.shared.hasServerPro }

    /// Cached API key from server
    var apiKey: String? { ShipSwiftProAccess.shared.apiKey }

    /// Check server pro status using Cognito ID token
    func checkServerProStatus(idToken: String) async {
        let access = ShipSwiftProAccess.shared
        do {
            let service = ShipSwiftAPIService()
            let status = try await service.getApiKeyStatus(idToken: idToken)
            access.hasServerPro = status.hasKey && status.status == "active"
            if access.hasServerPro {
                access.apiKey = status.apiKey
            }
        } catch {
            swDebugLog("Failed to check server pro status: \(error)")
        }
    }

    /// Sync App Store purchase to server and get API key
    func syncPurchaseToServer(idToken: String) async -> String? {
        // Get the latest transaction for the lifetime product
        guard let result = await Transaction.latest(for: config.lifetimeProductID),
              case .verified = result else {
            return nil
        }

        let access = ShipSwiftProAccess.shared
        do {
            let service = ShipSwiftAPIService()
            let response = try await service.verifyAppStorePurchase(
                idToken: idToken,
                signedTransactionInfo: result.jwsRepresentation
            )
            access.apiKey = response.apiKey
            access.hasServerPro = true
            return response.apiKey
        } catch {
            swDebugLog("Failed to sync purchase to server: \(error)")
            return nil
        }
    }
}
