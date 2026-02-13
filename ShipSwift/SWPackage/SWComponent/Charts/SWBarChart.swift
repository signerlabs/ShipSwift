//
//  SWBarChart.swift
//  ShipSwift
//
//  Horizontally scrollable bar chart built on Swift Charts (BarMark). Supports grouped
//  and stacked display modes, multiple series with color mapping, and optional value labels.
//  Generic over CategoryType for series grouping. Includes a convenience initializer for
//  String categories.
//
//  Usage:
//    // Basic grouped bar chart
//    let data: [SWBarChart<String>.DataPoint] = [
//        .init(date: Date(), value: 120, category: "Online"),
//        .init(date: Date(), value: 85, category: "Offline"),
//    ]
//    let colors: [String: Color] = ["Online": .blue, "Offline": .orange]
//
//    SWBarChart(dataPoints: data, colorMapping: colors, title: "Sales Channel")
//
//    // Stacked bar chart with custom config
//    SWBarChart(
//        dataPoints: data,
//        colorMapping: colors,
//        stackMode: .stacked,
//        showValueLabels: true,
//        barCornerRadius: 4,
//        yDomain: 0...300,
//        visibleDays: 14,
//        chartHeight: 250,
//        title: "Revenue Breakdown"
//    )
//
//  Data Model (built-in):
//    SWBarChart<CategoryType>.DataPoint
//      - date: Date
//      - value: Double
//      - category: CategoryType
//
//  Parameters:
//    - dataPoints: [DataPoint]                      — Array of data points
//    - colorMapping: [CategoryType: Color]           — Category to color mapping
//    - stackMode: StackMode                         — .grouped or .stacked (default .grouped)
//    - showValueLabels: Bool                        — Show value above each bar (default false)
//    - barCornerRadius: CGFloat                     — Corner radius for bars (default 3)
//    - yDomain: ClosedRange<Double>?                — Y-axis range (default auto)
//    - scrollableDaysBack: Int                      — Scrollable days backward (default 30)
//    - scrollableDaysForward: Int                   — Scrollable days forward (default 7)
//    - visibleDays: Int                             — Visible days range (default 7)
//    - chartHeight: CGFloat                         — Chart height (default 200)
//    - title: String?                               — Optional title
//
//  Notes:
//    - Appear animation: bars grow from 0 to target value with easeOut 1.2s after 0.2s delay
//    - Y-axis range is fixed to real data bounds during animation (bars grow, axis stays)
//
//  Created by Wei Zhong on 2/13/26.
//

import SwiftUI
import Charts

// MARK: - SWBarChart

struct SWBarChart<CategoryType: Hashable & Plottable>: View {
    // MARK: - Enums

    /// Display mode for multi-series bars
    enum StackMode {
        /// Bars side by side within the same date bucket
        case grouped
        /// Bars stacked on top of each other
        case stacked
    }

    // MARK: - Built-in Data Model

    /// Data point model for the bar chart
    struct DataPoint: Identifiable {
        let id: UUID
        let date: Date
        let value: Double
        let category: CategoryType

        init(id: UUID = UUID(), date: Date, value: Double, category: CategoryType) {
            self.id = id
            self.date = date
            self.value = value
            self.category = category
        }
    }

    // MARK: - Properties

    /// Array of data points
    let dataPoints: [DataPoint]

    /// Color mapping for categories
    let colorMapping: [CategoryType: Color]

    /// Grouped or stacked display mode
    var stackMode: StackMode = .grouped

    /// Whether to show value annotations above bars
    var showValueLabels: Bool = false

    /// Corner radius for bar shape
    var barCornerRadius: CGFloat = 3

    /// Y-axis range (nil = automatic)
    var yDomain: ClosedRange<Double>? = nil

    /// X-axis scrollable total range (days back from today)
    var scrollableDaysBack: Int = 30

    /// X-axis scrollable total range (days forward from today)
    var scrollableDaysForward: Int = 7

    /// Visible range (days)
    var visibleDays: Int = 7

    /// Chart height
    var chartHeight: CGFloat = 200

    /// Title (optional)
    var title: String? = nil

    /// 动画进度（0 到 1），控制柱状图从 0 生长到目标值
    @State private var animationProgress: Double = 0

    // MARK: - Computed Properties

    /// 基于真实数据计算的 Y 轴范围（动画期间保持不变，避免 Y 轴随数据缩放）
    /// stacked 模式下取同一日期各系列之和的最大值，grouped 模式下取单一数据点最大值
    private var effectiveYDomain: ClosedRange<Double>? {
        if let yDomain = yDomain { return yDomain }
        guard !dataPoints.isEmpty else { return nil }

        let maxVal: Double
        if stackMode == .stacked {
            // 按日期（天）分组后求和，取最大值
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: dataPoints) { calendar.startOfDay(for: $0.date) }
            guard let stackMax = grouped.values.map({ $0.reduce(0) { $0 + $1.value } }).max(), stackMax > 0 else { return nil }
            maxVal = stackMax
        } else {
            guard let singleMax = dataPoints.map(\.value).max(), singleMax > 0 else { return nil }
            maxVal = singleMax
        }
        return 0...maxVal
    }

    /// X-axis scrollable total range
    private var chartXDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -scrollableDaysBack, to: startOfToday)!
        let endDate = calendar.date(byAdding: .day, value: scrollableDaysForward, to: startOfToday)!
        return startDate...endDate
    }

    /// Chart initial scroll position: center today in the visible range
    private var chartInitialScrollDate: Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let offset = visibleDays / 2
        return calendar.date(byAdding: .day, value: -offset, to: startOfToday)!
    }

    /// Visible range time length (seconds)
    private var visibleDomainLength: Int {
        visibleDays * 24 * 60 * 60
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            if let title = title {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            // Chart（y 值乘以 animationProgress 实现从 0 生长的动画效果）
            Chart(dataPoints) { point in
                if stackMode == .grouped {
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Value", point.value * animationProgress)
                    )
                    .foregroundStyle(by: .value("Category", point.category))
                    .position(by: .value("Category", point.category))
                    .clipShape(RoundedRectangle(cornerRadius: barCornerRadius))
                    .annotation(position: .top) {
                        valueLabel(for: point)
                    }
                } else {
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Value", point.value * animationProgress)
                    )
                    .foregroundStyle(by: .value("Category", point.category))
                    .clipShape(RoundedRectangle(cornerRadius: barCornerRadius))
                    .annotation(position: .top) {
                        valueLabel(for: point)
                    }
                }
            }
            .chartForegroundStyleScale(
                domain: Array(colorMapping.keys),
                range: Array(colorMapping.values)
            )
            .chartXScale(domain: chartXDomain)
            .applyOptionalYDomain(effectiveYDomain)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: visibleDomainLength)
            .chartScrollPosition(initialX: chartInitialScrollDate)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartLegend(position: .top, alignment: .trailing)
            .frame(height: chartHeight)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                    animationProgress = 1.0
                }
            }
        }
    }

    // MARK: - Private Helpers

    /// Value label annotation (only rendered when showValueLabels is true)
    @ViewBuilder
    private func valueLabel(for point: DataPoint) -> some View {
        if showValueLabels {
            Text("\(Int(point.value))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Y-Domain Helper

private extension View {
    /// Conditionally apply Y-axis domain when provided
    @ViewBuilder
    func applyOptionalYDomain(_ domain: ClosedRange<Double>?) -> some View {
        if let domain = domain {
            self.chartYScale(domain: domain)
        } else {
            self
        }
    }
}

// MARK: - Convenience Initializer for String Category

extension SWBarChart where CategoryType == String {
    /// Convenience initializer (using String as category type)
    init(
        dataPoints: [DataPoint],
        colorMapping: [String: Color],
        stackMode: StackMode = .grouped,
        showValueLabels: Bool = false,
        barCornerRadius: CGFloat = 3,
        yDomain: ClosedRange<Double>? = nil,
        scrollableDaysBack: Int = 30,
        scrollableDaysForward: Int = 7,
        visibleDays: Int = 7,
        chartHeight: CGFloat = 200,
        title: String? = nil
    ) {
        self.dataPoints = dataPoints
        self.colorMapping = colorMapping
        self.stackMode = stackMode
        self.showValueLabels = showValueLabels
        self.barCornerRadius = barCornerRadius
        self.yDomain = yDomain
        self.scrollableDaysBack = scrollableDaysBack
        self.scrollableDaysForward = scrollableDaysForward
        self.visibleDays = visibleDays
        self.chartHeight = chartHeight
        self.title = title
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 32) {
            // Example 1: Grouped bar chart (two series)
            Group {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())

                let salesData: [SWBarChart<String>.DataPoint] = (0..<10).flatMap { dayOffset -> [SWBarChart<String>.DataPoint] in
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

            // Example 2: Stacked bar chart with value labels
            Group {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())

                let stackedData: [SWBarChart<String>.DataPoint] = (0..<7).flatMap { dayOffset -> [SWBarChart<String>.DataPoint] in
                    let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                    return [
                        .init(date: date, value: Double.random(in: 30...80), category: "Food"),
                        .init(date: date, value: Double.random(in: 20...50), category: "Transport"),
                        .init(date: date, value: Double.random(in: 10...40), category: "Entertainment"),
                    ]
                }

                SWBarChart(
                    dataPoints: stackedData,
                    colorMapping: [
                        "Food": .green,
                        "Transport": .blue,
                        "Entertainment": .purple,
                    ],
                    stackMode: .stacked,
                    showValueLabels: false,
                    yDomain: 0...200,
                    visibleDays: 7,
                    chartHeight: 250,
                    title: "Daily Expenses (Stacked)"
                )
            }

            Divider()

            // Example 3: Single series bar chart
            Group {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())

                let singleData: [SWBarChart<String>.DataPoint] = (0..<14).map { dayOffset in
                    let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                    return .init(date: date, value: Double.random(in: 2000...12000), category: "Steps")
                }

                SWBarChart(
                    dataPoints: singleData,
                    colorMapping: ["Steps": .mint],
                    showValueLabels: true,
                    barCornerRadius: 5,
                    visibleDays: 7,
                    chartHeight: 200,
                    title: "Daily Steps"
                )
            }
        }
        .padding()
    }
}
