//
//  SWStringExtension.swift
//  ShipSwift
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
