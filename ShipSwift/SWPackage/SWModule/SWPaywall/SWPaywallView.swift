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
    var isDemo: Bool = false

    @Environment(SWStoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "en"

    var body: some View {
        if isDemo {
            demoBody
        } else {
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
    }

    // MARK: - Demo Body

    @State private var demoPlanSelected = 1   // 0 = monthly, 1 = yearly

    private var demoBody: some View {
        ScrollView {
            VStack(spacing: 28) {
                paywallContent

                // Plan picker rows (mimics macOS SubscriptionStoreView list style)
                VStack(spacing: 0) {
                    demoPlanRow(
                        index: 0,
                        title: "Monthly",
                        price: "$4.99",
                        period: "per month",
                        badge: nil
                    )
                    Divider()
                    demoPlanRow(
                        index: 1,
                        title: "Yearly",
                        price: "$29.99",
                        period: "per year",
                        badge: "Best Value"
                    )
                }
                #if canImport(UIKit)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                #else
                .background(Color(NSColor.controlBackgroundColor))
                #endif
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.1), lineWidth: 1))

                // Subscribe CTA
                Button {
                    SWAlertManager.shared.show(.info, message: "UI Demo — purchase actions are not functional")
                } label: {
                    Text(demoPlanSelected == 0 ? "Subscribe — $4.99 / month" : "Subscribe — $29.99 / year")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)

                // Footer
                VStack(spacing: 6) {
                    Button("Restore Purchases") {
                        SWAlertManager.shared.show(.info, message: "UI Demo — purchase actions are not functional")
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Text("Terms of Service").font(.caption).foregroundStyle(.tertiary)
                        Text("Privacy Policy").font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(.vertical)
            .padding(.horizontal)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
    }

    private func demoPlanRow(index: Int, title: String, price: String, period: String, badge: String?) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { demoPlanSelected = index }
        } label: {
            HStack(spacing: 12) {
                // Radio indicator
                Image(systemName: demoPlanSelected == index ? "circle.inset.filled" : "circle")
                    .foregroundStyle(demoPlanSelected == index ? Color.accentColor : .secondary)
                    .font(.system(size: 18))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title).fontWeight(.medium)
                        if let badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                    if index == 1 {
                        Text("$2.50 / month billed annually")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(price).fontWeight(.semibold)
                    Text(period).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var paywallContent: some View {
        VStack(spacing: 20) {
            SWShakingIcon(image: Image(systemName: "apple.logo"))

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
