//
//  slDebugLog.swift
//  ShipSwift
//
//  Best Practice: Debug Logging Utility
//  Zero-overhead debug logging that is completely removed in Release builds.
//
//  Usage:
//    debugLog("📊 Data loaded:", count)           // Simple logging
//    debugLog("Processing complete")              // With file:line info
//
//  Created by Claude on 2025/1/9.
//

import Foundation

// MARK: - Debug Logging

/// Debug 模式下打印日志，Release 模式下完全移除（零开销）
/// - Parameters:
///   - items: 要打印的内容
///   - separator: 分隔符，默认空格
///   - terminator: 结束符，默认换行
///
/// Example:
/// ```swift
/// debugLog("📊", "Count:", items.count)  // Output: 📊 Count: 10
/// ```
@inline(__always)
func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    print(output, terminator: terminator)
    #endif
}

/// Debug 模式下打印日志（带文件和行号信息）
/// - Parameters:
///   - message: 日志消息
///   - file: 文件名（自动填充）
///   - line: 行号（自动填充）
///
/// Example:
/// ```swift
/// debugLog("Loading complete")  // Output: [ViewModel.swift:42] Loading complete
/// ```
@inline(__always)
func debugLog(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
    #if DEBUG
    let filename = (file as NSString).lastPathComponent
    print("[\(filename):\(line)] \(message())")
    #endif
}
