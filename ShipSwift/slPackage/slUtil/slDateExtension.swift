//
//  slDateExtension.swift
//  ShipSwift
//
//  日期格式化工具，自动支持中英文（读取 appLanguage）
//
//  使用示例:
//    date.formatMonthDay()    // "Jan 15" / "1月15日"
//    date.formatFullDate()    // "Jan 15, 2025" / "2025年1月15日"
//    date.timeAgo()           // "3 min ago" / "3分钟前"
//    date.isToday             // Bool
//    date.isSameDay(as: other)
//    date.adding(days: 7)
//
//  每日重置:
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

    /// 格式化为月份
    /// - Returns: `Jan` / `1月`
    func formatMonth() -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateFormat = isEnglish ? "MMM" : "M月"
        return formatter.string(from: self)
    }

    /// 格式化为日期
    /// - Returns: `15`
    func formatDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    /// 格式化为月日
    /// - Returns: `Jan 15` / `1月15日`
    func formatMonthDay() -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateFormat = isEnglish ? "MMM d" : "M月d日"
        return formatter.string(from: self)
    }

    /// 格式化为完整日期
    /// - Returns: `Jan 15, 2025` / `2025年1月15日`
    func formatFullDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateFormat = isEnglish ? "MMM d, yyyy" : "yyyy年M月d日"
        return formatter.string(from: self)
    }

    /// 格式化为时间
    /// - Returns: `14:30`
    func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    /// 格式化为日期和时间
    /// - Returns: `Jan 15, 14:30` / `1月15日 14:30`
    func formatDateTime() -> String {
        "\(formatMonthDay()) \(formatTime())"
    }

    // MARK: - Relative Time

    /// 相对时间描述
    /// - Returns: `Just now` / `3 min ago` / `2 hours ago` / `Yesterday` / `Jan 15`
    func timeAgo() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        // 未来时间
        if interval < 0 {
            return formatMonthDay()
        }

        // 1分钟内
        if interval < 60 {
            return isEnglish ? "Just now" : "刚刚"
        }

        // 1小时内
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return isEnglish ? "\(minutes) min ago" : "\(minutes)分钟前"
        }

        // 24小时内
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return isEnglish ? "\(hours) hour\(hours > 1 ? "s" : "") ago" : "\(hours)小时前"
        }

        // 昨天
        if Calendar.current.isDateInYesterday(self) {
            return isEnglish ? "Yesterday" : "昨天"
        }

        // 7天内
        if interval < 604800 {
            let days = Int(interval / 86400)
            return isEnglish ? "\(days) day\(days > 1 ? "s" : "") ago" : "\(days)天前"
        }

        // 超过7天显示日期
        return formatMonthDay()
    }

    // MARK: - Date Comparison

    /// 是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// 是否是昨天
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// 是否是明天
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// 是否与另一个日期是同一天
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// 获取当天开始时间 (00:00:00)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 获取当天结束时间 (23:59:59)
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
    }

    // MARK: - Date Arithmetic

    /// 添加天数
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// 添加月份
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// 添加年份
    func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }

    /// 两个日期之间的天数差
    func days(from other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: other.startOfDay, to: self.startOfDay).day ?? 0
    }
}

// MARK: - Daily Reset Helper

extension Date {
    /// 检查是否需要重置每日计数
    /// - Parameter key: UserDefaults 中存储日期的 key
    /// - Returns: 是否需要重置（跨天了）
    static func shouldResetDaily(dateKey: String) -> Bool {
        let today = Date().startOfDay
        let lastDate = UserDefaults.standard.object(forKey: dateKey) as? Date ?? .distantPast
        return !today.isSameDay(as: lastDate)
    }

    /// 更新每日重置日期
    /// - Parameter key: UserDefaults 中存储日期的 key
    static func updateDailyResetDate(dateKey: String) {
        UserDefaults.standard.set(Date().startOfDay, forKey: dateKey)
    }
}
