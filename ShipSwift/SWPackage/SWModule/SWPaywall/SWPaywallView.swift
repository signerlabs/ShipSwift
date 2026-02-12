//
//  SWPaywallView.swift
//  ShipSwift
//
//  Subscription paywall view using SubscriptionStoreView.
//  Displays subscription options, feature list, and handles purchase
//  completion with automatic pro status update and dismiss.
//
//  Usage:
//    // 1. Configure SWStoreManager before presenting (see SWStoreManager.swift)
//    //    Make sure product IDs, features, and policy URLs are set.
//
//    // 2. Present as a sheet with SWStoreManager in environment
//    @State private var showPaywall = false
//
//    Button("Upgrade") { showPaywall = true }
//    .sheet(isPresented: $showPaywall) {
//        SWPaywallView()
//            .environment(SWStoreManager.shared)
//    }
//
//    // 3. The view automatically:
//    //    - Shows monthly and yearly subscription options
//    //    - Displays configurable feature list with icons
//    //    - Shows Restore Purchases, Redeem Code, and policy buttons
//    //    - Dismisses on successful purchase
//    //    - Updates SWStoreManager.shared.isPro status
//
//    // 4. Preview usage
//    #Preview {
//        SWPaywallView()
//            .environment(SWStoreManager.shared)
//    }
//
//  Created by Wei Zhong on 3/1/26.
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
