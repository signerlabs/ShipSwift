//
//  SettingView.swift
//  ShipSwift
//
//  Settings page for the ShipSwift Showcase App.
//  Includes Pro status, API key management, account, recommended apps,
//  share, legal links, and version info.
//
//  Created by Wei Zhong on 13/2/26.
//

import SwiftUI
import StoreKit

struct SettingView: View {
    @Environment(SWStoreManager.self) private var storeManager
    @Environment(SWUserManager.self) private var userManager

    // MARK: - State

    @State private var showPaywall = false
    @State private var showAuth = false
    @State private var isSyncing = false
    @State private var showDeleteConfirmation = false

    // MARK: - Configuration

    private let appStoreURL = URL(string: "https://apps.apple.com/app/id6759209764")!
    private let termsURL = URL(string: "https://shipswift.app/terms")!
    private let privacyURL = URL(string: "https://shipswift.app/privacy")!

    // App Store links for recommended apps
    private let appStoreFullpack = "https://apps.apple.com/us/app/fullpack-packing-outfit/id6745692929"
    private let appStoreBrushmo = "https://apps.apple.com/us/app/brushmo/id6744569822"
    private let appStoreLifebang = "https://apps.apple.com/us/app/lifebang/id6474886848"
    private let appStoreUtilityMax = "https://apps.apple.com/us/app/utilitymax%E6%95%88%E5%BA%A6%E5%AE%B6-%E7%BB%88%E8%BA%AB%E8%B4%A2%E5%8A%A1%E6%A8%A1%E6%8B%9F%E4%B8%8E%E9%80%80%E4%BC%91%E8%A7%84%E5%88%92%E5%99%A8/id6758595049"
    private let appStoreJourney = "https://apps.apple.com/us/app/journey-goal-tracker-diary/id6748666816"
    private let appStoreSmileMax = "https://apps.apple.com/us/app/smilemax/id6758947123"

    /// App version number
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// App build number
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                proSection
                if userManager.sessionState.isSignedIn { accountSection }
                recommendedAppsSection
                generalSection
                legalSection
                versionSection
            }
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.inlineLarge)
            .sheet(isPresented: $showPaywall) {
                ProPaywallView()
                    .environment(storeManager)
                    .environment(userManager)
            }
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
                    Task { await syncProStatus() }
                }
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        try? await userManager.deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. Your account and all associated data will be permanently deleted.")
            }
        }
    }

    // MARK: - Pro Section

    private var proSection: some View {
        Section {
            if storeManager.isPro {
                // Pro status
                HStack {
                    Label("ShipSwift Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // API Key management
                if userManager.sessionState.isSignedIn {
                    apiKeyRow
                } else {
                    Button {
                        showAuth = true
                    } label: {
                        Label("Sign in to get your API Key", systemImage: "person.badge.key.fill")
                    }
                }
            } else {
                // Upgrade button
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Upgrade to Pro", systemImage: "star.fill")
                            .foregroundStyle(.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Restore Purchases
            Button {
                Task { await restorePurchases() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Pro")
        }
    }

    // MARK: - API Key Row

    private var apiKeyRow: some View {
        Group {
            if let masked = storeManager.apiKey {
                Button {
                    Task { await copyKey() }
                } label: {
                    HStack {
                        Label {
                            Text(masked)
                                .font(.system(.subheadline, design: .monospaced))
                                .lineLimit(1)
                        } icon: {
                            Image(systemName: "key.fill")
                        }
                        Spacer()
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(.secondary)
                    }
                }
            } else if isSyncing {
                HStack {
                    Label("Syncing purchase...", systemImage: "key.fill")
                    Spacer()
                    ProgressView()
                }
            } else {
                Button {
                    Task { await syncProStatus() }
                } label: {
                    Label("Get API Key", systemImage: "key.fill")
                }
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("Account") {
            HStack {
                Label("Email", systemImage: "envelope")
                Spacer()
                Text(extractEmail())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Button {
                Task { await userManager.signOut() }
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Account", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Other Sections

    private var recommendedAppsSection: some View {
        Section("Apps Built with ShipSwift") {
            Link(destination: URL(string: appStoreSmileMax)!) {
                labelWithImage(.smileMaxLogo, name: "SmileMax - Glow Up Coach")
            }
            Link(destination: URL(string: appStoreFullpack)!) {
                labelWithImage(.fullpackLogo, name: "Fullpack - Packing & Outfit")
            }
            Link(destination: URL(string: appStoreBrushmo)!) {
                labelWithImage(.brushmoLogo, name: "Brushmo - Oral Health Companion")
            }
            Link(destination: URL(string: appStoreLifebang)!) {
                labelWithImage(.lifebangLogo, name: "Lifebang - Pro Cleaner")
            }
            Link(destination: URL(string: appStoreUtilityMax)!) {
                labelWithImage(.utilityMaxLogo, name: "UtilityMax - Financial Simulator")
            }
            Link(destination: URL(string: appStoreJourney)!) {
                labelWithImage(.journeyLogo, name: "Spark - Goal Tracker & Diary")
            }
        }
    }

    private var generalSection: some View {
        Section {
            ShareLink(item: appStoreURL) {
                HStack {
                    Text("Share App")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var legalSection: some View {
        Section {
            Link(destination: termsURL) {
                HStack {
                    Text("Terms of Service")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: privacyURL) {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var versionSection: some View {
        Section {
            LabeledContent("Version") {
                Text("v\(appVersion) (\(buildNumber))")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func labelWithImage(_ image: ImageResource, name: LocalizedStringResource) -> some View {
        HStack {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(5)
            Text(name)
        }
    }

    private func extractEmail() -> String {
        // Decode email from JWT id token
        guard let idToken = userManager.sessionState.tokens?.idToken else { return "" }
        let parts = idToken.split(separator: ".")
        guard parts.count >= 2,
              let data = Data(base64Encoded: String(parts[1]).padding(toLength: ((parts[1].count + 3) / 4) * 4, withPad: "=", startingAt: 0)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = json["email"] as? String else {
            return ""
        }
        return email
    }

    // MARK: - Actions

    private func syncProStatus() async {
        guard let idToken = await userManager.getFreshIdToken() else { return }
        isSyncing = true
        defer { isSyncing = false }

        // If user has a local purchase, sync it to server
        if storeManager.hasLifetimePurchase {
            _ = await storeManager.syncPurchaseToServer(idToken: idToken)
        }

        // Check server status
        await storeManager.checkServerProStatus(idToken: idToken)
    }

    private func copyKey() async {
        guard let idToken = await userManager.getFreshIdToken() else { return }
        do {
            let service = ShipSwiftAPIService()
            let key = try await service.revealApiKey(idToken: idToken)
            #if os(iOS)
            UIPasteboard.general.string = key
            #else
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(key, forType: .string)
            #endif
            SWAlertManager.shared.show(.success, message: "API Key copied to clipboard")
        } catch {
            SWAlertManager.shared.show(.error, message: "Failed to copy API key")
        }
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
            SWAlertManager.shared.show(.error, message: "Restore failed")
        }
    }
}

#Preview {
    SettingView()
        .environment(SWStoreManager.shared)
        .environment(SWUserManager(skipAuthCheck: true))
}
