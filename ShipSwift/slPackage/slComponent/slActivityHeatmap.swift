//
//  slActivityHeatmap.swift
//  ShipSwift
//
//  活动热力图组件 - 展示连续打卡天数和过去 N 天的活动记录
//  使用场景：习惯追踪、打卡应用、记录应用等
//
//  使用示例：
//  ```swift
//  // 在 List 中使用
//  Form {
//      // Streaks 卡片
//      slActivityHeatmap.StreakCard(
//          streaks: timestamps,
//          currentStreakTitle: "Current Streak",
//          dayText: "Day",
//          daysText: "Days",
//          noRecordsText: "No records yet. Start today!",
//          colors: [.blue, .purple]
//      )
//
//      // 热力图
//      Section {
//          slActivityHeatmap.HeatmapGrid(
//              timestamps: timestamps,
//              days: 60,
//              baseColor: .green,
//              itemSize: 20,
//              spacing: 3
//          )
//      } header: {
//          Text("Past 60 days")
//      } footer: {
//          slActivityHeatmap.HeatmapLegend(
//              baseColor: .green,
//              lessText: "Less",
//              moreText: "More"
//          )
//      }
//  }
//  ```
//
//  Created by Claude on 2026/1/26.
//

import SwiftUI

/// 活动热力图组件集合
enum slActivityHeatmap {

    // MARK: - Streak Info

    /// 连续打卡信息
    struct StreakInfo {
        /// 当前连续天数
        let currentStreak: Int
        /// 开始日期
        let startDate: Date?

        /// 生成描述文本
        func displayText(
            noRecordsText: String = "No records yet. Start today!",
            startedTodayText: String = "Started today. Keep it up!",
            recordedYesterdayText: String = "You recorded yesterday. Continue today to keep the streak!"
        ) -> String {
            guard currentStreak > 0 else {
                return noRecordsText
            }

            if currentStreak == 1 {
                let calendar = Calendar.current
                if let startDate = startDate, calendar.isDateInToday(startDate) {
                    return startedTodayText
                } else {
                    return recordedYesterdayText
                }
            }

            guard let startDate = startDate else {
                return "Current streak started \(currentStreak) days ago."
            }

            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0

            if days == 0 {
                return "Current streak started today."
            } else if days == 1 {
                return "Current streak started yesterday."
            } else if days < 7 {
                return "Current streak started \(days) days ago."
            } else if days < 30 {
                let weeks = days / 7
                return "Current streak started \(weeks) week\(weeks == 1 ? "" : "s") ago."
            } else {
                let months = days / 30
                return "Current streak started \(months) month\(months == 1 ? "" : "s") ago."
            }
        }
    }

    // MARK: - Streak Calculation

    /// 计算连续打卡天数
    /// - Parameter timestamps: 时间戳数组
    /// - Returns: 打卡信息
    static func calculateStreak(from timestamps: [Date]) -> StreakInfo {
        guard !timestamps.isEmpty else {
            return StreakInfo(currentStreak: 0, startDate: nil)
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 按日期分组
        var recordsByDay: Set<Date> = []
        for timestamp in timestamps {
            let day = calendar.startOfDay(for: timestamp)
            recordsByDay.insert(day)
        }

        // 按降序排序（最近的在前）
        let sortedDays = recordsByDay.sorted(by: >)

        // 过滤未来日期
        let validDays = sortedDays.filter { $0 <= today }

        guard let mostRecentDay = validDays.first else {
            return StreakInfo(currentStreak: 0, startDate: nil)
        }

        let daysSinceMostRecent = calendar.dateComponents([.day], from: mostRecentDay, to: today).day ?? 0

        // 如果最近一次记录超过 1 天前，打卡中断
        if daysSinceMostRecent > 1 {
            return StreakInfo(currentStreak: 0, startDate: nil)
        }

        // 计算连续天数
        var currentStreak = 1
        var streakStartDate = mostRecentDay
        var expectedDate = calendar.date(byAdding: .day, value: -1, to: mostRecentDay)!

        for day in validDays.dropFirst() {
            let dayDifference = calendar.dateComponents([.day], from: expectedDate, to: day).day ?? 999

            if dayDifference == 0 {
                currentStreak += 1
                streakStartDate = day
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else {
                break
            }
        }

        return StreakInfo(currentStreak: currentStreak, startDate: streakStartDate)
    }

    // MARK: - Streak Card

    /// 连续打卡展示卡片
    struct StreakCard: View {
        let streaks: [Date]
        let currentStreakTitle: String
        let dayText: String
        let daysText: String
        let noRecordsText: String
        let startedTodayText: String
        let recordedYesterdayText: String
        let colors: [Color]

        private var streakInfo: StreakInfo {
            calculateStreak(from: streaks)
        }

        /// 创建连续打卡卡片
        /// - Parameters:
        ///   - streaks: 时间戳数组
        ///   - currentStreakTitle: 标题文本
        ///   - dayText: 单数天文本
        ///   - daysText: 复数天文本
        ///   - noRecordsText: 无记录文本
        ///   - startedTodayText: 今天开始文本
        ///   - recordedYesterdayText: 昨天记录文本
        ///   - colors: 渐变颜色数组
        init(
            streaks: [Date],
            currentStreakTitle: String = "Current Streak",
            dayText: String = "Day",
            daysText: String = "Days",
            noRecordsText: String = "No records yet. Start today!",
            startedTodayText: String = "Started today. Keep it up!",
            recordedYesterdayText: String = "You recorded yesterday. Continue today!",
            colors: [Color] = [.blue, .purple]
        ) {
            self.streaks = streaks
            self.currentStreakTitle = currentStreakTitle
            self.dayText = dayText
            self.daysText = daysText
            self.noRecordsText = noRecordsText
            self.startedTodayText = startedTodayText
            self.recordedYesterdayText = recordedYesterdayText
            self.colors = colors
        }

        var body: some View {
            HStack {
                Spacer()
                VStack {
                    Text(currentStreakTitle)
                        .font(.headline)
                        .foregroundStyle(.regularMaterial)

                    VStack(spacing: -10) {
                        Text("\(streakInfo.currentStreak)")
                            .fontWeight(.bold)
                            .font(.system(size: 80))
                        Text(streakInfo.currentStreak == 1 ? dayText : daysText)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)

                    Text(streakInfo.displayText(
                        noRecordsText: noRecordsText,
                        startedTodayText: startedTodayText,
                        recordedYesterdayText: recordedYesterdayText
                    ))
                    .font(.footnote)
                    .foregroundStyle(.regularMaterial)
                    .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding(.vertical)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    // MARK: - Heatmap Grid

    /// 活动热力图网格
    struct HeatmapGrid: View {
        let timestamps: [Date]
        let days: Int
        let baseColor: Color
        let itemSize: CGFloat
        let spacing: CGFloat

        private let calendar = Calendar.current

        private var recordCountByDay: [Date: Int] {
            var counts: [Date: Int] = [:]

            for timestamp in timestamps {
                let day = calendar.startOfDay(for: timestamp)
                counts[day, default: 0] += 1
            }

            return counts
        }

        private var targetDays: [Date] {
            let today = calendar.startOfDay(for: Date())
            var daysList: [Date] = []

            for i in stride(from: days - 1, through: 0, by: -1) {
                if let day = calendar.date(byAdding: .day, value: -i, to: today) {
                    daysList.append(day)
                }
            }

            return daysList
        }

        private func colorForRecordCount(_ count: Int) -> Color {
            switch count {
            case 0:
                return baseColor.opacity(0.2)
            case 1:
                return baseColor.opacity(0.4)
            case 2:
                return baseColor.opacity(0.7)
            default:
                return baseColor
            }
        }

        /// 创建活动热力图网格
        /// - Parameters:
        ///   - timestamps: 时间戳数组
        ///   - days: 显示的天数，默认 60
        ///   - baseColor: 基础颜色，默认绿色
        ///   - itemSize: 单个方块大小，默认 20
        ///   - spacing: 方块间距，默认 3
        init(
            timestamps: [Date],
            days: Int = 60,
            baseColor: Color = .green,
            itemSize: CGFloat = 20,
            spacing: CGFloat = 3
        ) {
            self.timestamps = timestamps
            self.days = days
            self.baseColor = baseColor
            self.itemSize = itemSize
            self.spacing = spacing
        }

        var body: some View {
            HStack {
                Spacer()
                FlowLayout(spacing: spacing) {
                    ForEach(targetDays, id: \.self) { date in
                        let count = recordCountByDay[date] ?? 0

                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForRecordCount(count))
                            .frame(width: itemSize, height: itemSize)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Heatmap Legend

    /// 热力图图例
    struct HeatmapLegend: View {
        let baseColor: Color
        let lessText: String
        let moreText: String

        /// 创建热力图图例
        /// - Parameters:
        ///   - baseColor: 基础颜色
        ///   - lessText: "少"的文本
        ///   - moreText: "多"的文本
        init(
            baseColor: Color = .green,
            lessText: String = "Less",
            moreText: String = "More"
        ) {
            self.baseColor = baseColor
            self.lessText = lessText
            self.moreText = moreText
        }

        var body: some View {
            HStack {
                Spacer()

                Text(lessText)

                HStack(spacing: 3) {
                    Group {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(baseColor.opacity(0.2))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(baseColor.opacity(0.4))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(baseColor.opacity(0.7))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(baseColor)
                    }
                    .frame(width: 12, height: 12)
                }

                Text(moreText)
            }
        }
    }

    // MARK: - Flow Layout

    /// 自定义流式布局，水平排列并自动换行
    struct FlowLayout: Layout {
        let spacing: CGFloat

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let result = FlowResult(
                in: proposal.width ?? .infinity,
                subviews: subviews,
                spacing: spacing
            )
            return result.size
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let result = FlowResult(
                in: bounds.width,
                subviews: subviews,
                spacing: spacing
            )

            for (index, subview) in subviews.enumerated() {
                subview.place(
                    at: CGPoint(
                        x: bounds.minX + result.positions[index].x,
                        y: bounds.minY + result.positions[index].y
                    ),
                    proposal: ProposedViewSize(result.sizes[index])
                )
            }
        }

        struct FlowResult {
            let size: CGSize
            let positions: [CGPoint]
            let sizes: [CGSize]

            init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
                var positions: [CGPoint] = []
                var sizes: [CGSize] = []

                var x: CGFloat = 0
                var y: CGFloat = 0
                var lineHeight: CGFloat = 0
                var maxX: CGFloat = 0

                for subview in subviews {
                    let size = subview.sizeThatFits(.unspecified)
                    sizes.append(size)

                    if x + size.width > maxWidth && x > 0 {
                        x = 0
                        y += lineHeight + spacing
                        lineHeight = 0
                    }

                    positions.append(CGPoint(x: x, y: y))
                    lineHeight = max(lineHeight, size.height)
                    x += size.width + spacing
                    maxX = max(maxX, x - spacing)
                }

                self.size = CGSize(width: maxX, height: y + lineHeight)
                self.positions = positions
                self.sizes = sizes
            }
        }
    }
}

// MARK: - Preview

#Preview("完整示例") {
    // 模拟数据：过去 60 天随机打卡
    let timestamps: [Date] = {
        var dates: [Date] = []
        let calendar = Calendar.current
        let today = Date()

        for i in 0..<60 {
            // 70% 概率有记录
            if Int.random(in: 0...100) < 70 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    // 每天可能有 1-3 条记录
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
            // Streaks 卡片
            Section {
                slActivityHeatmap.StreakCard(
                    streaks: timestamps,
                    colors: [.blue, .purple]
                )
            }
            .listRowInsets(EdgeInsets())

            // 热力图
            Section {
                slActivityHeatmap.HeatmapGrid(
                    timestamps: timestamps,
                    days: 60,
                    baseColor: .green
                )
            } header: {
                Text("Past 60 days")
            } footer: {
                slActivityHeatmap.HeatmapLegend(
                    baseColor: .green
                )
            }
        }
        .navigationTitle("Activity")
    }
}

#Preview("空数据") {
    NavigationStack {
        Form {
            Section {
                slActivityHeatmap.StreakCard(
                    streaks: [],
                    colors: [.orange, .red]
                )
            }
            .listRowInsets(EdgeInsets())

            Section {
                slActivityHeatmap.HeatmapGrid(
                    timestamps: [],
                    baseColor: .blue
                )
            } header: {
                Text("Past 60 days")
            } footer: {
                slActivityHeatmap.HeatmapLegend(
                    baseColor: .blue
                )
            }
        }
        .navigationTitle("Activity")
    }
}
