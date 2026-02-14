//
//  SettingView.swift
//  ShipSwift
//
//  Settings page for the ShipSwift Showcase App.
//  Includes recommended apps, share, legal links, and version info.
//  Does not include auth features (sign-out, delete account, etc.).
//
//  Created by Wei Zhong on 13/2/26.
//

import SwiftUI

struct SettingView: View {
    
    // MARK: - Configuration
    
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id123456789")!
    private let termsURL = URL(string: "https://shipswift.app/terms")!
    private let privacyURL = URL(string: "https://shipswift.app/privacy")!
    
    // App Store links for recommended apps
    private let appStoreFullpack = "https://apps.apple.com/us/app/fullpack-packing-outfit/id6745692929"
    private let appStoreBrushmo = "https://apps.apple.com/us/app/brushmo/id6744569822"
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
                    Link(destination: URL(string: appStoreUtilityMax)!) {
                        labelWithImage(.utilityMaxLogo, name: "UtilityMax - Financial Simulator")
                    }
                    Link(destination: URL(string: appStoreJourney)!) {
                        labelWithImage(.journeyLogo, name: "Spark - Goal Tracker & Diary")
                    }
                }
                
                // MARK: - General Settings
                Section {
                    // Share app
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
                
                // MARK: - Version Info
                Section {
                    LabeledContent("Version") {
                        Text("v\(appVersion) (\(buildNumber))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.inlineLarge)
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
}

#Preview {
    SettingView()
}
