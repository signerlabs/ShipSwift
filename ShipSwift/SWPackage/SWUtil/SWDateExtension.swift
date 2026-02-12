//
//  SWDateExtension.swift
//  ShipSwift
//
//  Date formatting utility with automatic Chinese/English support (reads appLanguage).
//
//  Usage:
//    date.formatMonthDay()    // "Jan 15" / "1月15日"
//    date.formatFullDate()    // "Jan 15, 2025" / "2025年1月15日"
//    date.timeAgo()           // "3 min ago" / "3分钟前"
//    date.isToday             // Bool
//    date.isSameDay(as: other)
//    date.adding(days: 7)
//
//  Daily reset:
//    if Date.shouldResetDaily(dateKey: "lastDate") { ... }
//

import Foundation

// MARK: - App Language Helper

private var appLanguage: String {
    UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
}

private var isEnglish: Bool {
    appLanguage == "en"
}

private var currentLocale: Locale {
    Locale(identifier: appLanguage)
}

// MARK: - Date Formatting

extension Date {

    // MARK: - Basic Formatting

    /// Format as month
    /// - Returns: `Jan` / `1月`
    func formatMonth() -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateFormat = isEnglish ? "MMM" : "M月"
        return formatter.string(from: self)
    }

    /// Format as day
    /// - Returns: `15`
    func formatDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    /// Format as month and day
    /// - Returns: `Jan 15` / `1月15日`
    func formatMonthDay() -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateFormat = isEnglish ? "MMM d" : "M月d日"
        return formatter.string(from: self)
    }

    /// Format as full date
    /// - Returns: `Jan 15, 2025` / `2025年1月15日`
    func formatFullDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateFormat = isEnglish ? "MMM d, yyyy" : "yyyy年M月d日"
        return formatter.string(from: self)
    }

    /// Format as time
    /// - Returns: `14:30`
    func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    /// Format as date and time
    /// - Returns: `Jan 15, 14:30` / `1月15日 14:30`
    func formatDateTime() -> String {
        "\(formatMonthDay()) \(formatTime())"
    }

    // MARK: - Relative Time

    /// Relative time description
    /// - Returns: `Just now` / `3 min ago` / `2 hours ago` / `Yesterday` / `Jan 15`
    func timeAgo() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        // Future date
        if interval < 0 {
            return formatMonthDay()
        }

        // Within 1 minute
        if interval < 60 {
            return isEnglish ? "Just now" : "刚刚"
        }

        // Within 1 hour
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return isEnglish ? "\(minutes) min ago" : "\(minutes)分钟前"
        }

        // Within 24 hours
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return isEnglish ? "\(hours) hour\(hours > 1 ? "s" : "") ago" : "\(hours)小时前"
        }

        // Yesterday
        if Calendar.current.isDateInYesterday(self) {
            return isEnglish ? "Yesterday" : "昨天"
        }

        // Within 7 days
        if interval < 604800 {
            let days = Int(interval / 86400)
            return isEnglish ? "\(days) day\(days > 1 ? "s" : "") ago" : "\(days)天前"
        }

        // More than 7 days, show date
        return formatMonthDay()
    }

    // MARK: - Date Comparison

    /// Whether the date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Whether the date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Whether the date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Whether this date is the same day as another date
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Get the start of day (00:00:00)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Get the end of day (23:59:59)
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
    }

    // MARK: - Date Arithmetic

    /// Add days
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Add months
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Add years
    func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }

    /// Number of days between two dates
    func days(from other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: other.startOfDay, to: self.startOfDay).day ?? 0
    }
}

// MARK: - Daily Reset Helper

extension Date {
    /// Check whether the daily counter needs to be reset
    /// - Parameter key: The key used to store the date in UserDefaults
    /// - Returns: Whether a reset is needed (day has changed)
    static func shouldResetDaily(dateKey: String) -> Bool {
        let today = Date().startOfDay
        let lastDate = UserDefaults.standard.object(forKey: dateKey) as? Date ?? .distantPast
        return !today.isSameDay(as: lastDate)
    }

    /// Update the daily reset date
    /// - Parameter key: The key used to store the date in UserDefaults
    static func updateDailyResetDate(dateKey: String) {
        UserDefaults.standard.set(Date().startOfDay, forKey: dateKey)
    }
}
