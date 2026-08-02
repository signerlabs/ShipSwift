//
//  ModuleListView.swift
//  ShipSwift
//
//  Modules tab — showcases the multi-file framework modules:
//  Auth, Camera, Face Camera, Paywall, Chat, TikTok Tracking,
//  Subject Lifting, and Setting.
//
//  Created by Wei Zhong on 2/8/26.
//

import SwiftUI

struct ModuleListView: View {
    var body: some View {
        NavigationStack {
            List {
                // Auth demo — renders SWAuthView (iOS or macOS version automatically)
                ComponentNavigationLink {
                    SWAuthView(isDemo: true)
                        .environment(SWUserManager(skipAuthCheck: true))
                        .hideTabBar()
                } label: {
                    ListItem(
                        title: "Auth",
                        icon: "person.badge.key.fill",
                        description: "Complete auth flow: email sign-in/up, phone sign-in with country code picker, verification code, forgot/reset password, Apple & Google social sign-in."
                    )
                }

                // Camera demo — iOS only
                #if os(iOS)
                ComponentNavigationLink {
                    ComponentViewCameraDemo()
                        .swAlert()
                        .hideTabBar()
                } label: {
                    ListItem(
                        title: "Camera",
                        icon: "camera.fill",
                        description: "Full camera capture view with viewfinder overlay, pinch-to-zoom, zoom slider, photo library picker, and permission handling."
                    )
                }

                // Face Camera demo — iOS only
                ComponentNavigationLink {
                    ComponentViewFaceCameraDemo()
                        .hideTabBar()
                } label: {
                    ListItem(
                        title: "Face Camera",
                        icon: "face.smiling.inverse",
                        description: "Camera with real-time Vision face landmark detection, front/back switching, landmark overlay toggle, and configurable color schemes."
                    )
                }
                #endif

                // Paywall — Pro paywall with lifetime purchase
                ComponentNavigationLink {
                    SWPaywallView(isDemo: true)
                        .environment(SWStoreManager.shared)
                        .hideTabBar()
                } label: {
                    ListItem(
                        title: "Paywall",
                        icon: "creditcard.fill",
                        description: "Pro paywall with lifetime purchase, feature list, restore purchases, and sign-in for API key management."
                    )
                }

                // Chat demo — iOS only
                #if os(iOS)
                ComponentNavigationLink {
                    ComponentViewChatDemo()
                        .hideTabBar()
                } label: {
                    ListItem(
                        title: "Chat",
                        icon: "bubble.left.and.bubble.right.fill",
                        description: "Chat interface with message bubbles, text input, voice recording waveform, and simple echo response simulation."
                    )
                }
                #endif

                // TikTok Tracking demo — iOS only
                #if os(iOS)
                ComponentNavigationLink {
                    SWTikTokTrackingView()
                        .hideTabBar()
                } label: {
                    ListItem(
                        title: "TikTok Tracking",
                        icon: "chart.bar.xaxis.ascending",
                        description: "TikTok App Events SDK with ATT permission flow and event tracking for ad attribution."
                    )
                }
                #endif

                // Subject Lifting demo — iOS only
                #if os(iOS)
                ComponentNavigationLink {
                    SWSubjectLiftingView()
                        .hideTabBar()
                } label: {
                    ListItem(
                        title: "Subject Lifting",
                        icon: "person.and.background.dotted",
                        description: "Background removal using VisionKit ImageAnalyzer. Capture or pick a photo to extract the primary subject."
                    )
                }
                #endif

                // Settings module
                ComponentNavigationLink {
                    SWSettingView(isDemo: true)
                        .hideTabBar()
                } label: {
                    ListItem(
                        title: "Setting",
                        icon: "gearshape.fill",
                        description: "Generic settings page with language switch, share, legal links, and account actions. Pushed via NavigationLink."
                    )
                }
            }
            .navigationTitle("tab.modules")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

// MARK: - Preview

#Preview {
    ModuleListView()
        .environment(SWStoreManager.shared)
        .environment(SWUserManager(skipAuthCheck: true))
}
