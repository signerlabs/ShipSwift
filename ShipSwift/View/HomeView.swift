//
//  HomeView.swift
//  ShipSwift
//
//  Showcase App home page — hero section, Skills card, module overview grid,
//  and footer with link to shipswift.app.
//
//  Created by Wei Zhong on 14/2/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(SWStoreManager.self) private var storeManager
    @Environment(SWUserManager.self) private var userManager
    @Environment(\.openURL) private var openURL
    @Binding var selectedTab: String

    @State private var showPaywall = false
    @State private var copied = false

    private let skillsCommand = "npx skills add signerlabs/shipswift-skills"
    private let founderEmail = "wei@signerlabs.com"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    proStatusRow
                    skillsCard
                    linksRow
                    moduleGrid
                    founderServicesCard
                    footer
                }
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.never)
            .navigationTitle("tab.home")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SettingView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                ProPaywallView()
                    .environment(storeManager)
                    .environment(userManager)
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {
            SWShakingIcon(
                image: Image(.shipSwiftLogo),
                height: 120,
                cornerRadius: 16,
                idleDelay: 6
            )
            .padding(.vertical, 60)

            Text("home.subtitle")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("home.description")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Skills Card (Refined Terminal)

    private var skillsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // -- Header --
            HStack {
                // Terminal icon in gradient badge
                Image(systemName: "terminal.fill")
                    .foregroundStyle(.accent)
                
                Text("home.install")
            }
            .font(.headline)

            // -- Command block (tap to copy) --
            Button {
                #if os(iOS)
                UIPasteboard.general.string = skillsCommand
                #else
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(skillsCommand, forType: .string)
                #endif
                SWAlertManager.shared.show(.success, message: String(localized: "home.copied"))
                withAnimation(.easeInOut(duration: 0.2)) {
                    copied = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        copied = false
                    }
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    HStack(alignment: .top, spacing: 0) {
                        Text("$")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(Color(hue: 0.38, saturation: 0.7, brightness: 0.75))

                        Spacer(minLength: 6)

                        Text(skillsCommand)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .padding(.trailing, 24) // Leave room for the copy icon

                    // Copy / checkmark icon overlay
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(copied ? .green : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                        .padding(8)
                }
                .background(
                    Color.accentColor.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            }
            .buttonStyle(.plain)

            // -- Subtitle --
            Text("home.install.hint")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    // MARK: - Links Row

    private var linksRow: some View {
        HStack(spacing: 12) {
            Link(destination: URL(string: "https://shipswift.app")!) {
                Label("home.link.website", systemImage: "globe")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)

            Link(destination: URL(string: "https://github.com/signerlabs/ShipSwift")!) {
                Label("home.link.github", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
    }

    // MARK: - Pro Status Row

    private var proStatusRow: some View {
        Group {
            if storeManager.isPro {
                Label("home.pro.unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.secondary)
            } else {
                Button { showPaywall = true } label: {
                    Label("home.pro.unlock", systemImage: "lock.open.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Module Grid

    private var moduleGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ModuleCard(
                icon: "puzzlepiece.extension.fill",
                color: .blue,
                title: "Modules",
                subtitle: "Frameworks",
                description: "Auth, Camera, Face Camera, Chat, Paywall, Settings"
            ) { selectedTab = "modules" }

            ModuleCard(
                icon: "sparkles.tv.fill",
                color: .orange,
                title: "Animation",
                subtitle: "Components",
                description: "Transitions, Change Effects, Shimmer, and more"
            ) { selectedTab = "animation" }

            ModuleCard(
                icon: "chart.bar.fill",
                color: .green,
                title: "Charts",
                subtitle: "Components",
                description: "Line, Bar, Area, Donut, Radar, Scatter, and more"
            ) { selectedTab = "charts" }

            ModuleCard(
                icon: "square.grid.2x2.fill",
                color: .purple,
                title: "UI",
                subtitle: "Components",
                description: "Display, Feedback, Input — ready to use"
            ) { selectedTab = "ui" }
        }
    }

    // MARK: - Founder Services Card

    /// Custom development inquiry entry — pricing tier #4 on the website.
    /// Starting at $5,000, MVP delivered in 4 weeks. Tap CTA to compose a
    /// pre-filled inquiry email in the user's default mail client.
    private var founderServicesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title row — hammer icon in a soft circular gradient badge
            HStack(spacing: 12) {
                Image(systemName: "hammer.fill")
                    .font(.title3)
                    .foregroundStyle(.accent)
                    .frame(width: 36, height: 36)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.18),
                                Color.accentColor.opacity(0.05),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("founder.title")
                        .font(.headline)
                    Text("founder.tagline")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Price — SWStatusBadge capsule (info blue, translucent fill + stroke)
            SWStatusBadge(text: "founder.price", style: .info)

            // Features — SWBulletPointText with five distinct capsule colors
            VStack(alignment: .leading, spacing: 10) {
                SWBulletPointText(bulletColor: .blue) {
                    Text("founder.feature.platforms")
                        .font(.subheadline)
                }
                SWBulletPointText(bulletColor: .green) {
                    Text("founder.feature.backend")
                        .font(.subheadline)
                }
                SWBulletPointText(bulletColor: .orange) {
                    Text("founder.feature.integrations")
                        .font(.subheadline)
                }
                SWBulletPointText(bulletColor: .purple) {
                    Text("founder.feature.submission")
                        .font(.subheadline)
                }
                SWBulletPointText(bulletColor: .pink) {
                    Text("founder.feature.handover")
                        .font(.subheadline)
                }
            }
            .padding(.leading, 4)

            // SWGradientDivider — accent-tinted fade-out divider
            SWGradientDivider(color: .accentColor, opacity: 0.3, height: 1)
                .padding(.vertical, 2)

            // CTA — one-tap email to Founder Services
            Button {
                contactFounderServices()
            } label: {
                HStack {
                    Label("founder.cta", systemImage: "envelope.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.accent)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.accent)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
        )
    }

    /// Cross-platform card surface color. iOS gets the grouped-list secondary
    /// background; macOS falls back to the control background to match
    /// `Form` / `List` chrome on that platform.
    private var cardBackground: Color {
#if os(iOS)
        Color(.secondarySystemGroupedBackground)
#else
        Color(NSColor.controlBackgroundColor)
#endif
    }

    /// Build mailto URL with localized subject + body and open the default mail client.
    /// Subject and body are pulled from Localizable.xcstrings, so users on a Chinese system
    /// get a pre-filled Chinese inquiry template, and English-locale users get the English one.
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

    // MARK: - Footer

    private var footer: some View {
        Link(destination: URL(string: "https://shipswift.app")!) {
            Text("home.footer")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Module Card

private struct ModuleCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let description: String
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    #if canImport(UIKit)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    #else
                    .fill(Color(NSColor.controlBackgroundColor))
                    #endif
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HomeView(selectedTab: .constant("home"))
        .environment(SWStoreManager.shared)
        .environment(SWUserManager(skipAuthCheck: true))
        .swAlert()
}
