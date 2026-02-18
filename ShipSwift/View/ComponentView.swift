//
//  ComponentView.swift
//  ShipSwift
//
//  Components tab — showcases all component categories:
//  Module, Animation, Chart, Display, Feedback, and Input.
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI
import Charts

struct ComponentView: View {
    @Binding var scrollTarget: String?

    // Input section state
    @State private var selectedInputTab = 0
    @State private var stepperValue = 1

    // Display section state
    @State private var showAddSheet = false
    @State private var showOnboarding = false
    @State private var showOrder = false
    @State private var showRootTab = false

    // Module section state
    @State private var showAuthDemo = false
    @State private var showCameraDemo = false
    @State private var showFaceCameraDemo = false
    @State private var showPaywall = false
    @State private var showChatDemo = false

    // Chart section state
    @State private var donutSelectedCategory: String? = nil

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    moduleSection
                    animationSection
                    chartSection
                    displaySection
                    feedbackSection
                    inputSection
                }
                .onChange(of: scrollTarget) { _, target in
                    guard let target else { return }
                    withAnimation {
                        proxy.scrollTo(target, anchor: .top)
                    }
                    // Reset after scrolling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        scrollTarget = nil
                    }
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
            // Display section covers
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
            // Module section covers
            .fullScreenCover(isPresented: $showAuthDemo) {
                NavigationStack {
                    ComponentViewAuthDemo()
                }
            }
            .fullScreenCover(isPresented: $showCameraDemo) {
                ComponentViewCameraDemo()
                    .swAlert()
            }
            .fullScreenCover(isPresented: $showFaceCameraDemo) {
                ComponentViewFaceCameraDemo()
            }
            .sheet(isPresented: $showPaywall) {
                ComponentViewPaywallDemo()
            }
            .fullScreenCover(isPresented: $showChatDemo) {
                NavigationStack {
                    ComponentViewChatDemo()
                }
            }
        }
    }

    // MARK: - Module Section

    private var moduleSection: some View {
        Section {
            // Auth demo — presented as fullScreenCover, no backend
            Button {
                showAuthDemo = true
            } label: {
                ListItem(
                    title: "Auth",
                    icon: "person.badge.key.fill",
                    description: "Complete auth flow: email sign-in/up, phone sign-in with country code picker, verification code, forgot/reset password, Apple & Google social sign-in."
                )
            }

            // Camera demo — showcase SWCamera UI components (no real camera)
            Button {
                showCameraDemo = true
            } label: {
                ListItem(
                    title: "Camera",
                    icon: "camera.fill",
                    description: "Full camera capture view with viewfinder overlay, pinch-to-zoom, zoom slider, photo library picker, and permission handling."
                )
            }

            // Face Camera demo — real camera with Vision face tracking
            Button {
                showFaceCameraDemo = true
            } label: {
                ListItem(
                    title: "Face Camera",
                    icon: "face.smiling.inverse",
                    description: "Camera with real-time Vision face landmark detection, front/back switching, landmark overlay toggle, and configurable color schemes."
                )
            }

            // Paywall demo — presented as sheet
            Button {
                showPaywall = true
            } label: {
                ListItem(
                    title: "Paywall",
                    icon: "creditcard.fill",
                    description: "Subscription paywall with monthly/yearly options, feature list, restore purchases, redeem code, and policy links."
                )
            }

            // Chat demo — presented as fullScreenCover
            Button {
                showChatDemo = true
            } label: {
                ListItem(
                    title: "Chat",
                    icon: "bubble.left.and.bubble.right.fill",
                    description: "Chat interface with message bubbles, text input, voice recording waveform, and simple echo response simulation."
                )
            }

            // Settings module
            NavigationLink {
                SWSettingView()
            } label: {
                ListItem(
                    title: "Setting",
                    icon: "gearshape.fill",
                    description: "Generic settings page with language switch, share, legal links, and account actions. Pushed via NavigationLink."
                )
            }
        } header: {
            Text("Module (6)")
                .font(.title3.bold())
                .textCase(nil)
                .id("module")
        }
    }

    // MARK: - Animation Section

    private var animationSection: some View {
        Section {
            NavigationLink {
                SWBeforeAfterSlider(
                    before: Image(.smileBefore),
                    after: Image(.smileAfter)
                )
                .padding()
            } label: {
                ListItem(
                    title: "Before / After Slider",
                    icon: "slider.horizontal.below.rectangle",
                    description: "Draggable image comparison slider with auto-oscillating animation. Supports custom labels, speed, and aspect ratio."
                )
            }

            NavigationLink {
                VStack(spacing: 26) {
                    SWTypewriterText(
                        texts: ["Level up your smile game", "AI-powered smile analysis", "Join the glow up era"],
                        animationStyle: .spring
                    )
                    .font(.title3.weight(.semibold))

                    SWTypewriterText(
                        texts: ["Level up your smile game", "AI-powered smile analysis", "Join the glow up era"],
                        animationStyle: .blur
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
            } label: {
                ListItem(
                    title: "Typewriter Text",
                    icon: "character.cursor.ibeam",
                    description: "Typing and deleting text animation that cycles through strings. Six animation styles: spring, blur, fade, scale, wave, none."
                )
            }

            NavigationLink {
                VStack(spacing: 40) {
                    SWShakingIcon(image: Image(systemName: "apple.logo"), height: 20)
                    SWShakingIcon(image: Image(.smileAfter), height: 100, cornerRadius: 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } label: {
                ListItem(
                    title: "Shaking Icon",
                    icon: "iphone.radiowaves.left.and.right",
                    description: "Periodically zooms in and shakes side-to-side, mimicking the iOS home-screen jiggle effect. Supports SF Symbols and asset images."
                )
            }

            NavigationLink {
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
            } label: {
                ListItem(
                    title: "Shimmer",
                    icon: "light.max",
                    description: "Translucent light band sweep across any view. Commonly used on buttons, skeleton loaders, or cards to draw attention."
                )
            }

            NavigationLink {
                VStack(spacing: 26) {
                    SWGlowSweep {
                        Text("Start Scan Today")
                            .font(.largeTitle.bold())
                    }

                    SWGlowSweep(baseColor: .accentColor, glowColor: .white, duration: 1.5) {
                        Text("Analyzing...")
                            .font(.title2.bold())
                    }

                    SWGlowSweep(baseColor: .green.opacity(0.7), glowColor: .black) {
                        Text("Processing")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } label: {
                ListItem(
                    title: "Glow Sweep",
                    icon: "wand.and.rays",
                    description: "Sweeps a glowing highlight band using the original content shape as mask. Ideal for text, icons, and SF Symbols."
                )
            }

            NavigationLink {
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
            } label: {
                ListItem(
                    title: "Light Sweep",
                    icon: "light.beacon.max",
                    description: "Gradient light band that sweeps across content in a rounded rectangle. Great for image cards and thumbnails."
                )
            }

            NavigationLink {
                VStack(spacing: 20) {
                    SWScanningOverlay {
                        Image(.facePicture)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    SWScanningOverlay(gridOpacity: 0.1, bandOpacity: 0.1, speed: 3.0) {
                        Image(.facePicture)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } label: {
                ListItem(
                    title: "Scanning Overlay",
                    icon: "barcode.viewfinder",
                    description: "Grid lines, sweeping scan band, and noise layer overlay. Conveys an analyzing / processing visual effect."
                )
            }

            NavigationLink {
                SWAnimatedMeshGradient()
                    .ignoresSafeArea()
            } label: {
                ListItem(
                    title: "Animated Mesh Gradient",
                    icon: "circle.hexagongrid.fill",
                    description: "3x3 mesh gradient background that transitions between two color palettes. Designed as a full-screen or section background."
                )
            }

            NavigationLink {
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

                    SWOrbitingLogos(
                        images: ["airpods", "business-shoes", "sunglasses", "tshirt", "wide-brimmed-hat", "golf-gloves", "suit", "golf-gloves"]
                    ) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 50, height: 50)
                    }
                    .frame(width: 150)
                }
            } label: {
                ListItem(
                    title: "Orbiting Logos",
                    icon: "atom",
                    description: "SpriteKit-powered concentric rings of colored dots with icons on the outermost ring. Custom center view via SwiftUI."
                )
            }
        } header: {
            Text("Animation (9)")
                .font(.title3.bold())
                .textCase(nil)
                .id("animation")
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        Section {
            NavigationLink {
                ScrollView {
                    VStack(spacing: 32) {
                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let salesData: [SWLineChart<String>.DataPoint] = (0..<14).flatMap { (dayOffset: Int) -> [SWLineChart<String>.DataPoint] in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return [
                                    .init(date: date, value: Double.random(in: 40...90), category: "Revenue"),
                                    .init(date: date, value: Double.random(in: 20...60), category: "Cost"),
                                ]
                            }

                            SWLineChart(
                                dataPoints: salesData,
                                colorMapping: ["Revenue": .blue, "Cost": .red],
                                title: "Revenue vs Cost"
                            )
                        }

                        Divider()

                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let tempData: [SWLineChart<String>.DataPoint] = (0..<10).map { dayOffset in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return .init(date: date, value: Double.random(in: 35.5...38.5), category: "Temperature")
                            }

                            SWLineChart(
                                dataPoints: tempData,
                                colorMapping: ["Temperature": .orange],
                                referenceLines: [
                                    .init(value: 37.0, label: "Normal", color: .green),
                                    .init(value: 38.0, label: "Fever", color: .red),
                                ],
                                interpolationMethod: .catmullRom,
                                showPointMarkers: true,
                                yDomain: 35...40,
                                visibleDays: 10,
                                chartHeight: 220,
                                title: "Body Temperature"
                            )
                        }
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Line Chart",
                    icon: "chart.xyaxis.line",
                    description: "Multi-series line chart with horizontal scrolling, reference lines, point markers, and configurable interpolation methods."
                )
            }

            NavigationLink {
                ScrollView {
                    VStack(spacing: 32) {
                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let salesData: [SWBarChart<String>.DataPoint] = (0..<10).flatMap { (dayOffset: Int) -> [SWBarChart<String>.DataPoint] in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return [
                                    .init(date: date, value: Double.random(in: 50...150), category: "Online"),
                                    .init(date: date, value: Double.random(in: 30...100), category: "Offline"),
                                ]
                            }

                            SWBarChart(
                                dataPoints: salesData,
                                colorMapping: ["Online": .blue, "Offline": .orange],
                                title: "Sales by Channel (Grouped)"
                            )
                        }

                        Divider()

                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let stackedData: [SWBarChart<String>.DataPoint] = (0..<7).flatMap { (dayOffset: Int) -> [SWBarChart<String>.DataPoint] in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return [
                                    .init(date: date, value: Double.random(in: 30...80), category: "Food"),
                                    .init(date: date, value: Double.random(in: 20...50), category: "Transport"),
                                    .init(date: date, value: Double.random(in: 10...40), category: "Entertainment"),
                                ]
                            }

                            SWBarChart(
                                dataPoints: stackedData,
                                colorMapping: ["Food": .green, "Transport": .blue, "Entertainment": .purple],
                                stackMode: .stacked,
                                yDomain: 0...200,
                                visibleDays: 7,
                                chartHeight: 250,
                                title: "Daily Expenses (Stacked)"
                            )
                        }
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Bar Chart",
                    icon: "chart.bar.fill",
                    description: "Grouped or stacked bar chart with horizontal scrolling, optional value labels, and configurable bar corner radius."
                )
            }

            NavigationLink {
                ScrollView {
                    VStack(spacing: 32) {
                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let trafficData: [SWAreaChart<String>.DataPoint] = (0..<14).flatMap { (dayOffset: Int) -> [SWAreaChart<String>.DataPoint] in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return [
                                    .init(date: date, value: Double.random(in: 100...300), category: "Organic"),
                                    .init(date: date, value: Double.random(in: 50...200), category: "Paid"),
                                ]
                            }

                            SWAreaChart(
                                dataPoints: trafficData,
                                colorMapping: ["Organic": .green, "Paid": .blue],
                                gradientOpacity: 0.25,
                                title: "Website Traffic"
                            )
                        }

                        Divider()

                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let revenueData: [SWAreaChart<String>.DataPoint] = (0..<10).flatMap { (dayOffset: Int) -> [SWAreaChart<String>.DataPoint] in
                                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                                return [
                                    .init(date: date, value: Double.random(in: 40...120), category: "Product A"),
                                    .init(date: date, value: Double.random(in: 30...80), category: "Product B"),
                                    .init(date: date, value: Double.random(in: 20...60), category: "Product C"),
                                ]
                            }

                            SWAreaChart(
                                dataPoints: revenueData,
                                colorMapping: ["Product A": .purple, "Product B": .orange, "Product C": .cyan],
                                stackMode: .stacked,
                                gradientOpacity: 0.4,
                                yDomain: 0...300,
                                visibleDays: 10,
                                chartHeight: 240,
                                title: "Revenue by Product (Stacked)"
                            )
                        }
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Area Chart",
                    icon: "chart.line.uptrend.xyaxis",
                    description: "Standard or stacked area chart with smooth interpolation, optional line overlay, and configurable area opacity."
                )
            }

            NavigationLink {
                ScrollView {
                    VStack(spacing: 32) {
                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let sampleData: [SWScatterChart<String>.DataPoint] = [
                                .init(date: calendar.date(byAdding: .hour, value: 8, to: today)!, value: 85, category: "Teeth"),
                                .init(date: calendar.date(byAdding: .hour, value: 12, to: today)!, value: 52, category: "Food"),
                                .init(date: calendar.date(byAdding: .hour, value: 18, to: today)!, value: 78, category: "Food"),
                                .init(date: calendar.date(byAdding: .day, value: -1, to: today)!, value: 72, category: "Teeth"),
                                .init(date: calendar.date(byAdding: .hour, value: -18, to: today)!, value: 65, category: "Food"),
                                .init(date: calendar.date(byAdding: .day, value: -2, to: today)!, value: 90, category: "Teeth"),
                                .init(date: calendar.date(byAdding: .day, value: -3, to: today)!, value: 45, category: "Food"),
                                .init(date: calendar.date(byAdding: .day, value: -3, to: today)!, value: 88, category: "Teeth"),
                            ]

                            SWScatterChart(
                                dataPoints: sampleData,
                                colorMapping: ["Teeth": .blue, "Food": .orange],
                                title: "Scan Trends"
                            )
                        }

                        Divider()

                        Group {
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())

                            let temperatureData: [SWScatterChart<String>.DataPoint] = [
                                .init(date: calendar.date(byAdding: .hour, value: 6, to: today)!, value: 36.2, category: "Morning"),
                                .init(date: calendar.date(byAdding: .hour, value: 12, to: today)!, value: 36.8, category: "Noon"),
                                .init(date: calendar.date(byAdding: .hour, value: 20, to: today)!, value: 37.1, category: "Evening"),
                                .init(date: calendar.date(byAdding: .day, value: -1, to: today)!, value: 36.5, category: "Morning"),
                            ]

                            SWScatterChart(
                                dataPoints: temperatureData,
                                colorMapping: ["Morning": .cyan, "Noon": .yellow, "Evening": .purple],
                                yDomain: 35...40,
                                visibleDays: 5,
                                chartHeight: 200,
                                title: "Body Temperature"
                            )
                        }
                    }
                    .padding()
                }
            } label: {
                ListItem(
                    title: "Scatter Chart",
                    icon: "chart.dots.scatter",
                    description: "Horizontally scrollable scatter chart with generic category types, color mapping, and configurable axis ranges."
                )
            }

            NavigationLink {
                SWDonutChart(
                    subjects: {
                        let work = SWDonutChart.Category(name: "Work")
                        let personal = SWDonutChart.Category(name: "Personal")
                        let health = SWDonutChart.Category(name: "Health")
                        return [
                            .init(name: "Meeting", category: work),
                            .init(name: "Report", category: work),
                            .init(name: "Email", category: work),
                            .init(name: "Shopping", category: personal),
                            .init(name: "Reading", category: personal),
                            .init(name: "Exercise", category: health),
                            .init(name: "Meditation", category: health),
                            .init(name: "Running", category: health),
                            .init(name: "Uncategorized Task", category: nil),
                        ]
                    }(),
                    selectedCategory: $donutSelectedCategory
                )
                .padding()
            } label: {
                ListItem(
                    title: "Donut Chart",
                    icon: "chart.pie.fill",
                    description: "Interactive donut chart with tap-to-select categories. Selected segment expands with center overlay showing count and name."
                )
            }

            NavigationLink {
                SWRadarChart(data: [
                    .init(label: "Tolerance", value: 75),
                    .init(label: "Ambition", value: 50),
                    .init(label: "Acuity", value: 50),
                    .init(label: "Creativity", value: 85),
                    .init(label: "Stability", value: 85)
                ])
                .padding(100)
            } label: {
                ListItem(
                    title: "Radar Chart",
                    icon: "pentagon",
                    description: "Animated radar (spider) chart with axis labels, grid rings, and radial lines. Supports 3+ axes with customizable max value."
                )
            }

            NavigationLink {
                VStack(spacing: 40) {
                    SWRingChart(data: [
                        .init(label: "Move", value: 75, color: .red),
                        .init(label: "Exercise", value: 50, color: .green),
                        .init(label: "Stand", value: 90, color: .cyan)
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

                    Divider()

                    SWRingChart(
                        data: [
                            .init(label: "Partner", value: 80, color: .accentColor),
                            .init(label: "Family", value: 91, color: .green),
                            .init(label: "Social", value: 63, color: .orange)
                        ],
                        size: 200,
                        ringWidth: 20,
                        spacing: 8
                    )
                }
                .padding()
            } label: {
                ListItem(
                    title: "Ring Chart",
                    icon: "circle.circle",
                    description: "Apple Watch Activity Rings style concentric ring progress chart. Supports custom center content, dimensions, and animated appear."
                )
            }

            NavigationLink {
                let timestamps: [Date] = {
                    var dates: [Date] = []
                    let calendar = Calendar.current
                    let today = Date()
                    for i in 0..<60 {
                        if Int.random(in: 0...100) < 70 {
                            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                                let count = Int.random(in: 1...3)
                                for _ in 0..<count {
                                    dates.append(date)
                                }
                            }
                        }
                    }
                    return dates
                }()

                NavigationStack {
                    Form {
                        Section {
                            SWActivityHeatmap.StreakCard(
                                streaks: timestamps,
                                colors: [.blue, .purple]
                            )
                        }
                        .listRowInsets(EdgeInsets())

                        Section {
                            SWActivityHeatmap.HeatmapGrid(
                                timestamps: timestamps,
                                days: 60,
                                baseColor: .green
                            )
                        } header: {
                            Text("Past 60 days")
                        } footer: {
                            SWActivityHeatmap.HeatmapLegend(
                                baseColor: .green
                            )
                        }
                    }
                    .navigationTitle("Activity")
                }
            } label: {
                ListItem(
                    title: "Activity Heatmap",
                    icon: "square.grid.3x3.fill",
                    description: "GitHub-style activity heatmap with streak tracking. Includes StreakCard, HeatmapGrid, HeatmapLegend sub-components."
                )
            }
        } header: {
            Text("Chart (8)")
                .font(.title3.bold())
                .textCase(nil)
                .id("chart")
        }
    }

    // MARK: - Display Section

    private var displaySection: some View {
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
                .id("display")
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
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
                .id("feedback")
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
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
                .id("input")
        }
    }
}

// MARK: - Auth Demo View (Pure UI, No Backend)

/// Standalone demo view showcasing the SWAuth module UI interactions.
/// Does not import Amplify or connect to any backend — all actions are simulated locally.
/// Internal access so ComponentRegistry can reference it from ChatView.
struct ComponentViewAuthDemo: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - View Mode

    private enum ViewMode: CaseIterable {
        case signIn
        case signUp
        case verifyEmail
        case forgotPassword
        case resetPassword
        case phoneSignIn
        case phoneVerify
    }

    // Sign-in method enum for the top segmented picker (Email / Phone)
    private enum SignInMethod: String, CaseIterable {
        case email = "Email"
        case phone = "Phone"
    }

    // MARK: - State

    @State private var viewMode: ViewMode = .signIn
    @State private var signInMethod: SignInMethod = .email
    @State private var isLoading = false

    // Sign in / sign up fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Verify email
    @State private var verificationCode = ""
    @FocusState private var isCodeFocused: Bool

    // Reset password
    @State private var resetCode = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""

    // Phone sign-in
    @State private var phoneNumber = ""
    @State private var countryCode = "+1"
    @State private var showingCountryPicker = false
    @State private var countrySearchText = ""
    @State private var phoneVerificationCode = ""
    @FocusState private var isPhoneCodeFocused: Bool

    // Agreement
    @State private var agreementChecked = false

    // MARK: - Computed Properties

    private var isValidEmail: Bool {
        let regex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    private var isValidPassword: Bool { password.count >= 8 }
    private var passwordsMatch: Bool { password == confirmPassword && isValidPassword }
    private var isValidCode: Bool { verificationCode.count == 6 }
    private var isValidResetCode: Bool { resetCode.count == 6 }
    private var isValidNewPassword: Bool { newPassword.count >= 8 }
    private var newPasswordsMatch: Bool { newPassword == confirmNewPassword && isValidNewPassword }
    private var isValidPhone: Bool {
        let expectedLength = SWCountryData.phoneLength(for: countryCode)
        return expectedLength.contains(phoneNumber.count)
    }
    private var isValidPhoneCode: Bool { phoneVerificationCode.count == 6 }
    private var fullPhoneNumber: String { "\(countryCode)\(phoneNumber)" }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                // Icon
                Image(.shipSwiftLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Title
                VStack(spacing: 8) {
                    Text(headerTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(headerSubtitle)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Sign-in method toggle buttons, shown only in signIn / phoneSignIn modes
                if viewMode == .signIn || viewMode == .phoneSignIn {
                    HStack(spacing: 12) {
                        signInMethodButton(.email, icon: "envelope.fill", label: "Email")
                        signInMethodButton(.phone, icon: "phone.fill", label: "Phone")
                    }
                }

                Spacer(minLength: 20)

                // Content based on mode
                switch viewMode {
                case .signIn, .signUp:
                    mainAuthSection
                case .verifyEmail:
                    verifyEmailSection
                case .forgotPassword:
                    forgotPasswordSection
                case .resetPassword:
                    resetPasswordSection
                case .phoneSignIn:
                    phoneSignInSection
                case .phoneVerify:
                    phoneVerifySection
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: signInMethod) { _, newMethod in
            withAnimation {
                switch newMethod {
                case .email: viewMode = .signIn
                case .phone: viewMode = .phoneSignIn
                }
            }
        }
        .sheet(isPresented: $showingCountryPicker) {
            countryCodePicker
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Header Text

    private var headerTitle: String {
        switch viewMode {
        case .signIn:         return "Welcome"
        case .signUp:         return "Create Account"
        case .verifyEmail:    return "Verify Email"
        case .forgotPassword: return "Forgot Password"
        case .resetPassword:  return "Reset Password"
        case .phoneSignIn:    return "Phone Sign In"
        case .phoneVerify:    return "Verify Phone"
        }
    }

    private var headerSubtitle: String {
        switch viewMode {
        case .signIn:         return "Sign in to continue"
        case .signUp:         return "Sign up with your email"
        case .verifyEmail:    return "Enter the 6-digit code sent to \(email.isEmpty ? "your email" : email)"
        case .forgotPassword: return "Enter your email to receive a reset code"
        case .resetPassword:  return "Enter the code and your new password"
        case .phoneSignIn:    return "Sign in with your phone number"
        case .phoneVerify:    return "Enter the 6-digit code sent to \(fullPhoneNumber)"
        }
    }

    // MARK: - Main Auth Section (Sign In / Sign Up)

    @ViewBuilder
    private var mainAuthSection: some View {
        VStack(spacing: 16) {
            emailFormSection

            if viewMode == .signIn {
                socialSignInSection
            }
        }
    }

    // MARK: - Email Form

    @ViewBuilder
    private var emailFormSection: some View {
        VStack(spacing: 12) {
            // Email input
            HStack {
                Image(systemName: "envelope")
                    .foregroundStyle(.secondary)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Password input
            HStack {
                Image(systemName: "lock")
                    .foregroundStyle(.secondary)
                SecureField("Password", text: $password)
                    .textContentType(viewMode == .signUp ? .newPassword : .password)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Password requirements hint (sign-up only)
            if viewMode == .signUp && !password.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(password.count >= 8 ? .green : .secondary)
                    Text("At least 8 characters")
                        .foregroundStyle(password.count >= 8 ? .primary : .secondary)
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }

            // Confirm password (sign-up only)
            if viewMode == .signUp {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !confirmPassword.isEmpty && password != confirmPassword {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Primary action button
            Button {
                simulateAction {
                    if viewMode == .signUp {
                        SWAlertManager.shared.show(.success, message: "Demo: Account created — verification code sent")
                        withAnimation { viewMode = .verifyEmail }
                    } else {
                        SWAlertManager.shared.show(.success, message: "Demo: Sign in successful")
                    }
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(primaryButtonText)
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isFormValid || isLoading)

            // Forgot password (sign-in only)
            if viewMode == .signIn {
                Button {
                    withAnimation { viewMode = .forgotPassword }
                } label: {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Toggle sign-in / sign-up
            Button {
                withAnimation {
                    viewMode = viewMode == .signIn ? .signUp : .signIn
                    signInMethod = .email
                    confirmPassword = ""
                }
            } label: {
                Text(viewMode == .signUp
                     ? "Already have an account? Sign In"
                     : "Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical)
    }

    private var primaryButtonText: String {
        if isLoading {
            return viewMode == .signUp ? "Creating Account..." : "Signing In..."
        }
        return viewMode == .signUp ? "Create Account" : "Sign In"
    }

    private var isFormValid: Bool {
        if viewMode == .signUp {
            return isValidEmail && passwordsMatch
        }
        return isValidEmail && isValidPassword
    }

    // MARK: - Verify Email Section

    @ViewBuilder
    private var verifyEmailSection: some View {
        VStack(spacing: 16) {
            // 6-digit code input
            TextField("000000", text: $verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isCodeFocused)
                .multilineTextAlignment(.center)
                .font(.title2.monospacedDigit())
                .padding(.vertical, 16)
                .background(.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: verificationCode) { _, newValue in
                    verificationCode = String(newValue.filter(\.isNumber).prefix(6))
                }

            // Verify button
            Button {
                simulateAction {
                    SWAlertManager.shared.show(.success, message: "Demo: Email verified successfully")
                    withAnimation {
                        viewMode = .signIn
                        signInMethod = .email
                    }
                    verificationCode = ""
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Verifying..." : "Verify Email")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidCode || isLoading)

            // Resend code
            Button {
                SWAlertManager.shared.show(.info, message: "Demo: Verification code resent")
            } label: {
                Text("Resend Code")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }

            // Back
            Button {
                withAnimation {
                    viewMode = .signIn
                    signInMethod = .email
                    verificationCode = ""
                }
            } label: {
                Text("Back to Sign In")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isCodeFocused = true
        }
    }

    // MARK: - Forgot Password Section

    @ViewBuilder
    private var forgotPasswordSection: some View {
        VStack(spacing: 16) {
            // Email input
            HStack {
                Image(systemName: "envelope")
                    .foregroundStyle(.secondary)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Send reset code
            Button {
                simulateAction {
                    SWAlertManager.shared.show(.success, message: "Demo: Reset code sent to \(email)")
                    withAnimation { viewMode = .resetPassword }
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Sending..." : "Send Reset Code")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidEmail || isLoading)

            // Back
            Button {
                withAnimation {
                    viewMode = .signIn
                    signInMethod = .email
                }
            } label: {
                Text("Back to Sign In")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Reset Password Section

    @ViewBuilder
    private var resetPasswordSection: some View {
        VStack(spacing: 16) {
            // Reset code
            VStack(alignment: .leading, spacing: 4) {
                Text("Verification Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("000000", text: $resetCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.title2.monospacedDigit())
                    .padding(.vertical, 16)
                    .background(.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: resetCode) { _, newValue in
                        resetCode = String(newValue.filter(\.isNumber).prefix(6))
                    }
            }

            // New password
            VStack(alignment: .leading, spacing: 4) {
                Text("New Password")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Image(systemName: "lock")
                        .foregroundStyle(.secondary)
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Password requirements
            if !newPassword.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: newPassword.count >= 8 ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(newPassword.count >= 8 ? .green : .secondary)
                    Text("At least 8 characters")
                        .foregroundStyle(newPassword.count >= 8 ? .primary : .secondary)
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }

            // Confirm new password
            VStack(alignment: .leading, spacing: 4) {
                Text("Confirm New Password")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    SecureField("Confirm New Password", text: $confirmNewPassword)
                        .textContentType(.newPassword)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !confirmNewPassword.isEmpty && newPassword != confirmNewPassword {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Reset password button
            Button {
                simulateAction {
                    SWAlertManager.shared.show(.success, message: "Demo: Password reset successful")
                    withAnimation {
                        viewMode = .signIn
                        signInMethod = .email
                        resetCode = ""
                        newPassword = ""
                        confirmNewPassword = ""
                        password = ""
                    }
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Resetting..." : "Reset Password")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidResetCode || !newPasswordsMatch || isLoading)

            // Back
            Button {
                withAnimation {
                    viewMode = .signIn
                    signInMethod = .email
                    resetCode = ""
                    newPassword = ""
                    confirmNewPassword = ""
                }
            } label: {
                Text("Back to Sign In")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Social Sign-In Section

    @ViewBuilder
    private var socialSignInSection: some View {
        VStack(spacing: 16) {
            // Divider
            HStack {
                Rectangle()
                    .fill(.tertiary)
                    .frame(height: 1)
                Text("or continue with")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .fill(.tertiary)
                    .frame(height: 1)
            }
            .padding(.top, 16)

            // Social buttons
            HStack(spacing: 12) {
                Button {
                    SWAlertManager.shared.show(.info, message: "Demo: Apple sign-in requires Auth Recipe")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                        Text("Apple")
                    }
                }
                .buttonStyle(.swSecondary)

                Button {
                    SWAlertManager.shared.show(.info, message: "Demo: Google sign-in requires Auth Recipe")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 18))
                        Text("Google")
                    }
                }
                .buttonStyle(.swSecondary)
            }

            // Agreement checker
            SWAgreementChecker(agreementChecked: $agreementChecked)
        }
    }

    // MARK: - Phone Sign-In Section

    @ViewBuilder
    private var phoneSignInSection: some View {
        VStack(spacing: 16) {
            // Country code + phone number input
            HStack(spacing: 8) {
                // Country code selector button
                Button {
                    showingCountryPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(SWCountryData.flag(for: countryCode))
                        Text(countryCode)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Phone number input
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: phoneNumber) { _, newValue in
                        let cleaned = newValue.replacingOccurrences(of: " ", with: "")
                        if cleaned != newValue {
                            phoneNumber = cleaned
                        }
                    }
            }

            // Send verification code button
            Button {
                simulateAction {
                    SWAlertManager.shared.show(.success, message: "Demo: Code sent to \(fullPhoneNumber)")
                    withAnimation { viewMode = .phoneVerify }
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Sending..." : "Send Verification Code")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidPhone || isLoading)

            // Social sign-in area
            socialSignInSection
        }
        .padding(.vertical)
    }

    // MARK: - Phone Verify Section

    @ViewBuilder
    private var phoneVerifySection: some View {
        VStack(spacing: 16) {
            // 6-digit verification code input
            TextField("000000", text: $phoneVerificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isPhoneCodeFocused)
                .multilineTextAlignment(.center)
                .font(.title2.monospacedDigit())
                .padding(.vertical, 16)
                .background(.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: phoneVerificationCode) { _, newValue in
                    phoneVerificationCode = String(newValue.filter(\.isNumber).prefix(6))
                }

            // Verify button
            Button {
                simulateAction {
                    SWAlertManager.shared.show(.success, message: "Demo: Phone verified successfully")
                    withAnimation {
                        viewMode = .signIn
                        signInMethod = .email
                    }
                    phoneVerificationCode = ""
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isLoading ? "Verifying..." : "Verify Phone")
                }
            }
            .buttonStyle(.swPrimary)
            .disabled(!isValidPhoneCode || isLoading)

            // Resend code
            Button {
                SWAlertManager.shared.show(.info, message: "Demo: Verification code resent to \(fullPhoneNumber)")
            } label: {
                Text("Resend Code")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }

            // Go back to phoneSignIn, keeping signInMethod = .phone
            Button {
                withAnimation {
                    viewMode = .phoneSignIn
                    phoneVerificationCode = ""
                }
            } label: {
                Text("Back")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isPhoneCodeFocused = true
        }
    }

    // MARK: - Country Code Picker

    private var countryCodePicker: some View {
        let filteredCountries: [SWCountry] = countrySearchText.isEmpty
            ? SWCountryData.allCountries
            : SWCountryData.allCountries.filter {
                $0.name.localizedCaseInsensitiveContains(countrySearchText) ||
                $0.code.contains(countrySearchText)
            }
        let groupedCountries = Dictionary(grouping: filteredCountries) { country in
            String(country.name.prefix(1)).uppercased()
        }.sorted { $0.key < $1.key }

        return NavigationStack {
            List {
                ForEach(groupedCountries, id: \.key) { letter, countries in
                    Section(header: Text(letter)) {
                        ForEach(countries, id: \.name) { country in
                            Button {
                                countryCode = country.code
                                countrySearchText = ""
                                showingCountryPicker = false
                            } label: {
                                HStack {
                                    Text(country.flag)
                                        .font(.title2)
                                    HStack(spacing: 8) {
                                        Text(country.name)
                                            .foregroundStyle(.primary)
                                        Text(country.code)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if countryCode == country.code {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $countrySearchText, prompt: "Search")
            .tint(.primary)
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        countrySearchText = ""
                        showingCountryPicker = false
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Sign-in method toggle button: selected state uses accentColor + capsule background; unselected uses secondary
    private func signInMethodButton(_ method: SignInMethod, icon: String, label: String) -> some View {
        Button {
            withAnimation { signInMethod = method }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.subheadline)
            .fontWeight(signInMethod == method ? .medium : .regular)
            .foregroundStyle(signInMethod == method ? Color.accentColor : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                signInMethod == method ? Color.accentColor.opacity(0.1) : Color.clear,
                in: Capsule()
            )
        }
    }

    /// Simulates a loading state for 1 second, then executes the completion
    private func simulateAction(completion: @escaping () -> Void) {
        isLoading = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            isLoading = false
            completion()
        }
    }
}

// MARK: - Face Camera Demo View (Real Camera with Face Tracking)

/// SWFaceCameraView includes its own close button — present it directly.
struct ComponentViewFaceCameraDemo: View {
    var body: some View {
        SWFaceCameraView()
    }
}

// MARK: - Camera Demo View (Real Camera, No Processing)

/// Demo using real SWCameraView — captured or selected photos are not processed or saved.
struct ComponentViewCameraDemo: View {
    @State private var capturedImage: UIImage?

    var body: some View {
        SWCameraView(image: $capturedImage)
            .swAlert()
    }
}

// MARK: - Paywall Demo View (Mock SubscriptionStoreView UI)

/// Mock SubscriptionStoreView UI — no StoreKit dependency, ready for showcase.
struct ComponentViewPaywallDemo: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .yearly

    private enum Plan: String {
        case monthly, yearly
    }

    // Mock product data
    private let monthlyPrice = "$9.99"
    private let yearlyPrice = "$59.99"
    private let features: [(icon: String, text: String)] = [
        ("cpu.fill", "AI-optimized recipes for Claude, Cursor & Windsurf"),
        ("checkmark.seal.fill", "Full-stack iOS + AWS backend, battle-tested in production"),
        ("terminal.fill", "One MCP command — zero downloads, instant access"),
        ("arrow.triangle.branch", "Lifetime updates & new recipes included"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Marketing content
                    marketingHeader

                    // Subscription options
                    subscriptionOptions

                    // Subscribe button
                    subscribeButton

                    // Footer links
                    footerLinks
                }
                .padding()
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }

    // MARK: - Marketing Header

    private var marketingHeader: some View {
        VStack(spacing: 16) {
            SWShakingIcon(image: Image(.shipSwiftLogo), cornerRadius: 12)
                .padding(.vertical)

            Text("ShipSwift Pro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Ship your iOS app 10x faster")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(features, id: \.icon) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: feature.icon)
                            .foregroundStyle(.accent)
                            .imageScale(.small)
                            .frame(width: 20)
                        Text(feature.text)
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.top, 8)
    }

    // MARK: - Subscription Options

    private var subscriptionOptions: some View {
        VStack(spacing: 12) {
            planCard(
                plan: .yearly,
                title: "Yearly",
                price: yearlyPrice,
                period: "/year",
                badge: "Best Value"
            )

            planCard(
                plan: .monthly,
                title: "Monthly",
                price: monthlyPrice,
                period: "/month",
                badge: nil
            )
        }
    }

    private func planCard(plan: Plan, title: String, price: String, period: String, badge: String?) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = plan }
        } label: {
            HStack {
                // Selection indicator
                Image(systemName: selectedPlan == plan ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selectedPlan == plan ? .accent : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(price)\(period)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.accent, in: Capsule())
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        selectedPlan == plan ? Color.accentColor : Color(.separator),
                        lineWidth: selectedPlan == plan ? 2 : 1
                    )
            )
        }
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                SWAlertManager.shared.show(.info, message: "This is a demo — no real purchase")
            }
        } label: {
            Text("Get ShipSwift Pro")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    SWAlertManager.shared.show(.info, message: "This is a demo — no purchases to restore")
                }
            }
            .font(.subheadline)

            Button("Redeem Code") {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    SWAlertManager.shared.show(.info, message: "This is a demo — no codes to redeem")
                }
            }
            .font(.subheadline)

            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://shipswift.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://shipswift.app/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Chat Demo View (SWChatView with Simulated Response)

/// Demo showcasing SWChatView with a simulated echo-style AI response.
/// No ASR config is provided so the microphone button is hidden in demo mode.
struct ComponentViewChatDemo: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [SWChatMessage] = [
        SWChatMessage(
            content: "Welcome! Send a message to see the demo response.",
            isUser: false
        ),
    ]
    @State private var isWaiting = false

    var body: some View {
        SWChatView(
            messages: $messages,
            isDisabled: isWaiting
        ) { text in
            // Simulate AI response with a 1-second delay
            isWaiting = true
            Task {
                try? await Task.sleep(for: .seconds(1))
                messages.append(
                    SWChatMessage(
                        content: "This is a demo response. Connect ShipSwift MCP to enable full AI chat functionality.",
                        isUser: false
                    )
                )
                isWaiting = false
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ComponentView(scrollTarget: .constant(nil))
}
