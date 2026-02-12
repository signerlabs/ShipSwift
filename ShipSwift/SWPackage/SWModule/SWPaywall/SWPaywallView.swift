//
//  SWPaywallView.swift
//  ShipSwift
//
//  Paywall subscription view using StoreKit SubscriptionStoreView.
//

import SwiftUI
import StoreKit

struct SWPaywallView: View {
    @Environment(SWStoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "en"

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(productIDs: storeManager.config.allSubscriptionIDs) {
                paywallContent
            }
            .storeButton(.visible, for: .policies)
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(.visible, for: .cancellation)
            .storeButton(.visible, for: .redeemCode)
            .scrollIndicators(.hidden)
            .subscriptionStorePolicyDestination(
                url: URL(string: storeManager.config.privacyPolicyURL)!,
                for: .privacyPolicy
            )
            .subscriptionStorePolicyDestination(
                url: URL(string: storeManager.config.termsOfServiceURL)!,
                for: .termsOfService
            )
            .onInAppPurchaseCompletion { _, result in
                if case .success(.success(.verified)) = result {
                    Task {
                        await storeManager.updatePurchaseStatus()
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var paywallContent: some View {
        VStack(spacing: 20) {
            SWShakingIcon()

            Text(storeManager.config.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading) {
                ForEach(storeManager.config.features) { feature in
                    HStack {
                        Image(systemName: feature.icon)
                            .imageScale(.small)
                        Text(feature.text)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .font(.title3)
            .padding(.vertical)
        }
        .padding(.top)
        .environment(\.locale, Locale(identifier: appLanguage))
    }
}

#Preview {
    SWPaywallView()
        .environment(SWStoreManager.shared)
}
