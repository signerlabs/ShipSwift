//
//  slPaywallView.swift
//  full-pack
//
//  Created by Wei on 2025/7/27.
//  Copyright © 2025 Signer Labs. All rights reserved.
//

import SwiftUI
import StoreKit

struct slPaywallView: View {
    @Environment(slStoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss
    let productIDs = slConstants.Paywall.ProductID.allSubscriptions
    
    var body: some View {
        NavigationStack {
            SubscriptionStoreView(productIDs: productIDs) {
                paywallContent
            }
            .background(.customBg)
            .storeButton(.visible, for: .policies)
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(.visible, for: .cancellation)
            .storeButton(.visible, for: .redeemCode)
            .scrollIndicators(.hidden)
            .subscriptionStorePolicyDestination(
                url: URL(string: slConstants.URL.privacyPolicy)!,
                for: .privacyPolicy
            )
            .subscriptionStorePolicyDestination(
                url: URL(string: slConstants.URL.termsOfService)!,
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
            slShakingView()

            Text(slConstants.Paywall.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading) {
                ForEach(slConstants.Paywall.features, id: \.id) { feature in
                    HStack {
                        Image(systemName: feature.icon)
                            .foregroundStyle(.customGreen)
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
    }
}

#Preview {
    slPaywallView()
        .environment(slStoreManager())
}
