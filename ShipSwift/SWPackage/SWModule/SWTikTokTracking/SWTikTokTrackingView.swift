//
//  SWTikTokTrackingView.swift
//  ShipSwift
//
//  Informational page for the SWTikTokTracking module.
//  Explains TikTok App Events SDK integration features,
//  setup steps, supported events, and external resources.
//

import SwiftUI

struct SWTikTokTrackingView: View {

    var body: some View {
        List {
            overviewSection
            featuresSection
            integrationStepsSection
            supportedEventsSection
            resourcesSection
        }
        .navigationTitle("TikTok Tracking")
        .toolbarTitleDisplayMode(.inlineLarge)
    }

    // MARK: - Overview

    private var overviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ad Attribution & Conversion Tracking")
                    .font(.subheadline.weight(.semibold))
                Text("Integrate TikTok App Events SDK to measure ad campaign performance, track user conversions, and optimize ad spend with accurate attribution data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Overview")
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        Section {
            featureRow(icon: "hand.raised.fill", title: "ATT Permission Flow", description: "Built-in App Tracking Transparency request with proper timing")
            featureRow(icon: "chart.bar.fill", title: "Standard Event Tracking", description: "Subscribe, Purchase, ViewContent, and more")
            featureRow(icon: "sparkles", title: "Custom Event Tracking", description: "Track any app-specific event with custom properties")
            featureRow(icon: "arrow.triangle.branch", title: "SKAdNetwork Support", description: "Privacy-preserving attribution via Apple SKAdNetwork")
            featureRow(icon: "ladybug.fill", title: "Debug Mode", description: "Verbose logging for development and testing")
        } header: {
            Text("What You Get")
        }
    }

    // MARK: - Integration Steps

    private var integrationStepsSection: some View {
        Section {
            stepRow(number: 1, text: "Add TikTok Business SDK via Swift Package Manager")
            stepRow(number: 2, text: "Configure credentials in App init()")
            stepRow(number: 3, text: "Request ATT permission on app active")
            stepRow(number: 4, text: "Add event tracking at key touchpoints")
            stepRow(number: 5, text: "Test with TikTok SDK debug mode")
            stepRow(number: 6, text: "Submit to App Store with privacy compliance")
        } header: {
            Text("Integration Steps")
        }
    }

    // MARK: - Supported Events

    private var supportedEventsSection: some View {
        Section {
            ForEach(SWTikTokTrackingEvent.allCases, id: \.rawValue) { event in
                Label(event.rawValue, systemImage: "arrow.right.circle")
            }
        } header: {
            Text("Supported Events")
        } footer: {
            Text("Standard event types supported by TikTok Ads SDK. Custom events can also be tracked with arbitrary names.")
        }
    }

    // MARK: - Resources

    private var resourcesSection: some View {
        Section {
            Link(destination: URL(string: "https://ads.tiktok.com/help/article?aid=10028")!) {
                HStack {
                    Label("TikTok Events Manager", systemImage: "globe")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: URL(string: "https://github.com/tiktok/tiktok-business-ios-sdk")!) {
                HStack {
                    Label("TikTok Business SDK (GitHub)", systemImage: "chevron.left.forwardslash.chevron.right")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Resources")
        }
    }

    // MARK: - Row Builders

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        SWTikTokTrackingView()
    }
}
