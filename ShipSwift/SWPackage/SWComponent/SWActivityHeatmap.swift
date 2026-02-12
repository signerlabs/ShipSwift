//
//  SWActivityHeatmap.swift
//  ShipSwift
//
//  GitHub-style activity heatmap with streak tracking. Contains three sub-components
//  under the SWActivityHeatmap enum: StreakCard, HeatmapGrid, and HeatmapLegend.
//  Also provides a static calculateStreak(from:) method and StreakInfo model.
//
//  Usage:
//    // 1. Prepare timestamp data
//    let timestamps: [Date] = [Date(), /* ... historical check-in dates ... */]
//
//    // 2. Combine three sub-components in a Form/List
//    Form {
//        // Consecutive check-in days card
//        Section {
//            SWActivityHeatmap.StreakCard(
//                streaks: timestamps,
//                currentStreakTitle: "Current Streak",
//                colors: [.blue, .purple]
//            )
//        }
//        .listRowInsets(EdgeInsets())
//
//        // Heatmap grid
//        Section {
//            SWActivityHeatmap.HeatmapGrid(
//                timestamps: timestamps,
//                days: 60,
//                baseColor: .green,
//                itemSize: 20,
//                spacing: 3
//            )
//        } header: {
//            Text("Past 60 days")
//        } footer: {
//            // Legend
//            SWActivityHeatmap.HeatmapLegend(
//                baseColor: .green,
//                lessText: "Less",
//                moreText: "More"
//            )
//        }
//    }
//
//    // 3. Calculate streak independently
//    let info = SWActivityHeatmap.calculateStreak(from: timestamps)
//    print(info.currentStreak)    // Consecutive days
//    print(info.displayText())    // Description text
//
//  Sub-components:
//    - StreakCard    — Gradient background streak display card
//    - HeatmapGrid  — Flow-layout activity heatmap grid
//    - HeatmapLegend — Less/More color legend
//    - StreakInfo    — Streak info model (currentStreak, startDate, displayText())
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

/// Activity heatmap component collection
enum SWActivityHeatmap {

    // MARK: - Streak Info

    /// Consecutive streak information
    struct StreakInfo {
        /// Current consecutive days
        let currentStreak: Int
        /// Start date
        let startDate: Date?

        /// Generate description text
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

    /// Calculate consecutive streak days
    /// - Parameter timestamps: Array of timestamps
    /// - Returns: Streak information
    static func calculateStreak(from timestamps: [Date]) -> StreakInfo {
        guard !timestamps.isEmpty else {
            return StreakInfo(currentStreak: 0, startDate: nil)
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Group by date
        var recordsByDay: Set<Date> = []
        for timestamp in timestamps {
            let day = calendar.startOfDay(for: timestamp)
            recordsByDay.insert(day)
        }

        // Sort in descending order (most recent first)
        let sortedDays = recordsByDay.sorted(by: >)

        // Filter out future dates
        let validDays = sortedDays.filter { $0 <= today }

        guard let mostRecentDay = validDays.first else {
            return StreakInfo(currentStreak: 0, startDate: nil)
        }

        let daysSinceMostRecent = calendar.dateComponents([.day], from: mostRecentDay, to: today).day ?? 0

        // If the most recent record is more than 1 day ago, the streak is broken
        if daysSinceMostRecent > 1 {
            return StreakInfo(currentStreak: 0, startDate: nil)
        }

        // Calculate consecutive days
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

    /// Consecutive streak display card
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

        /// Create a streak card
        /// - Parameters:
        ///   - streaks: Array of timestamps
        ///   - currentStreakTitle: Title text
        ///   - dayText: Singular day text
        ///   - daysText: Plural days text
        ///   - noRecordsText: No records text
        ///   - startedTodayText: Started today text
        ///   - recordedYesterdayText: Recorded yesterday text
        ///   - colors: Gradient color array
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

    /// Activity heatmap grid
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

        /// Create an activity heatmap grid
        /// - Parameters:
        ///   - timestamps: Array of timestamps
        ///   - days: Number of days to display, default 60
        ///   - baseColor: Base color, default green
        ///   - itemSize: Individual block size, default 20
        ///   - spacing: Block spacing, default 3
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

    /// Heatmap legend
    struct HeatmapLegend: View {
        let baseColor: Color
        let lessText: String
        let moreText: String

        /// Create a heatmap legend
        /// - Parameters:
        ///   - baseColor: Base color
        ///   - lessText: "Less" text label
        ///   - moreText: "More" text label
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

    /// Custom flow layout that arranges items horizontally with automatic line wrapping
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

#Preview("Full Example") {
    // Sample data: random check-ins over the past 60 days
    let timestamps: [Date] = {
        var dates: [Date] = []
        let calendar = Calendar.current
        let today = Date()

        for i in 0..<60 {
            // 70% chance of having a record
            if Int.random(in: 0...100) < 70 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    // Each day may have 1-3 records
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
            // Streak card
            Section {
                SWActivityHeatmap.StreakCard(
                    streaks: timestamps,
                    colors: [.blue, .purple]
                )
            }
            .listRowInsets(EdgeInsets())

            // Heatmap
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
}

#Preview("Empty Data") {
    NavigationStack {
        Form {
            Section {
                SWActivityHeatmap.StreakCard(
                    streaks: [],
                    colors: [.orange, .red]
                )
            }
            .listRowInsets(EdgeInsets())

            Section {
                SWActivityHeatmap.HeatmapGrid(
                    timestamps: [],
                    baseColor: .blue
                )
            } header: {
                Text("Past 60 days")
            } footer: {
                SWActivityHeatmap.HeatmapLegend(
                    baseColor: .blue
                )
            }
        }
        .navigationTitle("Activity")
    }
}
