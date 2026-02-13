//
//  SWAreaChart.swift
//  ShipSwift
//
//  Horizontally scrollable area chart built on Swift Charts (AreaMark). Supports
//  multiple series with color mapping, configurable area opacity, optional line overlay,
//  and configurable interpolation. Generic over CategoryType for series grouping.
//  Includes a convenience initializer for String categories.
//
//  Usage:
//    // Basic area chart
//    let data: [SWAreaChart<String>.DataPoint] = [
//        .init(date: Date(), value: 72, category: "Downloads"),
//    ]
//    let colors: [String: Color] = ["Downloads": .blue]
//
//    SWAreaChart(dataPoints: data, colorMapping: colors, title: "App Downloads")
//
//    // Stacked area chart with gradient and line overlay
//    SWAreaChart(
//        dataPoints: data,
//        colorMapping: colors,
//        stackMode: .stacked,
//        showLineOverlay: true,
//        interpolationMethod: .catmullRom,
//        gradientOpacity: 0.3,
//        yDomain: 0...500,
//        visibleDays: 14,
//        chartHeight: 240,
//        title: "Traffic Sources"
//    )
//
//  Data Model (built-in):
//    SWAreaChart<CategoryType>.DataPoint
//      - date: Date
//      - value: Double
//      - category: CategoryType
//
//  Parameters:
//    - dataPoints: [DataPoint]                      — Array of data points
//    - colorMapping: [CategoryType: Color]           — Category to color mapping
//    - stackMode: StackMode                         — .standard or .stacked (default .standard)
//    - showLineOverlay: Bool                        — Draw LineMark on top of area (default true)
//    - interpolationMethod: InterpolationMethod      — Line/area interpolation (default .catmullRom)
//    - gradientOpacity: Double                      — Opacity of the area fill (default 0.15)
//    - yDomain: ClosedRange<Double>?                — Y-axis range (default auto)
//    - scrollableDaysBack: Int                      — Scrollable days backward (default 30)
//    - scrollableDaysForward: Int                   — Scrollable days forward (default 7)
//    - visibleDays: Int                             — Visible days range (default 7)
//    - chartHeight: CGFloat                         — Chart height (default 200)
//    - title: String?                               — Optional title
//
//  Notes:
//    - Appear animation: area and line draw from left to right along the date axis with easeOut 1.2s after 0.2s delay
//    - Y-axis range is fixed to real data bounds during animation (axis stays, area appears progressively)
//
//  Created by Wei Zhong on 2/13/26.
//

import SwiftUI
import Charts

// MARK: - SWAreaChart

struct SWAreaChart<CategoryType: Hashable & Plottable>: View {
    // MARK: - Enums

    /// Display mode for multi-series areas
    enum StackMode {
        /// Each series rendered independently (overlapping)
        case standard
        /// Series stacked on top of each other
        case stacked
    }

    // MARK: - Built-in Data Model

    /// Data point model for the area chart
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

    /// Standard or stacked display mode
    var stackMode: StackMode = .standard

    /// Whether to draw a LineMark on top of the area
    var showLineOverlay: Bool = true

    /// Line/area interpolation method
    var interpolationMethod: InterpolationMethod = .catmullRom

    /// Opacity of the area fill (0.0 = hidden, 1.0 = fully opaque)
    var gradientOpacity: Double = 0.15

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

    /// 动画进度（0 到 1），控制面积图沿日期轴从左到右逐步出现
    @State private var animationProgress: Double = 0

    // MARK: - Computed Properties

    /// 数据的日期范围（最小日期和最大日期）
    private var dateRange: (min: Date, max: Date) {
        let dates = dataPoints.map(\.date)
        let minDate = dates.min() ?? Date()
        let maxDate = dates.max() ?? Date()
        return (minDate, maxDate)
    }

    /// 当前动画截止日期：根据 animationProgress 映射到日期范围内的某一时刻
    private var animatedMaxDate: Date {
        let range = dateRange
        let totalInterval = range.max.timeIntervalSince(range.min)
        let animatedInterval = totalInterval * animationProgress
        return range.min.addingTimeInterval(animatedInterval)
    }

    /// 动画范围内可见的数据点（日期 <= animatedMaxDate）
    private var visibleDataPoints: [DataPoint] {
        dataPoints.filter { $0.date <= animatedMaxDate }
    }

    /// 基于真实数据计算的 Y 轴范围（动画期间保持不变，避免 Y 轴随数据缩放）
    /// stacked 模式下取同一日期各系列之和的最大值，standard 模式下取单一数据点最大值
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

            // Chart（沿日期轴从左到右逐步渲染，只显示 animatedMaxDate 以内的数据点）
            Chart {
                ForEach(visibleDataPoints) { point in
                    // 面积标记（带渐变）
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value),
                        stacking: stackMode == .stacked ? .standard : .unstacked
                    )
                    .foregroundStyle(by: .value("Category", point.category))
                    .interpolationMethod(interpolationMethod)
                    .opacity(gradientOpacity)

                    // 面积上方的线条覆盖层
                    if showLineOverlay {
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(by: .value("Category", point.category))
                        .interpolationMethod(interpolationMethod)
                        .lineStyle(StrokeStyle(lineWidth: 2))
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

extension SWAreaChart where CategoryType == String {
    /// Convenience initializer (using String as category type)
    init(
        dataPoints: [DataPoint],
        colorMapping: [String: Color],
        stackMode: StackMode = .standard,
        showLineOverlay: Bool = true,
        interpolationMethod: InterpolationMethod = .catmullRom,
        gradientOpacity: Double = 0.15,
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
        self.showLineOverlay = showLineOverlay
        self.interpolationMethod = interpolationMethod
        self.gradientOpacity = gradientOpacity
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
            // Example 1: Standard multi-series area chart (overlapping)
            Group {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())

                let trafficData: [SWAreaChart<String>.DataPoint] = (0..<14).flatMap { dayOffset -> [SWAreaChart<String>.DataPoint] in
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

            // Example 2: Stacked area chart with catmullRom
            Group {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())

                let revenueData: [SWAreaChart<String>.DataPoint] = (0..<10).flatMap { dayOffset -> [SWAreaChart<String>.DataPoint] in
                    let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                    return [
                        .init(date: date, value: Double.random(in: 40...120), category: "Product A"),
                        .init(date: date, value: Double.random(in: 30...80), category: "Product B"),
                        .init(date: date, value: Double.random(in: 20...60), category: "Product C"),
                    ]
                }

                SWAreaChart(
                    dataPoints: revenueData,
                    colorMapping: [
                        "Product A": .purple,
                        "Product B": .orange,
                        "Product C": .cyan,
                    ],
                    stackMode: .stacked,
                    interpolationMethod: .catmullRom,
                    gradientOpacity: 0.4,
                    yDomain: 0...300,
                    visibleDays: 10,
                    chartHeight: 240,
                    title: "Revenue by Product (Stacked)"
                )
            }

            Divider()

            // Example 3: Single series area chart (no line overlay)
            Group {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())

                let memoryData: [SWAreaChart<String>.DataPoint] = (0..<7).map { dayOffset in
                    let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                    return .init(date: date, value: Double.random(in: 1.5...4.0), category: "Memory")
                }

                SWAreaChart(
                    dataPoints: memoryData,
                    colorMapping: ["Memory": .red],
                    showLineOverlay: false,
                    interpolationMethod: .monotone,
                    gradientOpacity: 0.3,
                    visibleDays: 7,
                    chartHeight: 180,
                    title: "Memory Usage (GB)"
                )
            }
        }
        .padding()
    }
}
