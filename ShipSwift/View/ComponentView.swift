//
//  ComponentView.swift
//  ShipSwift
//
//  Components tab — showcases Display, Feedback, and Input components
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI

struct ComponentView: View {
    @State private var selectedInputTab = 0
    @State private var stepperValue = 1

    @State private var showAddSheet = false
    @State private var showOnboarding = false
    @State private var showOrder = false
    @State private var showRootTab = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Display Components
                Section {
                    // Floating labels — animated capsule labels hovering over an image
                    NavigationLink {
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

                    // Scrolling FAQ — auto-scrolling horizontal question pill carousel
                    NavigationLink {
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

                    // Rotating quote — auto-cycling famous quotes display
                    NavigationLink {
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
                    NavigationLink {
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
                    Button {
                        showOnboarding = true
                    } label: {
                        ListItem(
                            title: "Onboarding",
                            icon: "hand.wave.fill",
                            description: "Multi-page welcome flow with swipe navigation and skip support. Presented as fullScreenCover."
                        )
                    }

                    // Order — animated drink customization demo
                    Button {
                        showOrder = true
                    } label: {
                        ListItem(
                            title: "Order",
                            icon: "cup.and.saucer.fill",
                            description: "Animated drink customization demo with flavor/size selectors and cup animations. Presented as fullScreenCover."
                        )
                    }

                    // Tab — TabView template
                    Button {
                        showRootTab = true
                    } label: {
                        ListItem(
                            title: "Tab",
                            icon: "rectangle.split.3x1.fill",
                            description: "TabView template with selected/unselected icons and haptic feedback. Presented as sheet."
                        )
                    }
                } header: {
                    Text("Display (7)")
                        .font(.title3.bold())
                        .textCase(nil)
                }

                // MARK: - Feedback Components
                Section {
                    // Global toast alert — supports info/success/warning/error presets and custom styles
                    NavigationLink {
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
                    NavigationLink {
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
                    NavigationLink {
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
                    Text("Feedback (3)")
                        .font(.title3.bold())
                        .textCase(nil)
                }

                // MARK: - Input Components
                Section {
                    // Capsule tab button — for custom segmented controls and filter bars
                    NavigationLink {
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
                    NavigationLink {
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
                    NavigationLink {
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
                } header: {
                    Text("Input (3)")
                        .font(.title3.bold())
                        .textCase(nil)
                }
            }
            .navigationTitle("Components")
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
            .fullScreenCover(isPresented: $showOnboarding) {
                SWOnboardingView(onComplete: { showOnboarding = false })
            }
            .fullScreenCover(isPresented: $showOrder) {
                ZStack(alignment: .topTrailing) {
                    SWOrderView()
                    Button {
                        showOrder = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
            }
            .sheet(isPresented: $showRootTab) {
                SWRootTabView()
            }
        }
    }
}

#Preview {
    ComponentView()
}
