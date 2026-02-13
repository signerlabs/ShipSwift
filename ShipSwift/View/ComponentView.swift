//
//  ComponentView.swift
//  ShipSwift
//
//  Components tab placeholder — will be replaced with component showcase list
//
//  Created by Wei Zhong on 12/2/26.
//

import SwiftUI
import Charts

struct ComponentView: View {
    @State private var donutSelectedCategory: String? = nil
    @State private var selectedInputTab = 0
    @State private var stepperValue = 1
    @State private var agreementChecked = false
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            List {
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
                }
                
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
                    Text("Charts (8)")
                        .font(.title3.bold())
                        .textCase(nil)
                }
                
                // MARK: - Display 组件分区
                Section {
                    // 浮动标签组件 — 图片上方悬浮动画胶囊标签
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
                    
                    // 滚动问答组件 — 自动滚动的水平问答胶囊轮播
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
                        ) { question in
                            print("Tapped: \(question)")
                        }
                    } label: {
                        ListItem(
                            title: "Scrolling FAQ",
                            icon: "bubble.left.and.text.bubble.right",
                            description: "Auto-scrolling horizontal FAQ carousel with alternating row directions. Tapping a pill triggers a callback."
                        )
                    }
                    
                    // 旋转名言组件 — 自动轮播名人名言
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
                    
                    // 基础展示元素合并页 — BulletPointText + GradientDivider + Label
                    NavigationLink {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                
                                // 区域一：SWBulletPointText 演示
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
                                
                                // 区域二：SWGradientDivider 演示
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
                                
                                // 区域三：SWLabelWithIcon 演示
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
                } header: {
                    Text("Display (6)")
                        .font(.title3.bold())
                        .textCase(nil)
                }
                
                // MARK: - Feedback 组件分区
                Section {
                    // 全局 Toast 弹窗组件 — 支持 info/success/warning/error 四种预设及自定义样式
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
                    
                    // 全屏加载遮罩组件 — 毛玻璃背景 + 可选图标脉冲动画
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
                    
                    // 思考指示器组件 — 三点弹跳动画，用于聊天输入状态
                    NavigationLink {
                        VStack(spacing: 40) {
                            // 默认样式
                            VStack(spacing: 8) {
                                Text("Default")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                SWThinkingIndicator()
                            }
                            
                            // 聊天气泡中使用
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
                            
                            // 自定义颜色和大小
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
                
                // MARK: - Input 组件分区
                Section {
                    // 胶囊形 Tab 按钮 — 用于自定义分段控件和筛选栏
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
                    
                    // 数值步进器 — 带动画过渡和触觉反馈的紧凑步进控件
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
                    
                    // 协议勾选框 — 带服务条款和隐私政策链接的复选框
                    NavigationLink {
                        VStack {
                            Spacer()
                            SWAgreementChecker(agreementChecked: $agreementChecked)
                                .padding(.horizontal)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } label: {
                        ListItem(
                            title: "SWAgreementChecker",
                            icon: "checkmark.square",
                            description: "Agreement checkbox with Terms of Service and Privacy Policy links. Configurable URLs."
                        )
                    }
                    
                    // 添加表单 — 带文本输入的底部弹出面板
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
                            SWAddSheet(isPresented: $showAddSheet) { text in
                                print("User entered: \(text)")
                            }
                        }
                    } label: {
                        ListItem(
                            title: "SWAddSheet",
                            icon: "plus.rectangle.on.rectangle",
                            description: "Bottom sheet with text input, cancel and confirm buttons. Presented as medium detent for collecting user input."
                        )
                    }
                } header: {
                    Text("Input (4)")
                        .font(.title3.bold())
                        .textCase(nil)
                }
            }
            .navigationTitle("Components")
        }
    }
}

#Preview {
    ComponentView()
}
