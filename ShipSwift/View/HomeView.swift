//
//  HomeView.swift
//  ShipSwift
//
//  Showcase App home page — hero section, MCP card, module overview grid,
//  and footer with link to shipswift.app.
//
//  Created by Wei Zhong on 14/2/26.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: String

    // MCP command for clipboard copy
    private let mcpCommand = "claude mcp add --transport http shipswift https://api.shipswift.app/mcp"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    mcpCard
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

    // MARK: - MCP Card

    private var mcpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Connect via MCP", systemImage: "terminal.fill")
                .font(.headline)

            Text("Add ShipSwift to your AI assistant and start building production apps with a single command:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Copyable MCP command
            Button {
                UIPasteboard.general.string = mcpCommand
                SWAlertManager.shared.show(.success, message: "Copied to clipboard")
            } label: {
                Text(mcpCommand)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)

            Text("Pro Recipes available at shipswift.app")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
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
                count: "5 Frameworks",
                description: "Auth, Camera, Paywall, Chat, Settings"
            ) { selectedTab = "module" }

            ModuleCard(
                icon: "sparkles.tv.fill",
                color: .orange,
                title: "Animation",
                count: "9 Components",
                description: "Shimmer, TypewriterText, OrbitingLogos, and more"
            ) { selectedTab = "animation" }

            ModuleCard(
                icon: "chart.bar.fill",
                color: .green,
                title: "Chart",
                count: "8 Components",
                description: "Line, Bar, Area, Donut, Radar, Scatter, and more"
            ) { selectedTab = "chart" }

            ModuleCard(
                icon: "square.grid.2x2.fill",
                color: .purple,
                title: "Component",
                count: "15 Components",
                description: "Display, Feedback, Input — ready to use"
            ) { selectedTab = "component" }
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
    let count: String
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

                Text(count)
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
    HomeView(selectedTab: .constant("home"))
        .swAlert()
}
