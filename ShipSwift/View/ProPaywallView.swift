//
//  ProPaywallView.swift
//  ShipSwift
//
//  Custom paywall for non-consumable lifetime purchase.
//  Handles purchase flow without requiring sign-in.
//  After purchase, prompts user to sign in to get their API key.
//
//  Created by ShipSwift on 2/27/26.
//

import SwiftUI
import StoreKit

struct ProPaywallView: View {
    @Environment(SWStoreManager.self) private var storeManager
    @Environment(SWUserManager.self) private var userManager
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var showAuth = false
    @State private var isSyncing = false

    private let features: [(icon: String, text: String)] = [
        ("cpu.fill", "AI-optimized recipes for all llm"),
        ("checkmark.seal.fill", "Full-stack iOS + AWS backend"),
        ("terminal.fill", "One MCP command — instant access"),
        ("arrow.triangle.branch", "Lifetime updates"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    featureList
                    purchaseSection
                    footerLinks
                }
                .padding()
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showAuth) {
                NavigationStack {
                    ShipSwiftAuthView()
                        .environment(userManager)
                }
            }
            .onChange(of: userManager.sessionState) { _, newState in
                if newState.isSignedIn {
                    showAuth = false
                    // Auto-sync purchase to server after sign-in
                    Task { await syncAndDismiss() }
                }
            }
            .task {
                // Pre-load the lifetime product for display
                await storeManager.loadLifetimeProduct()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            SWShakingIcon(
                image: Image(.shipSwiftLogo),
                height: 80,
                cornerRadius: 12,
                idleDelay: 6
            )
            .padding(.vertical)

            Text("ShipSwift Pro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Ship your iOS app 10x faster")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(features, id: \.icon) { feature in
                HStack(spacing: 10) {
                    Image(systemName: feature.icon)
                        .foregroundStyle(.accent)
                        .imageScale(.small)
                        .frame(width: 20)
                    Text(feature.text)
                        .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        VStack(spacing: 16) {
            if storeManager.isPro {
                // Already Pro
                proStatusSection
            } else if let product = storeManager.lifetimeProduct {
                // Show purchase button
                Button {
                    Task { await purchase(product) }
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isPurchasing ? "Processing..." : "Buy Now — \(product.displayPrice)")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(isPurchasing)

                Text("One-time purchase. No subscription.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Loading product
                ProgressView("Loading...")
            }
        }
    }

    private var proStatusSection: some View {
        VStack(spacing: 12) {
            Label("Pro Unlocked", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.green)

            if !userManager.sessionState.isSignedIn {
                Button {
                    showAuth = true
                } label: {
                    Text("Sign in to get your API Key")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if isSyncing {
                ProgressView("Syncing purchase...")
            } else {
                Button { dismiss() } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                Task { await restorePurchases() }
            }
            .font(.subheadline)

            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://shipswift.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://shipswift.app/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await storeManager.updatePurchaseStatus()
                    SWTikTokTrackingManager.shared.track(.purchase, properties: [
                        "product_id": product.id,
                        "price": product.displayPrice
                    ])

                    // If already signed in, auto-sync to server
                    if userManager.sessionState.isSignedIn {
                        await syncAndDismiss()
                    }
                    // Otherwise, UI will show "Sign in to get your API Key"
                }
            case .pending:
                SWAlertManager.shared.show(.info, message: "Purchase pending approval")
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            SWAlertManager.shared.show(.error, message: "Purchase failed: \(error.localizedDescription)")
        }
    }

    private func syncAndDismiss() async {
        isSyncing = true
        defer { isSyncing = false }

        guard let idToken = await userManager.getFreshIdToken() else { return }
        let apiKey = await storeManager.syncPurchaseToServer(idToken: idToken)
        if apiKey != nil {
            SWAlertManager.shared.show(.success, message: "API Key generated!")
        }
        dismiss()
    }

    private func restorePurchases() async {
        do {
            try await AppStore.sync()
            await storeManager.updatePurchaseStatus()
            if storeManager.isPro {
                SWAlertManager.shared.show(.success, message: "Purchases restored!")
            } else {
                SWAlertManager.shared.show(.info, message: "No previous purchases found")
            }
        } catch {
            SWAlertManager.shared.show(.error, message: "Restore failed: \(error.localizedDescription)")
        }
    }
}
