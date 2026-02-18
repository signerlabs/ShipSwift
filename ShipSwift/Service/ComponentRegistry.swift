//
//  ComponentRegistry.swift
//  ShipSwift
//
//  Maps 38 component IDs to SwiftUI views for chat-inline previews
//  and full-screen demos. Used by ChatView to render real components
//  inside chat bubbles when the AI recommends a component.
//
//  Created by Wei Zhong on 18/2/26.
//

import SwiftUI
import Charts

// MARK: - Component Entry

/// Metadata and view factories for a single registered component.
struct ComponentEntry {
    let title: String
    let icon: String
    let description: String
    /// Compact preview for chat bubble (max width ~280pt, max height ~300pt)
    let preview: () -> AnyView
    /// Full demo view for fullscreen/sheet presentation
    let fullView: () -> AnyView
    /// Presentation style for the full view
    let presentation: ComponentPresentation
}

/// How the full view should be presented.
enum ComponentPresentation {
    case push
    case sheet
    case fullScreenCover
}

// MARK: - Component Registry

/// Central registry mapping component IDs to SwiftUI views.
///
/// Provides three lookups:
/// - `view(for:)` — compact preview for chat bubble embedding
/// - `fullView(for:)` — full demo view for expanded presentation
/// - `title(for:)` — display name
struct ComponentRegistry {

    /// All registered components keyed by ID.
    let entries: [String: ComponentEntry] = Self.buildRegistry()

    /// Compact preview view for embedding in a chat bubble.
    func view(for id: String) -> AnyView? {
        entries[id]?.preview()
    }

    /// Full demo view for expanded presentation.
    func fullView(for id: String) -> AnyView? {
        entries[id]?.fullView()
    }

    /// Display title for a component.
    func title(for id: String) -> String {
        entries[id]?.title ?? id
    }

    /// Presentation style for the full view.
    func presentation(for id: String) -> ComponentPresentation {
        entries[id]?.presentation ?? .push
    }

    /// Icon SF Symbol name.
    func icon(for id: String) -> String {
        entries[id]?.icon ?? "square.grid.2x2"
    }

    /// Short description.
    func description(for id: String) -> String {
        entries[id]?.description ?? ""
    }

    // MARK: - Registry Builder

    private static func buildRegistry() -> [String: ComponentEntry] {
        var reg: [String: ComponentEntry] = [:]

        // -- Module (6) --

        reg["auth"] = ComponentEntry(
            title: "Auth",
            icon: "person.badge.key.fill",
            description: "Complete auth flow with email, phone, Apple & Google sign-in",
            preview: {
                AnyView(
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.key.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.accent)
                        Text("Auth Module")
                            .font(.headline)
                        Text("Email / Phone / Apple / Google sign-in with verification flow")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: { AnyView(NavigationStack { ComponentDemoViews.authDemo() }) },
            presentation: .fullScreenCover
        )

        reg["camera"] = ComponentEntry(
            title: "Camera",
            icon: "camera.fill",
            description: "Full camera capture with viewfinder overlay, zoom, and photo picker",
            preview: {
                AnyView(
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.accent)
                        Text("Camera Module")
                            .font(.headline)
                        Text("Viewfinder overlay, pinch-to-zoom, photo library picker")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: { AnyView(ComponentDemoViews.cameraDemo().swAlert()) },
            presentation: .fullScreenCover
        )

        reg["face-camera"] = ComponentEntry(
            title: "Face Camera",
            icon: "face.smiling.inverse",
            description: "Camera with real-time Vision face landmark detection",
            preview: {
                AnyView(
                    VStack(spacing: 12) {
                        Image(systemName: "face.smiling.inverse")
                            .font(.system(size: 36))
                            .foregroundStyle(.accent)
                        Text("Face Camera")
                            .font(.headline)
                        Text("Vision face landmark detection with front/back switching")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: { AnyView(ComponentDemoViews.faceCameraDemo()) },
            presentation: .fullScreenCover
        )

        reg["paywall"] = ComponentEntry(
            title: "Paywall",
            icon: "creditcard.fill",
            description: "Subscription paywall with monthly/yearly options and feature list",
            preview: {
                AnyView(
                    VStack(spacing: 8) {
                        Image(.shipSwiftLogo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("ShipSwift Pro")
                            .font(.headline)
                        Text("$59.99/year")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.accent)
                                .imageScale(.small)
                            Text("Full-stack iOS + AWS backend")
                                .font(.caption)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "terminal.fill")
                                .foregroundStyle(.accent)
                                .imageScale(.small)
                            Text("One MCP command, instant access")
                                .font(.caption)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: { AnyView(ComponentDemoViews.paywallDemo()) },
            presentation: .sheet
        )

        reg["chat"] = ComponentEntry(
            title: "Chat",
            icon: "bubble.left.and.bubble.right.fill",
            description: "Chat interface with message bubbles and text input",
            preview: {
                AnyView(
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.accent)
                        Text("Chat Module")
                            .font(.headline)
                        Text("Message bubbles, text input, voice recording waveform")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: { AnyView(NavigationStack { ComponentDemoViews.chatDemo() }) },
            presentation: .fullScreenCover
        )

        reg["setting"] = ComponentEntry(
            title: "Setting",
            icon: "gearshape.fill",
            description: "Generic settings page with language switch, share, and legal links",
            preview: {
                AnyView(
                    VStack(spacing: 8) {
                        ForEach(["Language", "Share App", "Privacy Policy"], id: \.self) { item in
                            HStack {
                                Text(item)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            if item != "Privacy Policy" { Divider() }
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: { AnyView(SWSettingView()) },
            presentation: .push
        )

        // -- Animation (9) --

        reg["before-after-slider"] = ComponentEntry(
            title: "Before / After Slider",
            icon: "slider.horizontal.below.rectangle",
            description: "Draggable image comparison slider with auto-oscillation",
            preview: {
                AnyView(
                    SWBeforeAfterSlider(
                        before: Image(.smileBefore),
                        after: Image(.smileAfter)
                    )
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
            },
            fullView: {
                AnyView(
                    SWBeforeAfterSlider(
                        before: Image(.smileBefore),
                        after: Image(.smileAfter)
                    )
                    .padding()
                )
            },
            presentation: .push
        )

        reg["typewriter-text"] = ComponentEntry(
            title: "Typewriter Text",
            icon: "character.cursor.ibeam",
            description: "Typing and deleting text animation with multiple styles",
            preview: {
                AnyView(
                    SWTypewriterText(
                        texts: ["Level up your smile game", "AI-powered smile analysis"],
                        animationStyle: .spring
                    )
                    .font(.headline)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
            },
            fullView: {
                AnyView(
                    VStack(spacing: 26) {
                        SWTypewriterText(
                            texts: ["Level up your smile game", "AI-powered smile analysis", "Join the glow up era"],
                            animationStyle: .spring
                        )
                        .font(.title3.weight(.semibold))
                        SWTypewriterText(
                            texts: ["Hello World", "Welcome Back", "Let's Go"],
                            animationStyle: .spring,
                            gradient: LinearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing)
                        )
                        .font(.title.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                )
            },
            presentation: .push
        )

        reg["shaking-icon"] = ComponentEntry(
            title: "Shaking Icon",
            icon: "iphone.radiowaves.left.and.right",
            description: "Periodically zooms in and shakes, mimicking iOS jiggle effect",
            preview: {
                AnyView(
                    SWShakingIcon(image: Image(.shipSwiftLogo), height: 60, cornerRadius: 8)
                        .frame(maxWidth: .infinity)
                        .padding()
                )
            },
            fullView: {
                AnyView(
                    VStack(spacing: 40) {
                        SWShakingIcon(image: Image(systemName: "apple.logo"), height: 20)
                        SWShakingIcon(image: Image(.smileAfter), height: 100, cornerRadius: 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            },
            presentation: .push
        )

        reg["shimmer"] = ComponentEntry(
            title: "Shimmer",
            icon: "light.max",
            description: "Translucent light band sweep for buttons and skeleton loaders",
            preview: {
                AnyView(
                    SWShimmer {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 60)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: {
                AnyView(
                    VStack(spacing: 30) {
                        SWShimmer {
                            Button {} label: {
                                Text("Upgrade Now")
                                    .font(.largeTitle)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        SWShimmer {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.gray.opacity(0.3))
                                .frame(width: 280, height: 120)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            },
            presentation: .push
        )

        reg["glow-sweep"] = ComponentEntry(
            title: "Glow Sweep",
            icon: "wand.and.rays",
            description: "Sweeps a glowing highlight using content shape as mask",
            preview: {
                AnyView(
                    SWGlowSweep {
                        Text("Start Scan Today")
                            .font(.title2.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                )
            },
            fullView: {
                AnyView(
                    VStack(spacing: 26) {
                        SWGlowSweep {
                            Text("Start Scan Today")
                                .font(.largeTitle.bold())
                        }
                        SWGlowSweep(baseColor: .accentColor, glowColor: .white, duration: 1.5) {
                            Text("Analyzing...")
                                .font(.title2.bold())
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            },
            presentation: .push
        )

        reg["light-sweep"] = ComponentEntry(
            title: "Light Sweep",
            icon: "light.beacon.max",
            description: "Gradient light band that sweeps across content",
            preview: {
                AnyView(
                    SWLightSweep {
                        Image(.smileAfter)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                )
            },
            fullView: {
                AnyView(
                    VStack(spacing: 26) {
                        SWLightSweep {
                            Image(.smileAfter)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180)
                        }
                        SWLightSweep(lineWidth: 120, duration: 0.5, cornerRadius: 20) {
                            Image(.smileAfter)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            },
            presentation: .push
        )

        reg["scanning-overlay"] = ComponentEntry(
            title: "Scanning Overlay",
            icon: "barcode.viewfinder",
            description: "Grid lines, sweep band, and noise layer overlay",
            preview: {
                AnyView(
                    SWScanningOverlay {
                        Image(.facePicture)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                )
            },
            fullView: {
                AnyView(
                    VStack(spacing: 20) {
                        SWScanningOverlay {
                            Image(.facePicture)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            },
            presentation: .push
        )

        reg["animated-mesh-gradient"] = ComponentEntry(
            title: "Animated Mesh Gradient",
            icon: "circle.hexagongrid.fill",
            description: "3x3 mesh gradient background with color palette transitions",
            preview: {
                AnyView(
                    SWAnimatedMeshGradient()
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
            },
            fullView: {
                AnyView(
                    SWAnimatedMeshGradient()
                        .ignoresSafeArea()
                )
            },
            presentation: .push
        )

        reg["orbiting-logos"] = ComponentEntry(
            title: "Orbiting Logos",
            icon: "atom",
            description: "SpriteKit-powered concentric rings with orbiting icons",
            preview: {
                AnyView(
                    SWOrbitingLogos(
                        images: ["airpods", "business-shoes", "sunglasses", "tshirt", "wide-brimmed-hat", "golf-gloves", "suit", "golf-gloves"]
                    ) {
                        Image(.fullpackLogo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .offset(y: -3)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: {
                AnyView(
                    VStack {
                        SWOrbitingLogos(
                            images: ["airpods", "business-shoes", "sunglasses", "tshirt", "wide-brimmed-hat", "golf-gloves", "suit", "golf-gloves"]
                        ) {
                            Image(.fullpackLogo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .offset(y: -5)
                        }
                    }
                )
            },
            presentation: .push
        )

        // -- Chart (8) --

        reg["line-chart"] = ComponentEntry(
            title: "Line Chart",
            icon: "chart.xyaxis.line",
            description: "Multi-series line chart with scrolling and reference lines",
            preview: { AnyView(ChartPreviews.lineChart) },
            fullView: { AnyView(ChartPreviews.lineChartFull) },
            presentation: .push
        )

        reg["bar-chart"] = ComponentEntry(
            title: "Bar Chart",
            icon: "chart.bar.fill",
            description: "Grouped or stacked bar chart with horizontal scrolling",
            preview: { AnyView(ChartPreviews.barChart) },
            fullView: { AnyView(ChartPreviews.barChartFull) },
            presentation: .push
        )

        reg["area-chart"] = ComponentEntry(
            title: "Area Chart",
            icon: "chart.line.uptrend.xyaxis",
            description: "Standard or stacked area chart with smooth interpolation",
            preview: { AnyView(ChartPreviews.areaChart) },
            fullView: { AnyView(ChartPreviews.areaChartFull) },
            presentation: .push
        )

        reg["scatter-chart"] = ComponentEntry(
            title: "Scatter Chart",
            icon: "chart.dots.scatter",
            description: "Scrollable scatter chart with generic category types",
            preview: { AnyView(ChartPreviews.scatterChart) },
            fullView: { AnyView(ChartPreviews.scatterChartFull) },
            presentation: .push
        )

        reg["donut-chart"] = ComponentEntry(
            title: "Donut Chart",
            icon: "chart.pie.fill",
            description: "Interactive donut chart with tap-to-select categories",
            preview: { AnyView(ChartPreviews.donutChart) },
            fullView: { AnyView(ChartPreviews.donutChartFull) },
            presentation: .push
        )

        reg["radar-chart"] = ComponentEntry(
            title: "Radar Chart",
            icon: "pentagon",
            description: "Animated radar chart with axis labels and grid rings",
            preview: { AnyView(ChartPreviews.radarChart) },
            fullView: { AnyView(ChartPreviews.radarChartFull) },
            presentation: .push
        )

        reg["ring-chart"] = ComponentEntry(
            title: "Ring Chart",
            icon: "circle.circle",
            description: "Activity Rings style concentric ring progress chart",
            preview: { AnyView(ChartPreviews.ringChart) },
            fullView: { AnyView(ChartPreviews.ringChartFull) },
            presentation: .push
        )

        reg["activity-heatmap"] = ComponentEntry(
            title: "Activity Heatmap",
            icon: "square.grid.3x3.fill",
            description: "GitHub-style activity heatmap with streak tracking",
            preview: { AnyView(ChartPreviews.activityHeatmap) },
            fullView: { AnyView(ChartPreviews.activityHeatmapFull) },
            presentation: .push
        )

        // -- Display (9) --

        reg["floating-labels"] = ComponentEntry(
            title: "Floating Labels",
            icon: "tag.fill",
            description: "Animated floating capsule labels over an image",
            preview: {
                AnyView(
                    SWFloatingLabels(
                        image: Image(.facePicture),
                        labels: [
                            .init(text: "Teeth mapping", position: CGPoint(x: 0.3, y: 0.5)),
                            .init(text: "Plaque detection", position: CGPoint(x: 0.9, y: 0.6)),
                        ]
                    )
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
            },
            fullView: {
                AnyView(
                    SWFloatingLabels(
                        image: Image(.facePicture),
                        labels: [
                            .init(text: "Teeth mapping", position: CGPoint(x: 0.3, y: 0.5)),
                            .init(text: "Plaque detection", position: CGPoint(x: 0.9, y: 0.6)),
                            .init(text: "Shape & balance", position: CGPoint(x: 0.5, y: 0.8)),
                        ]
                    )
                )
            },
            presentation: .push
        )

        reg["scrolling-faq"] = ComponentEntry(
            title: "Scrolling FAQ",
            icon: "bubble.left.and.text.bubble.right",
            description: "Auto-scrolling horizontal FAQ carousel",
            preview: {
                AnyView(
                    SWScrollingFAQ(
                        rows: [
                            ["How does AI work?", "What can I ask?", "How accurate?"],
                            ["Write an email", "Summarize article", "Translate text"],
                        ],
                        title: "Let's talk"
                    ) { _ in }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
            },
            fullView: {
                AnyView(
                    SWScrollingFAQ(
                        rows: [
                            ["How does AI work?", "What can I ask?", "How accurate?", "Help with coding?",
                             "Remember chat?", "Languages supported?", "Get started?", "Explain topics?"],
                            ["Write an email", "Summarize article", "Translate text", "Creative ideas",
                             "Debug code", "Explain concept", "Meal plan", "Brainstorm"],
                        ],
                        title: "Let's talk about new topics"
                    ) { _ in }
                )
            },
            presentation: .push
        )

        reg["rotating-quote"] = ComponentEntry(
            title: "Rotating Quote",
            icon: "text.quote",
            description: "Auto-rotating quote display with author attribution",
            preview: {
                AnyView(
                    SWRotatingQuote(
                        quotes: [
                            "Stay hungry, stay foolish.",
                            "The only way to do great work is to love what you do."
                        ],
                        author: "Steve Jobs"
                    )
                    .frame(height: 100)
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: {
                AnyView(
                    ScrollView {
                        VStack(spacing: 32) {
                            SWRotatingQuote(
                                quotes: [
                                    "Stay hungry, stay foolish.",
                                    "The only way to do great work is to love what you do.",
                                    "Innovation distinguishes between a leader and a follower."
                                ],
                                author: "Steve Jobs"
                            )
                            .frame(height: 140)
                        }
                        .padding()
                    }
                )
            },
            presentation: .push
        )

        reg["bullet-point-text"] = ComponentEntry(
            title: "Bullet Point Text",
            icon: "list.bullet",
            description: "Colored capsule bullet indicator with custom content",
            preview: {
                AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        SWBulletPointText(bulletColor: .blue) { Text("Wealth") }
                        SWBulletPointText(bulletColor: .green) { Text("Health") }
                        SWBulletPointText(bulletColor: .orange) { Text("Happiness") }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
            },
            fullView: {
                AnyView(
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            SWBulletPointText(bulletColor: .blue) { Text("Wealth") }
                            SWBulletPointText(bulletColor: .green) { Text("Health") }
                            SWBulletPointText(bulletColor: .orange) { Text("Happiness") }
                            SWBulletPointText(bulletColor: .purple) { Text("Wisdom") }
                        }
                        .padding()
                    }
                )
            },
            presentation: .push
        )

        reg["gradient-divider"] = ComponentEntry(
            title: "Gradient Divider",
            icon: "minus",
            description: "Gradient divider with configurable color and opacity",
            preview: {
                AnyView(
                    VStack(spacing: 16) {
                        SWGradientDivider()
                        SWGradientDivider(color: .purple, opacity: 0.5)
                        SWGradientDivider(color: .mint, height: 2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: {
                AnyView(
                    VStack(spacing: 20) {
                        SWGradientDivider()
                        SWGradientDivider(color: .purple, opacity: 0.5)
                        SWGradientDivider(color: .mint, height: 2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            },
            presentation: .push
        )

        reg["label"] = ComponentEntry(
            title: "Label",
            icon: "tag",
            description: "Reusable label components with icon and image variants",
            preview: {
                AnyView(
                    VStack(alignment: .leading, spacing: 6) {
                        SWLabelWithIcon()
                        SWLabelWithIcon(icon: "gearshape", bg: .orange, name: "Settings")
                        SWLabelWithIcon(icon: "bell.badge", bg: .red, name: "Notifications")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
            },
            fullView: {
                AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        SWLabelWithIcon()
                        SWLabelWithIcon(icon: "gearshape", bg: .orange, name: "Settings")
                        SWLabelWithIcon(icon: "bell.badge", bg: .red, name: "Notifications")
                        SWLabelWithIcon(icon: "lock.shield", bg: .green, name: "Privacy")
                        SWLabelWithIcon(icon: "creditcard", bg: .purple, name: "Subscription")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                )
            },
            presentation: .push
        )

        reg["onboarding-view"] = ComponentEntry(
            title: "Onboarding",
            icon: "hand.wave.fill",
            description: "Multi-page welcome flow with swipe navigation and skip",
            preview: {
                AnyView(
                    VStack(spacing: 12) {
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.accent)
                        Text("Onboarding View")
                            .font(.headline)
                        Text("Multi-page swipe flow with skip support")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: { AnyView(OnboardingDemoWrapper()) },
            presentation: .fullScreenCover
        )

        reg["order-view"] = ComponentEntry(
            title: "Order",
            icon: "cup.and.saucer.fill",
            description: "Animated drink customization demo with flavor/size selectors",
            preview: {
                AnyView(
                    VStack(spacing: 12) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.brown)
                        Text("Order View")
                            .font(.headline)
                        Text("Animated drink customization with cup animations")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: { AnyView(OrderDemoWrapper()) },
            presentation: .fullScreenCover
        )

        reg["root-tab-view"] = ComponentEntry(
            title: "Tab",
            icon: "rectangle.split.3x1.fill",
            description: "TabView template with selected/unselected icons",
            preview: {
                AnyView(
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.split.3x1.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.accent)
                        Text("Tab View Template")
                            .font(.headline)
                        Text("iOS 18+ TabView with haptic feedback")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: { AnyView(SWRootTabView()) },
            presentation: .sheet
        )

        // -- Feedback (3) --

        reg["alert"] = ComponentEntry(
            title: "SWAlert",
            icon: "bell.badge",
            description: "Toast-style alert with four presets and custom styling",
            preview: {
                AnyView(
                    VStack(spacing: 8) {
                        ForEach(["Info", "Success", "Warning", "Error"], id: \.self) { type in
                            Text(type)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(alertColor(for: type).opacity(0.15))
                                .foregroundStyle(alertColor(for: type))
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: {
                AnyView(
                    VStack(spacing: 12) {
                        Spacer()
                        VStack(spacing: 10) {
                            Button { SWAlertManager.shared.show(.info, message: "Info message") } label: {
                                Label("Info", systemImage: "info.circle.fill").frame(maxWidth: .infinity, alignment: .leading)
                            }.tint(.primary)
                            Button { SWAlertManager.shared.show(.success, message: "Success") } label: {
                                Label("Success", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity, alignment: .leading)
                            }.tint(.green)
                            Button { SWAlertManager.shared.show(.warning, message: "Warning") } label: {
                                Label("Warning", systemImage: "exclamationmark.triangle.fill").frame(maxWidth: .infinity, alignment: .leading)
                            }.tint(.orange)
                            Button { SWAlertManager.shared.show(.error, message: "Error") } label: {
                                Label("Error", systemImage: "xmark.circle.fill").frame(maxWidth: .infinity, alignment: .leading)
                            }.tint(.red)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                )
            },
            presentation: .push
        )

        reg["loading"] = ComponentEntry(
            title: "SWLoading",
            icon: "hourglass",
            description: "Fullscreen loading overlay with blur and optional icon",
            preview: {
                AnyView(
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading data...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: {
                AnyView(
                    ZStack {
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text("Page Content").font(.largeTitle).foregroundStyle(.white)
                            Button("Show Loading") {
                                SWLoadingManager.shared.show(page: .home, message: "Loading data...")
                                Task {
                                    try? await Task.sleep(for: .seconds(2))
                                    SWLoadingManager.shared.hide(page: .home)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .swPageLoading(.home)
                )
            },
            presentation: .push
        )

        reg["thinking-indicator"] = ComponentEntry(
            title: "SWThinkingIndicator",
            icon: "ellipsis.bubble",
            description: "Animated three-dot bouncing indicator for chat typing states",
            preview: {
                AnyView(
                    HStack(spacing: 4) {
                        Text("Thinking")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        SWThinkingIndicator()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: {
                AnyView(
                    VStack(spacing: 40) {
                        SWThinkingIndicator()
                        SWThinkingIndicator(dotSize: 10, dotColor: .blue, spacing: 6)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            },
            presentation: .push
        )

        // -- Input (3) --

        reg["tab-button"] = ComponentEntry(
            title: "SWTabButton",
            icon: "rectangle.compress.vertical",
            description: "Capsule-shaped tab button for segmented controls",
            preview: {
                AnyView(
                    HStack {
                        SWTabButton(title: "All", isSelected: true) {}
                        SWTabButton(title: "Recent", isSelected: false) {}
                        SWTabButton(title: "Trending", isSelected: false) {}
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: { AnyView(TabButtonFullDemo()) },
            presentation: .push
        )

        reg["stepper"] = ComponentEntry(
            title: "SWStepper",
            icon: "minus.forwardslash.plus",
            description: "Compact numeric stepper with animated transitions",
            preview: { AnyView(StepperPreviewWrapper()) },
            fullView: { AnyView(StepperFullDemo()) },
            presentation: .push
        )

        reg["add-sheet"] = ComponentEntry(
            title: "SWAddSheet",
            icon: "plus.rectangle.on.rectangle",
            description: "Bottom sheet with text input for collecting user input",
            preview: {
                AnyView(
                    VStack(spacing: 12) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                            .font(.system(size: 36))
                            .foregroundStyle(.accent)
                        Text("Add Sheet")
                            .font(.headline)
                        Text("Bottom sheet with text input and confirm button")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                )
            },
            fullView: { AnyView(AddSheetFullDemo()) },
            presentation: .push
        )

        return reg
    }

    // MARK: - Alert Color Helper

    private static func alertColor(for type: String) -> Color {
        switch type {
        case "Info": return .primary
        case "Success": return .green
        case "Warning": return .orange
        case "Error": return .red
        default: return .primary
        }
    }
}

// MARK: - Module Demo View Factories

/// Factory methods for module demo views.
/// These create the same demo views used in ComponentView but accessible
/// from outside for the ComponentRegistry and ChatView.
enum ComponentDemoViews {
    @ViewBuilder
    static func authDemo() -> some View {
        ComponentViewAuthDemo()
    }

    @ViewBuilder
    static func cameraDemo() -> some View {
        ComponentViewCameraDemo()
    }

    @ViewBuilder
    static func faceCameraDemo() -> some View {
        SWFaceCameraView()
    }

    @ViewBuilder
    static func paywallDemo() -> some View {
        ComponentViewPaywallDemo()
    }

    @ViewBuilder
    static func chatDemo() -> some View {
        ComponentViewChatDemo()
    }
}

// MARK: - Chart Preview Data Helpers

/// Pre-built chart views for compact previews and full demos.
private enum ChartPreviews {

    // MARK: - Line Chart

    static var lineChart: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let data: [SWLineChart<String>.DataPoint] = (0..<7).flatMap { (dayOffset: Int) -> [SWLineChart<String>.DataPoint] in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            return [
                SWLineChart<String>.DataPoint(date: date, value: Double.random(in: 40...90), category: "Revenue"),
            ]
        }
        return SWLineChart(dataPoints: data, colorMapping: ["Revenue": .blue], chartHeight: 160, title: "Revenue")
            .padding(.horizontal)
    }

    static var lineChartFull: some View {
        ScrollView {
            VStack(spacing: 32) {
                Group {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let data: [SWLineChart<String>.DataPoint] = (0..<14).flatMap { (dayOffset: Int) -> [SWLineChart<String>.DataPoint] in
                        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                        return [
                            .init(date: date, value: Double.random(in: 40...90), category: "Revenue"),
                            .init(date: date, value: Double.random(in: 20...60), category: "Cost"),
                        ]
                    }
                    SWLineChart(dataPoints: data, colorMapping: ["Revenue": .blue, "Cost": .red], title: "Revenue vs Cost")
                }
            }
            .padding()
        }
    }

    // MARK: - Bar Chart

    static var barChart: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let data: [SWBarChart<String>.DataPoint] = (0..<5).flatMap { (dayOffset: Int) -> [SWBarChart<String>.DataPoint] in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            return [
                .init(date: date, value: Double.random(in: 50...150), category: "Online"),
                .init(date: date, value: Double.random(in: 30...100), category: "Offline"),
            ]
        }
        return SWBarChart(dataPoints: data, colorMapping: ["Online": .blue, "Offline": .orange], visibleDays: 5, chartHeight: 160, title: "Sales")
            .padding(.horizontal)
    }

    static var barChartFull: some View {
        ScrollView {
            VStack(spacing: 32) {
                Group {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let data: [SWBarChart<String>.DataPoint] = (0..<10).flatMap { (dayOffset: Int) -> [SWBarChart<String>.DataPoint] in
                        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                        return [
                            .init(date: date, value: Double.random(in: 50...150), category: "Online"),
                            .init(date: date, value: Double.random(in: 30...100), category: "Offline"),
                        ]
                    }
                    SWBarChart(dataPoints: data, colorMapping: ["Online": .blue, "Offline": .orange], title: "Sales by Channel")
                }
            }
            .padding()
        }
    }

    // MARK: - Area Chart

    static var areaChart: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let data: [SWAreaChart<String>.DataPoint] = (0..<7).flatMap { (dayOffset: Int) -> [SWAreaChart<String>.DataPoint] in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            return [
                .init(date: date, value: Double.random(in: 100...300), category: "Organic"),
            ]
        }
        return SWAreaChart(dataPoints: data, colorMapping: ["Organic": .green], gradientOpacity: 0.25, visibleDays: 7, chartHeight: 160, title: "Traffic")
            .padding(.horizontal)
    }

    static var areaChartFull: some View {
        ScrollView {
            VStack(spacing: 32) {
                Group {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let data: [SWAreaChart<String>.DataPoint] = (0..<14).flatMap { (dayOffset: Int) -> [SWAreaChart<String>.DataPoint] in
                        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                        return [
                            .init(date: date, value: Double.random(in: 100...300), category: "Organic"),
                            .init(date: date, value: Double.random(in: 50...200), category: "Paid"),
                        ]
                    }
                    SWAreaChart(dataPoints: data, colorMapping: ["Organic": .green, "Paid": .blue], gradientOpacity: 0.25, title: "Website Traffic")
                }
            }
            .padding()
        }
    }

    // MARK: - Scatter Chart

    static var scatterChart: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let data: [SWScatterChart<String>.DataPoint] = [
            .init(date: calendar.date(byAdding: .hour, value: 8, to: today)!, value: 85, category: "Teeth"),
            .init(date: calendar.date(byAdding: .hour, value: 12, to: today)!, value: 52, category: "Food"),
            .init(date: calendar.date(byAdding: .day, value: -1, to: today)!, value: 72, category: "Teeth"),
            .init(date: calendar.date(byAdding: .day, value: -2, to: today)!, value: 90, category: "Teeth"),
        ]
        return SWScatterChart(dataPoints: data, colorMapping: ["Teeth": .blue, "Food": .orange], visibleDays: 3, chartHeight: 160, title: "Scans")
            .padding(.horizontal)
    }

    static var scatterChartFull: some View {
        ScrollView {
            VStack(spacing: 32) {
                Group {
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let data: [SWScatterChart<String>.DataPoint] = [
                        .init(date: calendar.date(byAdding: .hour, value: 8, to: today)!, value: 85, category: "Teeth"),
                        .init(date: calendar.date(byAdding: .hour, value: 12, to: today)!, value: 52, category: "Food"),
                        .init(date: calendar.date(byAdding: .hour, value: 18, to: today)!, value: 78, category: "Food"),
                        .init(date: calendar.date(byAdding: .day, value: -1, to: today)!, value: 72, category: "Teeth"),
                        .init(date: calendar.date(byAdding: .day, value: -2, to: today)!, value: 90, category: "Teeth"),
                        .init(date: calendar.date(byAdding: .day, value: -3, to: today)!, value: 45, category: "Food"),
                    ]
                    SWScatterChart(dataPoints: data, colorMapping: ["Teeth": .blue, "Food": .orange], title: "Scan Trends")
                }
            }
            .padding()
        }
    }

    // MARK: - Donut Chart

    static var donutChart: some View {
        DonutPreviewWrapper()
    }

    static var donutChartFull: some View {
        DonutFullWrapper()
    }

    // MARK: - Radar Chart

    static var radarChart: some View {
        SWRadarChart(data: [
            .init(label: "Tolerance", value: 75),
            .init(label: "Ambition", value: 50),
            .init(label: "Acuity", value: 50),
            .init(label: "Creativity", value: 85),
            .init(label: "Stability", value: 85),
        ])
        .padding(60)
        .frame(height: 220)
    }

    static var radarChartFull: some View {
        SWRadarChart(data: [
            .init(label: "Tolerance", value: 75),
            .init(label: "Ambition", value: 50),
            .init(label: "Acuity", value: 50),
            .init(label: "Creativity", value: 85),
            .init(label: "Stability", value: 85),
        ])
        .padding(100)
    }

    // MARK: - Ring Chart

    static var ringChart: some View {
        SWRingChart(data: [
            .init(label: "Move", value: 75, color: .red),
            .init(label: "Exercise", value: 50, color: .green),
            .init(label: "Stand", value: 90, color: .cyan),
        ], size: 120, ringWidth: 12)
        .frame(height: 160)
        .frame(maxWidth: .infinity)
    }

    static var ringChartFull: some View {
        VStack(spacing: 40) {
            SWRingChart(data: [
                .init(label: "Move", value: 75, color: .red),
                .init(label: "Exercise", value: 50, color: .green),
                .init(label: "Stand", value: 90, color: .cyan),
            ]) {
                VStack {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text("Activity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    // MARK: - Activity Heatmap

    static var activityHeatmap: some View {
        let timestamps: [Date] = {
            var dates: [Date] = []
            let calendar = Calendar.current
            let today = Date()
            for i in 0..<30 {
                if Int.random(in: 0...100) < 70 {
                    if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                        dates.append(date)
                    }
                }
            }
            return dates
        }()
        return SWActivityHeatmap.HeatmapGrid(timestamps: timestamps, days: 30, baseColor: .green)
            .padding()
    }

    static var activityHeatmapFull: some View {
        let timestamps: [Date] = {
            var dates: [Date] = []
            let calendar = Calendar.current
            let today = Date()
            for i in 0..<60 {
                if Int.random(in: 0...100) < 70 {
                    if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                        let count = Int.random(in: 1...3)
                        for _ in 0..<count { dates.append(date) }
                    }
                }
            }
            return dates
        }()
        return NavigationStack {
            Form {
                Section {
                    SWActivityHeatmap.StreakCard(streaks: timestamps, colors: [.blue, .purple])
                }
                .listRowInsets(EdgeInsets())
                Section {
                    SWActivityHeatmap.HeatmapGrid(timestamps: timestamps, days: 60, baseColor: .green)
                } header: {
                    Text("Past 60 days")
                } footer: {
                    SWActivityHeatmap.HeatmapLegend(baseColor: .green)
                }
            }
            .navigationTitle("Activity")
        }
    }
}

// MARK: - Stateful Wrapper Views

/// Donut chart preview needs its own state for selectedCategory.
private struct DonutPreviewWrapper: View {
    @State private var selected: String? = nil
    var body: some View {
        let work = SWDonutChart.Category(name: "Work")
        let personal = SWDonutChart.Category(name: "Personal")
        SWDonutChart(
            subjects: [
                .init(name: "Meeting", category: work),
                .init(name: "Shopping", category: personal),
                .init(name: "Exercise", category: nil),
            ],
            selectedCategory: $selected
        )
        .frame(height: 200)
        .padding(.horizontal)
    }
}

private struct DonutFullWrapper: View {
    @State private var selected: String? = nil
    var body: some View {
        let work = SWDonutChart.Category(name: "Work")
        let personal = SWDonutChart.Category(name: "Personal")
        let health = SWDonutChart.Category(name: "Health")
        SWDonutChart(
            subjects: [
                .init(name: "Meeting", category: work),
                .init(name: "Report", category: work),
                .init(name: "Email", category: work),
                .init(name: "Shopping", category: personal),
                .init(name: "Reading", category: personal),
                .init(name: "Exercise", category: health),
                .init(name: "Meditation", category: health),
                .init(name: "Running", category: health),
                .init(name: "Uncategorized Task", category: nil),
            ],
            selectedCategory: $selected
        )
        .padding()
    }
}

private struct StepperPreviewWrapper: View {
    @State private var value = 1
    var body: some View {
        SWStepper(quantity: $value)
            .padding()
            .frame(maxWidth: .infinity)
    }
}

private struct StepperFullDemo: View {
    @State private var value = 1
    var body: some View {
        VStack(spacing: 30) {
            SWStepper(quantity: $value)
            Divider()
            HStack {
                Text("Quantity")
                Spacer()
                SWStepper(quantity: $value)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct TabButtonFullDemo: View {
    @State private var selected = 0
    var body: some View {
        List {
            HStack {
                SWTabButton(title: "All", isSelected: selected == 0) {
                    withAnimation(.easeInOut(duration: 0.2)) { selected = 0 }
                }
                SWTabButton(title: "Favorites", isSelected: selected == 1) {
                    withAnimation(.easeInOut(duration: 0.2)) { selected = 1 }
                }
                SWTabButton(title: "Recent", isSelected: selected == 2) {
                    withAnimation(.easeInOut(duration: 0.2)) { selected = 2 }
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section {
                ForEach(["Item A", "Item B", "Item C"], id: \.self) { item in
                    Label(item, systemImage: "doc.text")
                }
            }
        }
    }
}

private struct AddSheetFullDemo: View {
    @State private var showSheet = false
    var body: some View {
        VStack {
            Spacer()
            Button("Show Add Sheet") { showSheet = true }
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showSheet) {
            SWAddSheet(isPresented: $showSheet) { _ in }
        }
    }
}

/// Wraps SWOnboardingView with dismiss logic for fullScreenCover.
private struct OnboardingDemoWrapper: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        SWOnboardingView(onComplete: { dismiss() })
    }
}

/// Wraps SWOrderView with a close button for fullScreenCover.
private struct OrderDemoWrapper: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack(alignment: .topTrailing) {
            SWOrderView()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .padding()
            }
        }
    }
}
