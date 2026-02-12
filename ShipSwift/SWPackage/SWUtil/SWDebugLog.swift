//
//  SWDebugLog.swift
//  ShipSwift
//
//  Debug logging utility with zero overhead in Release builds.
//
//  Usage:
//    swDebugLog("📊 Data loaded:", count)
//    swDebugLog("Processing complete")
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
