//
//  SWDebugLog.swift
//  ShipSwift
//
//  Debug logging utility functions that only print in DEBUG mode, with zero overhead
//  in Release builds (#if DEBUG + @inline(__always)). Provides two overloads:
//  simple print and print with file name/line number.
//
//  Usage:
//    // Overload 1 — multi-argument print (similar to print, supports custom separator and terminator):
//    swDebugLog("UserID:", userId, "Status:", status)
//    swDebugLog("A", "B", "C", separator: "-")
//    // Output: A-B-C
//
//    // Overload 2 — print with file name and line number (automatically captures call site):
//    swDebugLog("Network request failed")
//    // Output: [ViewModel.swift:42] Network request failed
//
//    // In Release mode, all swDebugLog calls are completely removed by the compiler with no performance impact.
//
//  Created by Wei Zhong on 3/1/26.
//

import Foundation

// MARK: - Debug Logging

/// Prints log messages in Debug mode, completely removed in Release (zero overhead)
@inline(__always)
nonisolated func swDebugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    print(output, terminator: terminator)
    #endif
}

/// Prints log messages with file and line info in Debug mode
@inline(__always)
nonisolated func swDebugLog(_ message: @autoclosure () -> String, file: String = #file, line: Int = #line) {
    #if DEBUG
    let filename = (file as NSString).lastPathComponent
    print("[\(filename):\(line)] \(message())")
    #endif
}
