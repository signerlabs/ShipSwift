//
//  SWSettingView.swift
//  ShipSwift
//
//  Generic settings page template with language switching, share app, legal links,
//  recommended apps, and sign out / delete account sections.
//  Use directly as a NavigationStack page — no additional wrapping needed.
//
//  Usage:
//    // 1. Basic usage — embed directly in TabView or NavigationStack:
//    SWSettingView()
//
//    // 2. Customization points (modify the constants in this file):
//    //    - appStoreURL      → App Store URL for the share link
//    //    - termsURL         → Terms of Service URL
//    //    - privacyURL       → Privacy Policy URL
//    //    - appStoreFullpack / appStoreBrushmo / ...  → Recommended app links
//
//    // 3. Replace sign-out and delete-account logic:
//    //    Find the signOut() and deleteAccount() methods and replace the TODO comments with real implementations:
//    private func signOut() {
//        isSigningOut = true
//        Task {
//            await userManager.signOut()
//            isSigningOut = false
//        }
//    }
//
//    // 4. Language switching is based on @AppStorage("appLanguage"),
//    //    pair with SWDateExtension and similar utilities for global English/Chinese switching.
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWSettingView: View {
    
    // MARK: - State
    
    @AppStorage("appLanguage") private var appLanguage = "en"
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var isDeleting = false
    @State private var isSigningOut = false
    
    // MARK: - Configuration (modify these values directly)
    
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id123456789")!
    private let termsURL = URL(string: "https://shipswift.app/terms")!
    private let privacyURL = URL(string: "https://shipswift.app/privacy")!
    
    // App Store URLs (examples, replace with actual URLs)
    private let appStoreFullpack = "https://apps.apple.com/us/app/fullpack-packing-outfit/id6745692929"
    private let appStoreBrushmo = "https://apps.apple.com/us/app/brushmo/id6744569822"
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
                // MARK: - General Settings
                Section {
                    // Language switcher
                    Picker("Language", selection: $appLanguage) {
                        Text("English").tag("en")
                        Text("简体中文").tag("zh-Hans")
                    }
                    
                    // Share App
                    ShareLink(item: appStoreURL) {
                        HStack {
                            Text("Share App")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // MARK: - Legal
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
                
                // MARK: - Recommended Apps
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
                    Link(destination: URL(string: appStoreJourney)!) {
                        labelWithImage(.journeyLogo, name: "Journey - Goal Tracker & Diary")
                    }
                }
                
                // MARK: - Account Actions
                Section {
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        HStack {
                            Text("Sign Out")
                            if isSigningOut {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isDeleting || isSigningOut)
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Text("Delete Account")
                            if isDeleting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isDeleting || isSigningOut)
                }
                
                // MARK: - Version Info
                Section {
                    LabeledContent("Version") {
                        Text("v\(appVersion) (\(buildNumber))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }
    
    // MARK: - Label With Image

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

    // MARK: - Actions (replace with actual logic)
    
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
}
