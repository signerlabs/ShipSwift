//
//  SWSettingView+macOS.swift
//  ShipSwift
//
//  macOS-native settings view using Form with grouped style.
//  Replaces the iOS List-based layout with native macOS Form controls,
//  LabeledContent rows, and macOS-appropriate link presentation.
//
//  Created by Wei Zhong on 3/7/26.
//

import SwiftUI

struct SWSettingView: View {

    // MARK: - State

    var isDemo: Bool = false

    @AppStorage("appLanguage") private var appLanguage = "en"
    @State private var selectedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var isDeleting = false
    @State private var isSigningOut = false

    // MARK: - Configuration

    private let appStoreURL = URL(string: "https://apps.apple.com/app/id6759209764")!
    private let termsURL = URL(string: "https://shipswift.app/terms")!
    private let privacyURL = URL(string: "https://shipswift.app/privacy")!

    private let appStoreFullpack    = URL(string: "https://apps.apple.com/us/app/fullpack-packing-outfit/id6745692929")!
    private let appStoreBrushmo     = URL(string: "https://apps.apple.com/us/app/brushmo/id6744569822")!
    private let appStoreLifebang    = URL(string: "https://apps.apple.com/us/app/lifebang/id6474886848")!
    private let appStoreJourney     = URL(string: "https://apps.apple.com/us/app/journey-goal-tracker-diary/id6748666816")!
    private let appStoreSmileMax    = URL(string: "https://apps.apple.com/us/app/smilemax/id6758947123")!
    private let appStoreUtilityMax  = URL(string: "https://apps.apple.com/us/app/utilitymax/id6758595049")!

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Body

    var body: some View {
        Form {
            // General
            Section("General") {
                Picker("Language", selection: $selectedLanguage) {
                    Text("English").tag("en")
                    Text("简体中文").tag("zh-Hans")
                }
                .onChange(of: selectedLanguage) { _, newValue in
                    if isDemo {
                        selectedLanguage = appLanguage
                        SWAlertManager.shared.show(.info, message: "UI Demo — language switching is not functional")
                    } else {
                        appLanguage = newValue
                    }
                }

                ShareLink("Share App", item: appStoreURL)
                    .buttonStyle(.plain)
            }

            // Legal
            Section("Legal") {
                Link("Terms of Service", destination: termsURL)
                Link("Privacy Policy", destination: privacyURL)
            }

            // Recommended Apps
            Section("Apps Built with ShipSwift") {
                appRow(.smileMaxLogo,      name: "SmileMax",       url: appStoreSmileMax)
                appRow(.fullpackLogo,      name: "Fullpack",       url: appStoreFullpack)
                appRow(.brushmoLogo,       name: "Brushmo",        url: appStoreBrushmo)
                appRow(.lifebangLogo,      name: "Lifebang",       url: appStoreLifebang)
                appRow(.utilityMaxLogo,    name: "UtilityMax",     url: appStoreUtilityMax)
                appRow(.journeyLogo,       name: "Journey",        url: appStoreJourney)
            }

            // Account
            Section("Account") {
                Button {
                    showSignOutConfirmation = true
                } label: {
                    if isSigningOut {
                        Label("Signing Out…", systemImage: "arrow.right.square")
                    } else {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                }
                .disabled(isDeleting || isSigningOut)
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    if isDeleting {
                        Label("Deleting…", systemImage: "trash")
                    } else {
                        Label("Delete Account", systemImage: "trash")
                    }
                }
                .disabled(isDeleting || isSigningOut)
                .buttonStyle(.plain)
            }

            // Version
            Section {
                LabeledContent("Version", value: "v\(appVersion) (\(buildNumber))")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .confirmationDialog("Sign Out?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { signOut() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete Account?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }

    // MARK: - App Row

    private func appRow(_ image: ImageResource, name: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 10) {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text(name)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func signOut() {
        isSigningOut = true
        Task {
            // TODO: Replace with actual sign-out logic
            // await userManager.signOut()
            try? await Task.sleep(for: .seconds(1))
            isSigningOut = false
        }
    }

    private func deleteAccount() {
        isDeleting = true
        Task {
            // TODO: Replace with actual account deletion logic
            // try await userManager.deleteAccount()
            try? await Task.sleep(for: .seconds(1))
            isDeleting = false
        }
    }
}

#Preview {
    SWSettingView()
        .frame(width: 600, height: 700)
}
