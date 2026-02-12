//
//  SWStringExtension.swift
//  ShipSwift
//
//  String extension providing computed properties for email and phone number format validation.
//
//  Usage:
//    // Email validation — matches standard email format (user@domain.tld):
//    "hello@example.com".isValidEmail   // true
//    "not-an-email".isValidEmail        // false
//
//    // Phone number validation — digits only, 8-15 characters (supports international numbers):
//    "13800138000".isValidPhone         // true
//    "123".isValidPhone                 // false (fewer than 8 digits)
//    "+1-555-1234".isValidPhone         // false (contains non-digit characters)
//
//    // Common usage — validate before form submission:
//    Button("Submit") { submit() }
//        .disabled(!email.isValidEmail || !phone.isValidPhone)
//
//  Created by Wei Zhong on 3/1/26.
//

import Foundation

extension String {
    /// Validate email format
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: emailRegex, options: .regularExpression) != nil
    }

    /// Validate phone number format (8-15 digits, international)
    var isValidPhone: Bool {
        let phoneRegex = #"^\d{8,15}$"#
        return range(of: phoneRegex, options: .regularExpression) != nil
    }
}
