//
//  ChartView.swift
//  ShipSwift
//
//  Charts tab — showcases chart components
//
//  Created by Wei Zhong on 13/2/26.
//

import SwiftUI
import Charts

struct ChartView: View {
    @State private var donutSelectedCategory: String? = nil
    
    var body: some View {
        NavigationStack {
            List {
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
            }
            .navigationTitle("Charts")
        }
    }
}

#Preview {
    ChartView()
}
