//
//  slScatterChart.swift
//  ShipSwift
//
//  Created by Claude on 2026/1/23.
//  Copyright © 2026 Signer Labs. All rights reserved.
//
//  可滚动的散点图组件，支持多类型数据点、时间轴滚动、自定义样式
//  适用于一天内多次记录的场景（如扫描记录、运动数据等）
//

import SwiftUI
import Charts

// MARK: - slScatterChart

struct slScatterChart<CategoryType: Hashable & Plottable>: View {
    // MARK: - 内置数据模型

    /// 数据点模型
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

    /// 数据点数组
    let dataPoints: [DataPoint]

    /// 类型对应的颜色映射
    let colorMapping: [CategoryType: Color]

    /// Y 轴范围
    var yDomain: ClosedRange<Double> = 0...100

    /// X 轴可滚动总范围（天数，从今天往前）
    var scrollableDaysBack: Int = 30

    /// X 轴可滚动总范围（天数，从今天往后）
    var scrollableDaysForward: Int = 7

    /// 可见范围（天数）
    var visibleDays: Int = 7

    /// 图表高度
    var chartHeight: CGFloat = 180

    /// 标题（可选）
    var title: String? = nil

    // MARK: - Computed Properties

    /// X 轴可滚动的总范围
    private var chartXDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -scrollableDaysBack, to: startOfToday)!
        let endDate = calendar.date(byAdding: .day, value: scrollableDaysForward, to: startOfToday)!
        return startDate...endDate
    }

    /// 图表初始滚动位置：让今天在可见范围的中间
    private var chartInitialScrollDate: Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        // 可见范围 N 天，要让今天在中间，起始位置是 N/2 天前
        let offset = visibleDays / 2
        return calendar.date(byAdding: .day, value: -offset, to: startOfToday)!
    }

    /// 可见范围的时间长度（秒）
    private var visibleDomainLength: Int {
        visibleDays * 24 * 60 * 60
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            if let title = title {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            // 图表
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

extension slScatterChart where CategoryType == String {
    /// 便捷初始化器（使用 String 作为类型）
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

#Preview("Basic Scatter Chart") {
    // 示例数据：模拟牙齿和食物扫描记录
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    let sampleData: [slScatterChart<String>.DataPoint] = [
        // 今天的数据
        .init(date: calendar.date(byAdding: .hour, value: 8, to: today)!, value: 85, category: "Teeth"),
        .init(date: calendar.date(byAdding: .hour, value: 12, to: today)!, value: 52, category: "Food"),
        .init(date: calendar.date(byAdding: .hour, value: 18, to: today)!, value: 78, category: "Food"),
        // 昨天的数据
        .init(date: calendar.date(byAdding: .day, value: -1, to: today)!, value: 72, category: "Teeth"),
        .init(date: calendar.date(byAdding: .hour, value: -18, to: today)!, value: 65, category: "Food"),
        // 前天的数据
        .init(date: calendar.date(byAdding: .day, value: -2, to: today)!, value: 90, category: "Teeth"),
        // 3 天前
        .init(date: calendar.date(byAdding: .day, value: -3, to: today)!, value: 45, category: "Food"),
        .init(date: calendar.date(byAdding: .day, value: -3, to: today)!, value: 88, category: "Teeth"),
    ]

    let colorMapping: [String: Color] = [
        "Teeth": .blue,
        "Food": .orange
    ]

    slScatterChart(
        dataPoints: sampleData,
        colorMapping: colorMapping,
        title: "Scan Trends"
    )
    .padding()
}

#Preview("Custom Y Domain") {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    let temperatureData: [slScatterChart<String>.DataPoint] = [
        .init(date: calendar.date(byAdding: .hour, value: 6, to: today)!, value: 36.2, category: "Morning"),
        .init(date: calendar.date(byAdding: .hour, value: 12, to: today)!, value: 36.8, category: "Noon"),
        .init(date: calendar.date(byAdding: .hour, value: 20, to: today)!, value: 37.1, category: "Evening"),
        .init(date: calendar.date(byAdding: .day, value: -1, to: today)!, value: 36.5, category: "Morning"),
    ]

    let colorMapping: [String: Color] = [
        "Morning": .cyan,
        "Noon": .yellow,
        "Evening": .purple
    ]

    slScatterChart(
        dataPoints: temperatureData,
        colorMapping: colorMapping,
        yDomain: 35...40,
        visibleDays: 5,
        chartHeight: 200,
        title: "Body Temperature"
    )
    .padding()
}

#Preview("Empty State") {
    let colorMapping: [String: Color] = [
        "Type A": .blue,
        "Type B": .green
    ]

    slScatterChart<String>(
        dataPoints: [],
        colorMapping: colorMapping,
        title: "No Data Yet"
    )
    .padding()
}
