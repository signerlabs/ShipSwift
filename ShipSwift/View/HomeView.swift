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
                VStack(spacing: 24) {
                    heroSection
                    proStatusRow
                    skillsCard
                    linksRow
                    moduleGrid
                    footer
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("ShipSwift")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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

            Text("AI-native iOS component library")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Production-ready SwiftUI components that LLMs can use to build real apps. Every component you see here is open-source.")
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
                
                Text("Install")
            }
            .font(.headline)

            // -- Command block (tap to copy) --
            Button {
                UIPasteboard.general.string = skillsCommand
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
                    .padding(.trailing, 24) // Leave room for the copy icon

                    // Copy / checkmark icon overlay
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(copied ? .green : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                        .padding(8)
                }
                .background(
                    Color(.systemGray6).opacity(0.6),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            }
            .buttonStyle(.plain)

            // -- Subtitle --
            Text("Works with Claude Code, Codex, Gemini, Cursor, Copilot, Windsurf, and all other AI tools.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    // MARK: - Links Row

    private var linksRow: some View {
        HStack(spacing: 12) {
            Link(destination: URL(string: "https://shipswift.app")!) {
                Label("Website", systemImage: "globe")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)

            Link(destination: URL(string: "https://github.com/signerlabs/ShipSwift")!) {
                Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
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
                title: "Component",
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
                    .fill(Color(.secondarySystemGroupedBackground))
            )
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
