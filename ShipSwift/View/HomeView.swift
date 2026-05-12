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
    @Binding var selectedTab: String
    @Binding var scrollTarget: String?

    @State private var showPaywall = false
    @State private var copied = false

    private let skillsCommand = "npx skills add signerlabs/shipswift-skills"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SWSpacing.sectionGap) {
                    heroSection
                    proStatusRow
                    skillsCard
                    linksRow
                    moduleGrid
                    footer
                }
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, SWSpacing.pageBottomInset)
            }
            .scrollIndicators(.never)
            .navigationTitle("ShipSwift")
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
        VStack(spacing: 14) {
            SWShakingIcon(
                image: Image(.shipSwiftLogo),
                height: 120,
                cornerRadius: 16,
                idleDelay: 6
            )
            .padding(.vertical, 48)

            Text("AI-native iOS component library")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Production-ready SwiftUI components LLMs can use to build real apps. Every one is open-source.")
                .font(.swBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Skills Card (Refined Terminal)

    private var skillsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // -- Header --
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundStyle(.accent)

                Text("Install")
            }
            .font(.swCardTitle)

            // -- Command block (tap to copy) --
            Button {
                #if os(iOS)
                UIPasteboard.general.string = skillsCommand
                #else
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(skillsCommand, forType: .string)
                #endif
                SWAlertManager.shared.show(.success, message: "Copied to clipboard")
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
                    .padding(.trailing, 24)

                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(copied ? .green : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                        .padding(8)
                }
                .background(
                    Color.accentColor.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            Text("Works with Claude Code, Codex, Gemini, Cursor, Copilot, Windsurf, and all other AI tools.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .swCardStyle()
    }

    // MARK: - Links Row

    private var linksRow: some View {
        HStack(spacing: 24) {
            Link(destination: URL(string: "https://shipswift.app")!) {
                Label("Website", systemImage: "globe")
                    .font(.subheadline)
            }

            Link(destination: URL(string: "https://github.com/signerlabs/ShipSwift")!) {
                Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.subheadline)
            }
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pro Status Row

    private var proStatusRow: some View {
        Group {
            if storeManager.isPro {
                Label("Pro Recipes unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.secondary)
            } else {
                Button { showPaywall = true } label: {
                    Label("Unlock Pro Recipes", systemImage: "lock.open.fill")
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
                title: "Module",
                subtitle: "Frameworks",
                description: "Auth, Camera, Face Camera, Chat, Paywall, Settings"
            ) { selectedTab = "component"; scrollTarget = "module" }

            ModuleCard(
                icon: "sparkles.tv.fill",
                color: .orange,
                title: "Animation",
                subtitle: "Components",
                description: "Shimmer, TypewriterText, OrbitingLogos, and more"
            ) { selectedTab = "component"; scrollTarget = "animation" }

            ModuleCard(
                icon: "chart.bar.fill",
                color: .green,
                title: "Chart",
                subtitle: "Components",
                description: "Line, Bar, Area, Donut, Radar, Scatter, and more"
            ) { selectedTab = "component"; scrollTarget = "chart" }

            ModuleCard(
                icon: "square.grid.2x2.fill",
                color: .purple,
                title: "Toolkit",
                subtitle: "Components",
                description: "Display, Feedback, Input — ready to use"
            ) { selectedTab = "component"; scrollTarget = "display" }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Link(destination: URL(string: "https://shipswift.app")!) {
            Text("Made with \u{2661} by SignerLabs")
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
            VStack(alignment: .leading, spacing: SWSpacing.iconTitleGap) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.bottom, 2)

                Text(title)
                    .font(.swCardTitle)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(description)
                    .font(.swMeta)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .swCardStyle(cornerRadius: 12, padding: 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HomeView(selectedTab: .constant("home"), scrollTarget: .constant(nil))
        .environment(SWStoreManager.shared)
        .environment(SWUserManager(skipAuthCheck: true))
        .swAlert()
}
