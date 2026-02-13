//
//  SWScatterChart.swift
//  ShipSwift
//
//  Horizontally scrollable scatter chart built on Swift Charts. Supports generic
//  category types (must conform to Hashable & Plottable) with color mapping.
//  Includes a convenience initializer for String categories.
//
//  Usage:
//    // Convenience initializer with String categories
//    let sampleData: [SWScatterChart<String>.DataPoint] = [
//        .init(date: Date(), value: 85, category: "Teeth"),
//        .init(date: Date(), value: 52, category: "Food"),
//    ]
//
//    let colorMapping: [String: Color] = [
//        "Teeth": .blue,
//        "Food": .orange
//    ]
//
//    SWScatterChart(
//        dataPoints: sampleData,
//        colorMapping: colorMapping,
//        title: "Scan Trends"
//    )
//    .padding()
//
//    // Custom Y-axis range and visible days
//    SWScatterChart(
//        dataPoints: temperatureData,
//        colorMapping: tempColorMapping,
//        yDomain: 35...40,
//        visibleDays: 5,
//        chartHeight: 200,
//        title: "Body Temperature"
//    )
//
//  Data Model (built-in):
//    SWScatterChart<CategoryType>.DataPoint
//      - date: Date
//      - value: Double
//      - category: CategoryType
//
//  Parameters:
//    - dataPoints: [DataPoint]              — Array of data points
//    - colorMapping: [CategoryType: Color]  — Category to color mapping
//    - yDomain: ClosedRange<Double>         — Y-axis range (default 0...100)
//    - scrollableDaysBack: Int              — Scrollable days backward (default 30)
//    - scrollableDaysForward: Int           — Scrollable days forward (default 7)
//    - visibleDays: Int                     — Visible days range (default 7)
//    - chartHeight: CGFloat                 — Chart height (default 180)
//    - title: String?                       — Optional title
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI
import Charts

// MARK: - SWScatterChart

struct SWScatterChart<CategoryType: Hashable & Plottable>: View {
    // MARK: - Built-in Data Model

    /// Data point model
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

    /// Y-axis range
    var yDomain: ClosedRange<Double> = 0...100

    /// X-axis scrollable total range (days back from today)
    var scrollableDaysBack: Int = 30

    /// X-axis scrollable total range (days forward from today)
    var scrollableDaysForward: Int = 7

    /// Visible range (days)
    var visibleDays: Int = 7

    /// Chart height
    var chartHeight: CGFloat = 180

    /// Title (optional)
    var title: String? = nil

    // MARK: - Computed Properties

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
        // Visible range is N days; to center today, start N/2 days back
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

            // Chart
            Chart(dataPoints) { point in
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Category", point.category))
            }
            .chartForegroundStyleScale(
                domain: Array(colorMapping.keys),
                range: Array(colorMapping.values)
            )
            .chartXScale(domain: chartXDomain)
            .chartYScale(domain: yDomain)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: visibleDomainLength)
            .chartScrollPosition(initialX: chartInitialScrollDate)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartLegend(position: .top, alignment: .trailing)
            .frame(height: chartHeight)
        }
    }
}

// MARK: - Convenience Initializer for String Category

extension SWScatterChart where CategoryType == String {
    /// Convenience initializer (using String as category type)
    init(
        dataPoints: [DataPoint],
        colorMapping: [String: Color],
        yDomain: ClosedRange<Double> = 0...100,
        scrollableDaysBack: Int = 30,
        scrollableDaysForward: Int = 7,
        visibleDays: Int = 7,
        chartHeight: CGFloat = 180,
        title: String? = nil
    ) {
        self.dataPoints = dataPoints
        self.colorMapping = colorMapping
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
            // Example 1: Basic scatter chart
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

            // Example 2: Custom Y domain
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

            Divider()

            // Example 3: Empty state
            SWScatterChart<String>(
                dataPoints: [],
                colorMapping: ["Type A": .blue, "Type B": .green],
                title: "No Data Yet"
            )
        }
        .padding()
    }
}
