//
//  slStringExtension.swift
//  ShipSwift
//

import Foundation

extension String {
    /// 验证邮箱格式
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: emailRegex, options: .regularExpression) != nil
    }

    /// 验证手机号格式（8-15位数字，国际通用）
    var isValidPhone: Bool {
        let phoneRegex = #"^\d{8,15}$"#
        return range(of: phoneRegex, options: .regularExpression) != nil
    }
}
