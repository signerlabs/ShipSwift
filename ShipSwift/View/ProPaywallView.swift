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
    @Environment(\.openURL) private var openURL

    @State private var isPurchasing = false
    @State private var showAuth = false
    @State private var isSyncing = false

    /// Recipient address for Founder Services custom development inquiries.
    private let founderEmail = "wei@signerlabs.com"

    private let features: [(icon: String, key: LocalizedStringKey)] = [
        ("cpu.fill", "paywall.feature.ai"),
        ("checkmark.seal.fill", "paywall.feature.fullstack"),
        ("terminal.fill", "paywall.feature.mcp"),
        ("arrow.triangle.branch", "paywall.feature.lifetime"),
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
            .frame(maxWidth: .infinity)
            #if canImport(UIKit)
            .background(Color(UIColor.systemGroupedBackground))
            #else
            .background(Color(NSColor.windowBackgroundColor))
            #endif
            .toolbarTitleDisplayMode(.inline)
            #if os(iOS)
            .fullScreenCover(isPresented: $showAuth) {
                NavigationStack {
                    ShipSwiftAuthView()
                        .environment(userManager)
                }
            }
            #else
            .sheet(isPresented: $showAuth) {
                NavigationStack {
                    ShipSwiftAuthView()
                        .environment(userManager)
                }
            }
            #endif
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

            Text("paywall.title")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("paywall.tagline")
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
                    Text(feature.key)
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
                        if isPurchasing {
                            Text("paywall.buy.processing")
                                .font(.headline)
                        } else {
                            // Compose "<localized prefix> <price>" — price stays a verbatim runtime value.
                            HStack(spacing: 6) {
                                Text("paywall.buy.prefix")
                                Text(verbatim: product.displayPrice)
                            }
                            .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(isPurchasing)

                Text("paywall.buy.footnote")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Loading product
                ProgressView("paywall.loading")
            }
        }
    }

    private var proStatusSection: some View {
        VStack(spacing: 12) {
            Label("paywall.unlocked", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.green)

            if !userManager.sessionState.isSignedIn {
                Button {
                    showAuth = true
                } label: {
                    Text("paywall.sign_in_for_key")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if isSyncing {
                ProgressView("paywall.syncing")
            } else {
                Button { dismiss() } label: {
                    Text("paywall.done")
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
            Button("paywall.restore") {
                Task { await restorePurchases() }
            }
            .font(.subheadline)

            // Secondary entry point to Founder Services (custom development).
            // Users who don't want a DIY skill-based path can request a turnkey MVP.
            HStack(spacing: 6) {
                Text("paywall.founder.line")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    contactFounderServices()
                } label: {
                    Text("paywall.founder.cta")
                        .font(.caption.bold())
                        .foregroundStyle(.accent)
                }
            }
            .padding(.top, 4)

            HStack(spacing: 16) {
                Link("paywall.legal.terms", destination: URL(string: "https://shipswift.app/terms")!)
                Link("paywall.legal.privacy", destination: URL(string: "https://shipswift.app/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Founder Services

    /// Open the user's default mail client with a localized inquiry template
    /// pre-addressed to Founder Services.
    private func contactFounderServices() {
        let subject = String(localized: "founder.email.subject")
        let body = String(localized: "founder.email.body")

        guard
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "mailto:\(founderEmail)?subject=\(encodedSubject)&body=\(encodedBody)")
        else { return }

        openURL(url)
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
                    #if os(iOS)
                    SWTikTokTrackingManager.shared.track(.purchase, properties: [
                        "product_id": product.id,
                        "price": product.displayPrice
                    ])
                    #endif

                    // If already signed in, auto-sync to server
                    if userManager.sessionState.isSignedIn {
                        await syncAndDismiss()
                    }
                    // Otherwise, UI will show "Sign in to get your API Key"
                }
            case .pending:
                SWAlertManager.shared.show(.info, message: String(localized: "paywall.alert.pending"))
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            let prefix = String(localized: "paywall.alert.failed")
            SWAlertManager.shared.show(.error, message: "\(prefix): \(error.localizedDescription)")
        }
    }

    private func syncAndDismiss() async {
        isSyncing = true
        defer { isSyncing = false }

        guard let idToken = await userManager.getFreshIdToken() else { return }
        let apiKey = await storeManager.syncPurchaseToServer(idToken: idToken)
        if apiKey != nil {
            SWAlertManager.shared.show(.success, message: String(localized: "paywall.alert.api_key_generated"))
        }
        dismiss()
    }

    private func restorePurchases() async {
        do {
            try await AppStore.sync()
            await storeManager.updatePurchaseStatus()
            if storeManager.isPro {
                SWAlertManager.shared.show(.success, message: String(localized: "settings.alert.restored"))
            } else {
                SWAlertManager.shared.show(.info, message: String(localized: "settings.alert.no_purchases"))
            }
        } catch {
            let prefix = String(localized: "settings.alert.restore_failed")
            SWAlertManager.shared.show(.error, message: "\(prefix): \(error.localizedDescription)")
        }
    }
}
