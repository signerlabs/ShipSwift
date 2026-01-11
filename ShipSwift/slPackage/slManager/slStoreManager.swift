//
//  slStoreManager.swift
//  full-pack
//
//  Created by Wei on 2025/7/27.
//  Copyright © 2025 Signer Labs. All rights reserved.
//

import StoreKit
import SwiftUI

@MainActor
@Observable
final class slStoreManager {

    // MARK: - Singleton
    static let shared = slStoreManager()

    // MARK: - 产品类型

    enum ProductType: CaseIterable {
        case lifetime
        case monthly
        case yearly

        var id: String {
            switch self {
            case .lifetime: slConstants.Paywall.ProductID.lifetime
            case .monthly: slConstants.Paywall.ProductID.monthly
            case .yearly: slConstants.Paywall.ProductID.yearly
            }
        }

        static func from(id: String) -> ProductType? {
            allCases.first { $0.id == id }
        }
    }

    // MARK: - 属性

    private(set) var hasActiveSubscription = false
    private(set) var hasLifetimePurchase = false

    var isPro: Bool { hasLifetimePurchase || hasActiveSubscription }

    // MARK: - 初始化

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

    // MARK: - 购买状态更新

    func updatePurchaseStatus() async {
        var subscription = false
        var lifetime = false

        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }

            switch ProductType.from(id: transaction.productID) {
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

    // MARK: - 免费用户限制检查

    func canCreateNewTrip(currentTripCount: Int) -> Bool {
        isPro || currentTripCount < slConstants.Paywall.tripLimitForFreeUser
    }

    func remainingTripsForFreeUser(currentTripCount: Int) -> Int? {
        guard !isPro else { return nil }
        return max(0, slConstants.Paywall.tripLimitForFreeUser - currentTripCount)
    }

    func canCreateNewItem(currentItemCount: Int) -> Bool {
        isPro || currentItemCount < slConstants.Paywall.itemLimitForFreeUser
    }

    func remainingItemsForFreeUser(currentItemCount: Int) -> Int? {
        guard !isPro else { return nil }
        return max(0, slConstants.Paywall.itemLimitForFreeUser - currentItemCount)
    }
}
