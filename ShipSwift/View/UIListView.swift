//
//  UIListView.swift
//  ShipSwift
//
//  UI tab — showcases the self-contained UI components in three
//  sections: Display, Feedback, and Input.
//
//  Created by Wei Zhong on 2/8/26.
//

import SwiftUI

struct UIListView: View {
    // Input section state
    @State private var selectedInputTab = 0
    @State private var stepperValue = 1
    @State private var searchBarText = ""

    // Display section state
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                displaySection
                feedbackSection
                inputSection
            }
            .navigationTitle("tab.ui")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }

    // MARK: - Display Section

    private var displaySection: some View {
        Section {
            // Floating labels — animated capsule labels hovering over an image
            ComponentNavigationLink {
                SWFloatingLabels(
                    image: Image(.facePicture),
                    labels: [
                        .init(text: "Teeth mapping",    position: CGPoint(x: 0.3, y: 0.5)),
                        .init(text: "Plaque detection", position: CGPoint(x: 0.9, y: 0.6)),
                        .init(text: "Shape & balance",  position: CGPoint(x: 0.5, y: 0.8))
                    ]
                )
            } label: {
                ListItem(
                    title: "Floating Labels",
                    icon: "tag.fill",
                    description: "Animated floating capsule labels over an image. Labels fade in/out at specified positions, ideal for feature callouts."
                )
            }

            // Scrolling FAQ — iOS only (UIScrollView + CADisplayLink)
            #if os(iOS)
            ComponentNavigationLink {
                SWScrollingFAQ(
                    rows: [
                        ["How does AI work?", "What can I ask?", "How accurate?", "Help with coding?",
                         "Remember chat?", "Languages supported?", "Get started?", "Explain topics?"],
                        ["Write an email", "Summarize article", "Translate text", "Creative ideas",
                         "Debug code", "Explain concept", "Meal plan", "Brainstorm"],
                        ["Best approach?", "How to improve?", "Give examples", "Compare options",
                         "Suggest alternatives", "Pros and cons?", "Help understand", "Walk through"]
                    ],
                    title: "Let's talk about new topics"
                ) { _ in }
            } label: {
                ListItem(
                    title: "Scrolling FAQ",
                    icon: "bubble.left.and.text.bubble.right",
                    description: "Auto-scrolling horizontal FAQ carousel with alternating row directions. Tapping a pill triggers a callback."
                )
            }
            #endif

            // Rotating quote — auto-cycling famous quotes display
            ComponentNavigationLink {
                ScrollView {
                    VStack(spacing: 32) {
                        // Multiple quotes rotation
                        SWRotatingQuote(
                            quotes: [
                                "Those times when you get up early, and you work hard, those times when you stay up late, and you work hard.",
                                "Those times when you don't feel like working, you're too tired, you don't want to push yourself, but you do it anyway.",
                                "That is actually the dream. It's not the destination, it's the journey."
                            ],
                            author: "Kobe Bryant"
                        )
                        .frame(height: 140)

                        Divider()

                        // Single quote (no rotation)
                        SWRotatingQuote(
                            quotes: [
                                "Stay hungry, stay foolish."
                            ],
                            author: "Steve Jobs",
                            quoteFont: .title3,
                            authorFont: .title2
                        )
                        .frame(height: 100)

                        Divider()

                        // Custom style (serif, faster rotation)
                        SWRotatingQuote(
                            quotes: [
                                "The only way to do great work is to love what you do.",
                                "Innovation distinguishes between a leader and a follower.",
                                "Your time is limited, don't waste it living someone else's life."
                            ],
                            author: "Steve Jobs",
                            interval: 3.0,
                            quoteFont: .body,
                            authorFont: .callout,
                            fontDesign: .serif,
                            foregroundStyle: .primary
                        )
                        .frame(height: 120)
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Rotating Quote",
                    icon: "text.quote",
                    description: "Auto-rotating quote display that cycles through texts with animated transitions and author attribution."
                )
            }

            // Basic display elements — BulletPointText + GradientDivider + Label
            ComponentNavigationLink {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Section 1: SWBulletPointText demo
                        Text("Bullet Point Text")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 10) {
                            SWBulletPointText(bulletColor: .blue) {
                                Text("Wealth")
                            }
                            SWBulletPointText(bulletColor: .green) {
                                HStack {
                                    Text("Health")
                                    Image(systemName: "heart.fill")
                                }
                            }
                            SWBulletPointText(bulletColor: .orange) {
                                Text("Happiness")
                            }
                            SWBulletPointText(bulletColor: .purple) {
                                Text("Wisdom")
                            }
                        }
                        .padding(.horizontal)

                        Divider()

                        // Section 2: SWGradientDivider demo
                        Text("Gradient Divider")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 20) {
                            SWGradientDivider()
                            SWGradientDivider(color: .purple, opacity: 0.5)
                            SWGradientDivider(color: .mint, height: 2)
                        }
                        .padding(.horizontal)

                        Divider()

                        // Section 3: SWLabelWithIcon demo
                        Text("Label with Icon")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            SWLabelWithIcon()
                            SWLabelWithIcon(
                                icon: "gearshape",
                                bg: .orange,
                                name: "Settings"
                            )
                            SWLabelWithIcon(
                                icon: "bell.badge",
                                bg: .red,
                                name: "Notifications"
                            )
                            SWLabelWithIcon(
                                icon: "lock.shield",
                                bg: .green,
                                name: "Privacy"
                            )
                            SWLabelWithIcon(
                                icon: "creditcard",
                                bg: .purple,
                                name: "Subscription"
                            )

                            Divider()

                            SWLabelWithImage(
                                image: .fullpackLogo,
                                name: "FullPack"
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            } label: {
                ListItem(
                    title: "Basic Display Elements",
                    icon: "rectangle.3.group",
                    description: "BulletPointText, GradientDivider, and LabelWithIcon — simple building blocks for lists, settings, and content sections."
                )
            }
            // Onboarding — multi-page welcome flow with swipe navigation and skip
            ComponentNavigationLink {
                SWOnboardingView(onComplete: {})
            } label: {
                ListItem(
                    title: "Onboarding",
                    icon: "hand.wave.fill",
                    description: "Multi-page welcome flow with swipe navigation and skip support."
                )
            }

            // Order — animated drink customization demo
            ComponentNavigationLink {
                SWOrderView()
            } label: {
                ListItem(
                    title: "Order",
                    icon: "cup.and.saucer.fill",
                    description: "Animated drink customization demo with flavor/size selectors and cup animations."
                )
            }

            // Tab — TabView template
            ComponentNavigationLink {
                SWRootTabView()
            } label: {
                ListItem(
                    title: "Tab",
                    icon: "rectangle.split.3x1.fill",
                    description: "TabView template with selected/unselected icons and haptic feedback."
                )
            }

            // Markdown Text — renders common LLM Markdown output
            ComponentNavigationLink {
                ScrollView {
                    SWMarkdownText("""
                    # Heading 1
                    ## Heading 2
                    ### Heading 3

                    This is a paragraph with **bold** and *italic* text.

                    Here is `inline code` in a sentence.

                    ```swift
                    func greet() {
                        print("Hello, world!")
                    }
                    ```

                    - First item
                    - Second item with **bold**
                    - Third item

                    1. Ordered item one
                    2. Ordered item two

                    ---

                    Another paragraph after the divider.
                    """)
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Markdown Text",
                    icon: "text.badge.checkmark",
                    description: "Custom Markdown renderer supporting headings, bold/italic, code blocks, lists, and dividers — ideal for LLM output."
                )
            }

            // Status Badge — capsule status indicator with five semantic styles
            ComponentNavigationLink {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("All styles")
                                .font(.headline)
                            HStack(spacing: 8) {
                                SWStatusBadge(text: "Info", style: .info)
                                SWStatusBadge(text: "Success", style: .success)
                                SWStatusBadge(text: "Warning", style: .warning)
                                SWStatusBadge(text: "Error", style: .error)
                                SWStatusBadge(text: "Neutral", style: .neutral)
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Order list example")
                                .font(.headline)
                            HStack {
                                Text("Order #1024")
                                Spacer()
                                SWStatusBadge(text: "Pending", style: .warning)
                            }
                            HStack {
                                Text("Order #1025")
                                Spacer()
                                SWStatusBadge(text: "Making", style: .info)
                            }
                            HStack {
                                Text("Order #1026")
                                Spacer()
                                SWStatusBadge(text: "Ready", style: .success)
                            }
                            HStack {
                                Text("Order #1027")
                                Spacer()
                                SWStatusBadge(text: "Cancelled", style: .error)
                            }
                            HStack {
                                Text("Order #1028")
                                Spacer()
                                SWStatusBadge(text: "Completed", style: .neutral)
                            }
                        }
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Status Badge",
                    icon: "circle.dotted",
                    description: "Capsule status badge with five semantic styles (info, success, warning, error, neutral). LocalizedStringKey and String overloads."
                )
            }

            // Image Thumbnail — square image tile with same-named ColorSet fallback
            ComponentNavigationLink {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            SWImageThumbnail(imageName: "PreviewMissingAsset", size: 200, cornerRadius: 24)
                            Text("200 × 200, radius 24")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 8) {
                            SWImageThumbnail(imageName: "PreviewMissingAsset")
                            Text("Default 120 × 120, radius 18")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 8) {
                            SWImageThumbnail(imageName: "PreviewMissingAsset", size: 60, cornerRadius: 12)
                            Text("60 × 60, radius 12 (cart row)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("Tip: register a same-named ColorSet alongside the image set to get a brand-appropriate tint before the image decodes — or as a permanent fallback for empty states.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Image Thumbnail",
                    icon: "photo.fill",
                    description: "Square image tile with same-named ColorSet fallback. Renders the tint while the image decodes or when the asset is missing."
                )
            }

            // KPI Card — dashboard metric card with icon, animated value, and trailing slot
            ComponentNavigationLink {
                ScrollView {
                    VStack(spacing: 20) {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            SWKPICard(
                                title: "Today's Revenue",
                                value: "$1,234",
                                icon: "dollarsign.circle.fill",
                                tint: .brown
                            ) {
                                SWKPIDeltaTag(delta: 12.5)
                            }
                            SWKPICard(
                                title: "Cups Sold",
                                value: "128",
                                icon: "cup.and.saucer.fill",
                                tint: .orange
                            ) {
                                Text("Unit: cups")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            SWKPICard(
                                title: "Monthly Revenue",
                                value: "$24,560",
                                icon: "calendar",
                                tint: .green
                            ) {
                                SWKPIDeltaTag(delta: -3.2)
                            }
                            SWKPICard(
                                title: "New Members",
                                value: "42",
                                icon: "person.2.fill",
                                tint: .pink
                            ) {
                                SWKPIDeltaTag(delta: nil)
                            }
                        }

                        Divider()

                        SWKPICard(
                            title: "Total Members",
                            value: "1,024",
                            icon: "person.3.fill",
                            tint: .blue
                        )
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "KPI Card",
                    icon: "rectangle.stack.badge.plus",
                    description: "Dashboard KPI card with icon, animated numeric value, and customizable trailing slot. Pairs with SWKPIDeltaTag for period-over-period."
                )
            }

            // Wallet — pouch holding a stack of payment cards with a reveal toggle
            ComponentNavigationLink {
                SWWallet()
            } label: {
                ListItem(
                    title: "Wallet",
                    icon: "wallet.bifold.fill",
                    description: "Olive-green wallet pouch holding a stack of payment cards. Tap the eye to spring the cards out into a ladder and reveal the total balance."
                )
            }
        } header: {
            Text("Display")
                .font(.title3.bold())
                .textCase(nil)
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        Section {
            // Global toast alert — supports info/success/warning/error presets and custom styles
            ComponentNavigationLink {
                VStack(spacing: 12) {
                    Spacer()

                    Text("Tap to trigger alerts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 10) {
                        Button {
                            SWAlertManager.shared.show(.info, message: "This is an info message")
                        } label: {
                            Label("Info", systemImage: "info.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.primary)

                        Button {
                            SWAlertManager.shared.show(.success, message: "Saved successfully")
                        } label: {
                            Label("Success", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.green)

                        Button {
                            SWAlertManager.shared.show(.warning, message: "Slow connection")
                        } label: {
                            Label("Warning", systemImage: "exclamationmark.triangle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.orange)

                        Button {
                            SWAlertManager.shared.show(.error, message: "Operation failed, please retry")
                        } label: {
                            Label("Error", systemImage: "xmark.circle.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.red)

                        Button {
                            SWAlertManager.shared.show(
                                icon: "star.fill",
                                message: "Custom alert style",
                                textColor: .yellow,
                                backgroundStyle: AnyShapeStyle(.black),
                                borderColor: .yellow
                            )
                        } label: {
                            Label("Custom", systemImage: "star.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.yellow)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Spacer()
                }
                .padding(.horizontal, 24)
            } label: {
                ListItem(
                    title: "SWAlert",
                    icon: "bell.badge",
                    description: "Toast-style alert overlay with four preset styles (info, success, warning, error) and custom styling. Auto-dismisses after configurable duration."
                )
            }

            // Fullscreen loading overlay — blur material background + optional icon pulse animation
            ComponentNavigationLink {
                ZStack {
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 20) {
                        Text("Page Content")
                            .font(.largeTitle)
                            .foregroundStyle(.white)

                        Button("Show Default Loading") {
                            SWLoadingManager.shared.show(page: .home, message: "Loading data...")
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                SWLoadingManager.shared.hide(page: .home)
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Show Loading with Icon") {
                            SWLoadingManager.shared.show(
                                page: .home,
                                message: "Syncing data...",
                                systemImage: "arrow.triangle.2.circlepath"
                            )
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                SWLoadingManager.shared.hide(page: .home)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .swPageLoading(.home)
            } label: {
                ListItem(
                    title: "SWLoading",
                    icon: "hourglass",
                    description: "Fullscreen loading overlay with blur material background, customizable message, optional SF Symbol icon with pulse animation."
                )
            }

            // Thinking indicator — three-dot bouncing animation for chat typing state
            ComponentNavigationLink {
                VStack(spacing: 40) {
                    // Default style
                    VStack(spacing: 8) {
                        Text("Default")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        SWThinkingIndicator()
                    }

                    // Inside a chat bubble
                    VStack(spacing: 8) {
                        Text("Chat Bubble")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .bottom, spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundStyle(.purple)
                            HStack(spacing: 4) {
                                Text("Thinking")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                SWThinkingIndicator()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    // Custom color and size
                    VStack(spacing: 8) {
                        Text("Custom (blue, large)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        SWThinkingIndicator(dotSize: 10, dotColor: .blue, spacing: 6)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } label: {
                ListItem(
                    title: "SWThinkingIndicator",
                    icon: "ellipsis.bubble",
                    description: "Animated three-dot bouncing indicator for chat typing states. Configurable dot size, color, and spacing."
                )
            }
        } header: {
            Text("Feedback")
                .font(.title3.bold())
                .textCase(nil)
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        Section {
            // Capsule tab button — for custom segmented controls and filter bars
            ComponentNavigationLink {
                List {
                    HStack {
                        SWTabButton(title: "All", isSelected: selectedInputTab == 0) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedInputTab = 0 }
                        }
                        SWTabButton(title: "Favorites", isSelected: selectedInputTab == 1) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedInputTab = 1 }
                        }
                        SWTabButton(title: "Recent", isSelected: selectedInputTab == 2) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedInputTab = 2 }
                        }
                        SWTabButton(title: "Trending", isSelected: selectedInputTab == 3) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedInputTab = 3 }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Section {
                        if selectedInputTab == 0 {
                            ForEach(["Meeting notes", "Grocery list", "Workout plan", "Travel ideas", "Book wishlist"], id: \.self) { item in
                                Label(item, systemImage: "doc.text")
                            }
                        } else if selectedInputTab == 1 {
                            ForEach(["Workout plan", "Travel ideas"], id: \.self) { item in
                                Label(item, systemImage: "star.fill")
                                    .foregroundStyle(.orange)
                            }
                        } else if selectedInputTab == 2 {
                            ForEach(["Grocery list", "Meeting notes"], id: \.self) { item in
                                Label(item, systemImage: "clock")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(["AI prompts", "Fitness trends", "Recipe hacks"], id: \.self) { item in
                                Label(item, systemImage: "flame.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            } label: {
                ListItem(
                    title: "SWTabButton",
                    icon: "rectangle.compress.vertical",
                    description: "Capsule-shaped tab button for custom segmented controls and filter bars. Toggles between selected and unselected states."
                )
            }

            // Numeric stepper — compact control with animated transitions and haptic feedback
            ComponentNavigationLink {
                VStack(spacing: 30) {
                    SWStepper(quantity: $stepperValue)

                    Divider()

                    HStack {
                        Text("Quantity")
                        Spacer()
                        SWStepper(quantity: $stepperValue)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } label: {
                ListItem(
                    title: "SWStepper",
                    icon: "minus.forwardslash.plus",
                    description: "Compact numeric stepper with animated transitions and haptic feedback. Chevron-style increment/decrement buttons."
                )
            }

            // Add sheet — bottom sheet with text input
            ComponentNavigationLink {
                VStack {
                    Spacer()

                    Button("Show Add Sheet") {
                        showAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sheet(isPresented: $showAddSheet) {
                    SWAddSheet(isPresented: $showAddSheet) { _ in }
                }
            } label: {
                ListItem(
                    title: "SWAddSheet",
                    icon: "plus.rectangle.on.rectangle",
                    description: "Bottom sheet with text input, cancel and confirm buttons. Presented as medium detent for collecting user input."
                )
            }

            // Search bar — capsule-shaped with magnifying glass, clear button, ultra-thin material
            ComponentNavigationLink {
                VStack(spacing: 24) {
                    SWSearchBar(text: $searchBarText)
                        .padding(.horizontal)

                    SWSearchBar(text: $searchBarText, placeholder: "Search contacts")
                        .padding(.horizontal)

                    Text(searchBarText.isEmpty ? "Start typing to see the bound value..." : "Query: \(searchBarText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.top)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } label: {
                ListItem(
                    title: "SWSearchBar",
                    icon: "magnifyingglass",
                    description: "Capsule-shaped search bar with magnifying glass, clear button and ultra-thin material background. Binds to a text string."
                )
            }
        } header: {
            Text("Input")
                .font(.title3.bold())
                .textCase(nil)
        }
    }
}

// MARK: - Preview

#Preview {
    UIListView()
}
