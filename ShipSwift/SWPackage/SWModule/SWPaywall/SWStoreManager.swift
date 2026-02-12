//
//  SWStoreManager.swift
//  ShipSwift
//
//  StoreKit 2 subscription and in-app purchase manager.
//  Manages monthly/yearly subscriptions and lifetime purchases,
//  tracks pro status, and enforces free-user resource limits.
//
//  Usage:
//    // 1. Configure before showing the paywall (e.g. in App init)
//    let store = SWStoreManager.shared
//    store.config.monthlyProductID = "com.myapp.monthly"
//    store.config.yearlyProductID  = "com.myapp.yearly"
//    store.config.lifetimeProductID = "com.myapp.lifetime"
//    store.config.tripLimitForFreeUser = 3
//    store.config.itemLimitForFreeUser = 20
//    store.config.privacyPolicyURL = "https://example.com/privacy"
//    store.config.termsOfServiceURL = "https://example.com/terms"
//    store.config.title = "Go Pro"
//    store.config.features = [
//        .init(icon: "star.fill", text: "Unlimited trips"),
//        .init(icon: "bolt.fill", text: "Priority support"),
//    ]
//
//    // 2. Inject into SwiftUI environment
//    ContentView()
//        .environment(SWStoreManager.shared)
//
//    // 3. Check pro status anywhere
//    if SWStoreManager.shared.isPro { /* unlock premium features */ }
//    // isPro == hasLifetimePurchase || hasActiveSubscription
//
//    // 4. Enforce free-user limits
//    if store.canCreateNewTrip(currentTripCount: trips.count) {
//        createTrip()
//    } else {
//        showPaywall()
//    }
//    let remaining = store.remainingItemsForFreeUser(currentItemCount: items.count)
//
//    // 5. Manually refresh purchase status
//    await store.updatePurchaseStatus()
//
//  Created by Wei Zhong on 3/1/26.
//

import StoreKit
import SwiftUI

@MainActor
@Observable
final class SWStoreManager {

    // MARK: - Singleton

    static let shared = SWStoreManager()

    // MARK: - Product Configuration (inline from app)

    /// Override these in your app's init or via a configure method
    struct PaywallConfig {
        var title = "Pro"
        var monthlyProductID = "com.example.app.monthly"
        var yearlyProductID = "com.example.app.yearly"
        var lifetimeProductID = "com.example.app.lifetime"
        var tripLimitForFreeUser = 3
        var itemLimitForFreeUser = 20
        var privacyPolicyURL = "https://example.com/privacy"
        var termsOfServiceURL = "https://example.com/terms"

        struct Feature: Identifiable {
            let id = UUID()
            let icon: String
            let text: LocalizedStringKey
        }

        var features: [Feature] = []

        var allSubscriptionIDs: [String] {
            [monthlyProductID, yearlyProductID]
        }
    }

    /// Configure this before showing the paywall
    var config = PaywallConfig()

    // MARK: - Product Type

    enum ProductType: CaseIterable {
        case lifetime
        case monthly
        case yearly
    }

    private func productType(for id: String) -> ProductType? {
        if id == config.lifetimeProductID { return .lifetime }
        if id == config.monthlyProductID { return .monthly }
        if id == config.yearlyProductID { return .yearly }
        return nil
    }

    // MARK: - State

    private(set) var hasActiveSubscription = false
    private(set) var hasLifetimePurchase = false

    var isPro: Bool { hasLifetimePurchase || hasActiveSubscription }

    // MARK: - Init

    init() {
        Task { await updatePurchaseStatus() }
        startObservingTransactions()
    }

    private func startObservingTransactions() {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, case let .verified(transaction) = result else { continue }
                await transaction.finish()
                await updatePurchaseStatus()
            }
        }
    }

    // MARK: - Purchase Status

    func updatePurchaseStatus() async {
        var subscription = false
        var lifetime = false

        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }

            switch productType(for: transaction.productID) {
            case .lifetime:
                lifetime = true
            case .monthly, .yearly:
                if transaction.revocationDate == nil {
                    subscription = true
                }
            case nil:
                break
            }
        }

        hasLifetimePurchase = lifetime
        hasActiveSubscription = subscription
    }

    // MARK: - Free User Limit Checks

    func canCreateNewTrip(currentTripCount: Int) -> Bool {
        isPro || currentTripCount < config.tripLimitForFreeUser
    }

    func remainingTripsForFreeUser(currentTripCount: Int) -> Int? {
        guard !isPro else { return nil }
        return max(0, config.tripLimitForFreeUser - currentTripCount)
    }

    func canCreateNewItem(currentItemCount: Int) -> Bool {
        isPro || currentItemCount < config.itemLimitForFreeUser
    }

    func remainingItemsForFreeUser(currentItemCount: Int) -> Int? {
        guard !isPro else { return nil }
        return max(0, config.itemLimitForFreeUser - currentItemCount)
    }
}
