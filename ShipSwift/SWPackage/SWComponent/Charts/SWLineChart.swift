//
//  SWLineChart.swift
//  ShipSwift
//
//  Horizontally scrollable line chart built on Swift Charts (LineMark). Supports
//  multiple series with color mapping, optional RuleMark reference lines, configurable
//  interpolation methods, and point markers. Generic over CategoryType for series
//  grouping. Includes a convenience initializer for String categories.
//
//  Usage:
//    // Basic multi-series line chart
//    let data: [SWLineChart<String>.DataPoint] = [
//        .init(date: Date(), value: 72, category: "Revenue"),
//        .init(date: Date(), value: 45, category: "Cost"),
//    ]
//    let colors: [String: Color] = ["Revenue": .blue, "Cost": .red]
//
//    SWLineChart(dataPoints: data, colorMapping: colors, title: "Financials")
//
//    // With reference line and custom interpolation
//    SWLineChart(
//        dataPoints: data,
//        colorMapping: colors,
//        referenceLines: [.init(value: 60, label: "Target", color: .orange)],
//        interpolationMethod: .catmullRom,
//        showPointMarkers: true,
//        yDomain: 0...100,
//        visibleDays: 14,
//        chartHeight: 220,
//        title: "Performance"
//    )
//
//  Data Model (built-in):
//    SWLineChart<CategoryType>.DataPoint
//      - date: Date
//      - value: Double
//      - category: CategoryType
//
//    SWLineChart.ReferenceLine
//      - value: Double        — Y-axis position
//      - label: String?       — Optional annotation text
//      - color: Color         — Line color (default .secondary)
//      - style: StrokeStyle   — Dash style
//
//  Parameters:
//    - dataPoints: [DataPoint]                      — Array of data points
//    - colorMapping: [CategoryType: Color]           — Category to color mapping
//    - referenceLines: [ReferenceLine]               — Horizontal reference lines (default [])
//    - interpolationMethod: InterpolationMethod       — Line interpolation (default .linear)
//    - showPointMarkers: Bool                        — Show PointMark on each data point (default false)
//    - yDomain: ClosedRange<Double>?                 — Y-axis range (default auto)
//    - scrollableDaysBack: Int                       — Scrollable days backward (default 30)
//    - scrollableDaysForward: Int                    — Scrollable days forward (default 7)
//    - visibleDays: Int                              — Visible days range (default 7)
//    - chartHeight: CGFloat                          — Chart height (default 200)
//    - title: String?                                — Optional title
//
//  Notes:
//    - Appear animation: lines draw from left to right along the date axis with easeOut 1.2s after 0.2s delay
//    - Y-axis range is fixed to real data bounds during animation (axis stays, lines appear progressively)
//    - Reference lines are always visible and do not participate in the date-axis animation
//
//  Created by Wei Zhong on 2/13/26.
//

import SwiftUI
import Charts

// MARK: - SWLineChart

struct SWLineChart<CategoryType: Hashable & Plottable>: View {
    // MARK: - Built-in Data Models

    /// Data point model for the line chart
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

    /// Horizontal reference line (RuleMark)
    struct ReferenceLine {
        let value: Double
        let label: String?
        let color: Color
        let style: StrokeStyle

        init(
            value: Double,
            label: String? = nil,
            color: Color = .secondary,
            style: StrokeStyle = StrokeStyle(lineWidth: 1, dash: [5, 3])
        ) {
            self.value = value
            self.label = label
            self.color = color
            self.style = style
        }
    }

    // MARK: - Properties

    /// Array of data points
    let dataPoints: [DataPoint]

    /// Color mapping for categories
    let colorMapping: [CategoryType: Color]

    /// Horizontal reference lines rendered via RuleMark
    var referenceLines: [ReferenceLine] = []

    /// Line interpolation method
    var interpolationMethod: InterpolationMethod = .linear

    /// Whether to show PointMark on each data point
    var showPointMarkers: Bool = false

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

    /// 动画进度（0 到 1），控制折线沿日期轴从左到右逐步出现
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
    private var effectiveYDomain: ClosedRange<Double>? {
        if let yDomain = yDomain { return yDomain }
        let allValues = dataPoints.map(\.value) + referenceLines.map(\.value)
        guard let minVal = allValues.min(), let maxVal = allValues.max(), maxVal > 0 else { return nil }
        return min(minVal, 0)...maxVal
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
                // 数据系列（仅显示动画范围内的可见数据点）
                ForEach(visibleDataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(by: .value("Category", point.category))
                    .interpolationMethod(interpolationMethod)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    if showPointMarkers {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(by: .value("Category", point.category))
                        .symbolSize(30)
                    }
                }

                // 参考线（RuleMark），始终显示，不参与日期轴动画
                ForEach(Array(referenceLines.enumerated()), id: \.offset) { _, line in
                    RuleMark(y: .value("Reference", line.value))
                        .foregroundStyle(line.color)
                        .lineStyle(line.style)
                        .annotation(position: .top, alignment: .leading) {
                            if let label = line.label {
                                Text(label)
                                    .font(.caption2)
                                    .foregroundStyle(line.color)
                            }
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

extension SWLineChart where CategoryType == String {
    /// Convenience initializer (using String as category type)
    init(
        dataPoints: [DataPoint],
        colorMapping: [String: Color],
        referenceLines: [ReferenceLine] = [],
        interpolationMethod: InterpolationMethod = .linear,
        showPointMarkers: Bool = false,
        yDomain: ClosedRange<Double>? = nil,
        scrollableDaysBack: Int = 30,
        scrollableDaysForward: Int = 7,
        visibleDays: Int = 7,
        chartHeight: CGFloat = 200,
        title: String? = nil
    ) {
        self.dataPoints = dataPoints
        self.colorMapping = colorMapping
        self.referenceLines = referenceLines
        self.interpolationMethod = interpolationMethod
        self.showPointMarkers = showPointMarkers
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
            // Example 1: Basic multi-series line chart
            Group {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())

                let salesData: [SWLineChart<String>.DataPoint] = (0..<14).flatMap { dayOffset -> [SWLineChart<String>.DataPoint] in
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

            // Example 2: With reference line, catmullRom interpolation, and point markers
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

            Divider()

            // Example 3: Single series with stepped interpolation
            Group {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())

                let stepData: [SWLineChart<String>.DataPoint] = (0..<7).map { dayOffset in
                    let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                    return .init(date: date, value: Double(Int.random(in: 1...5)) * 1000, category: "Steps")
                }

                SWLineChart(
                    dataPoints: stepData,
                    colorMapping: ["Steps": .green],
                    interpolationMethod: .stepCenter,
                    visibleDays: 7,
                    chartHeight: 180,
                    title: "Daily Steps (Stepped)"
                )
            }
        }
        .padding()
    }
}
