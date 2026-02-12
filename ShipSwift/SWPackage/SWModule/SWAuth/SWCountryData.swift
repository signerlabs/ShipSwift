//
//  SWCountryData.swift
//  ShipSwift
//
//  Phone country code and flag data for international auth.
//  Provides the SWCountry model and a static list of 200+ countries with
//  dial codes, flag emojis, names, and phone number length ranges.
//
//  Usage:
//    // 1. Access the full country list
//    let countries = SWCountryData.allCountries  // [SWCountry]
//
//    // 2. Each SWCountry has: code, flag, name, phoneLength
//    let us = SWCountryData.allCountries.first { $0.name == "United States" }
//    // us?.code == "+1", us?.flag == "...", us?.phoneLength == 10...10
//
//    // 3. Look up flag emoji by phone code
//    let flag = SWCountryData.flag(for: "+86")    // returns China flag
//
//    // 4. Get valid phone number length range by country code
//    let range = SWCountryData.phoneLength(for: "+44")  // 10...10 (UK)
//
//    // 5. Use in a country picker
//    ForEach(SWCountryData.allCountries, id: \.code) { country in
//        Text("\(country.flag) \(country.name) (\(country.code))")
//    }
//
//  Created by Wei Zhong on 3/1/26.
//

import Foundation

struct SWCountry {
    let code: String
    let flag: String
    let name: String
    let phoneLength: ClosedRange<Int>
}

struct SWCountryData {
    /// Look up country flag by phone code
    static func flag(for code: String) -> String {
        allCountries.first { $0.code == code }?.flag ?? "🌍"
    }

    /// Get phone number length range by country code
    static func phoneLength(for code: String) -> ClosedRange<Int> {
        allCountries.first { $0.code == code }?.phoneLength ?? 8...12
    }

    static let allCountries: [SWCountry] = [
        // A
        SWCountry(code: "+93", flag: "🇦🇫", name: "Afghanistan", phoneLength: 9...9),
        SWCountry(code: "+355", flag: "🇦🇱", name: "Albania", phoneLength: 9...9),
        SWCountry(code: "+213", flag: "🇩🇿", name: "Algeria", phoneLength: 9...9),
        SWCountry(code: "+1", flag: "🇦🇸", name: "American Samoa", phoneLength: 10...10),
        SWCountry(code: "+376", flag: "🇦🇩", name: "Andorra", phoneLength: 6...9),
        SWCountry(code: "+244", flag: "🇦🇴", name: "Angola", phoneLength: 9...9),
        SWCountry(code: "+1", flag: "🇦🇮", name: "Anguilla", phoneLength: 10...10),
        SWCountry(code: "+1", flag: "🇦🇬", name: "Antigua and Barbuda", phoneLength: 10...10),
        SWCountry(code: "+54", flag: "🇦🇷", name: "Argentina", phoneLength: 10...10),
        SWCountry(code: "+374", flag: "🇦🇲", name: "Armenia", phoneLength: 8...8),
        SWCountry(code: "+297", flag: "🇦🇼", name: "Aruba", phoneLength: 7...7),
        SWCountry(code: "+61", flag: "🇦🇺", name: "Australia", phoneLength: 9...9),
        SWCountry(code: "+43", flag: "🇦🇹", name: "Austria", phoneLength: 10...11),
        SWCountry(code: "+994", flag: "🇦🇿", name: "Azerbaijan", phoneLength: 9...9),

        // B
        SWCountry(code: "+1", flag: "🇧🇸", name: "Bahamas", phoneLength: 10...10),
        SWCountry(code: "+973", flag: "🇧🇭", name: "Bahrain", phoneLength: 8...8),
        SWCountry(code: "+880", flag: "🇧🇩", name: "Bangladesh", phoneLength: 10...10),
        SWCountry(code: "+1", flag: "🇧🇧", name: "Barbados", phoneLength: 10...10),
        SWCountry(code: "+375", flag: "🇧🇾", name: "Belarus", phoneLength: 9...9),
        SWCountry(code: "+32", flag: "🇧🇪", name: "Belgium", phoneLength: 9...9),
        SWCountry(code: "+501", flag: "🇧🇿", name: "Belize", phoneLength: 7...7),
        SWCountry(code: "+229", flag: "🇧🇯", name: "Benin", phoneLength: 8...8),
        SWCountry(code: "+1", flag: "🇧🇲", name: "Bermuda", phoneLength: 10...10),
        SWCountry(code: "+975", flag: "🇧🇹", name: "Bhutan", phoneLength: 8...8),
        SWCountry(code: "+591", flag: "🇧🇴", name: "Bolivia", phoneLength: 8...8),
        SWCountry(code: "+387", flag: "🇧🇦", name: "Bosnia and Herzegovina", phoneLength: 8...9),
        SWCountry(code: "+267", flag: "🇧🇼", name: "Botswana", phoneLength: 8...8),
        SWCountry(code: "+55", flag: "🇧🇷", name: "Brazil", phoneLength: 10...11),
        SWCountry(code: "+1", flag: "🇻🇬", name: "British Virgin Islands", phoneLength: 10...10),
        SWCountry(code: "+673", flag: "🇧🇳", name: "Brunei", phoneLength: 7...7),
        SWCountry(code: "+359", flag: "🇧🇬", name: "Bulgaria", phoneLength: 9...9),
        SWCountry(code: "+226", flag: "🇧🇫", name: "Burkina Faso", phoneLength: 8...8),
        SWCountry(code: "+257", flag: "🇧🇮", name: "Burundi", phoneLength: 8...8),

        // C
        SWCountry(code: "+855", flag: "🇰🇭", name: "Cambodia", phoneLength: 8...9),
        SWCountry(code: "+237", flag: "🇨🇲", name: "Cameroon", phoneLength: 9...9),
        SWCountry(code: "+1", flag: "🇨🇦", name: "Canada", phoneLength: 10...10),
        SWCountry(code: "+238", flag: "🇨🇻", name: "Cape Verde", phoneLength: 7...7),
        SWCountry(code: "+1", flag: "🇰🇾", name: "Cayman Islands", phoneLength: 10...10),
        SWCountry(code: "+236", flag: "🇨🇫", name: "Central African Republic", phoneLength: 8...8),
        SWCountry(code: "+235", flag: "🇹🇩", name: "Chad", phoneLength: 8...8),
        SWCountry(code: "+56", flag: "🇨🇱", name: "Chile", phoneLength: 9...9),
        SWCountry(code: "+86", flag: "🇨🇳", name: "China", phoneLength: 11...11),
        SWCountry(code: "+57", flag: "🇨🇴", name: "Colombia", phoneLength: 10...10),
        SWCountry(code: "+269", flag: "🇰🇲", name: "Comoros", phoneLength: 7...7),
        SWCountry(code: "+242", flag: "🇨🇬", name: "Congo", phoneLength: 9...9),
        SWCountry(code: "+243", flag: "🇨🇩", name: "Congo (DRC)", phoneLength: 9...9),
        SWCountry(code: "+682", flag: "🇨🇰", name: "Cook Islands", phoneLength: 5...5),
        SWCountry(code: "+506", flag: "🇨🇷", name: "Costa Rica", phoneLength: 8...8),
        SWCountry(code: "+225", flag: "🇨🇮", name: "Côte d'Ivoire", phoneLength: 10...10),
        SWCountry(code: "+385", flag: "🇭🇷", name: "Croatia", phoneLength: 9...9),
        SWCountry(code: "+53", flag: "🇨🇺", name: "Cuba", phoneLength: 8...8),
        SWCountry(code: "+357", flag: "🇨🇾", name: "Cyprus", phoneLength: 8...8),
        SWCountry(code: "+420", flag: "🇨🇿", name: "Czech Republic", phoneLength: 9...9),

        // D
        SWCountry(code: "+45", flag: "🇩🇰", name: "Denmark", phoneLength: 8...8),
        SWCountry(code: "+253", flag: "🇩🇯", name: "Djibouti", phoneLength: 8...8),
        SWCountry(code: "+1", flag: "🇩🇲", name: "Dominica", phoneLength: 10...10),
        SWCountry(code: "+1", flag: "🇩🇴", name: "Dominican Republic", phoneLength: 10...10),

        // E
        SWCountry(code: "+593", flag: "🇪🇨", name: "Ecuador", phoneLength: 9...9),
        SWCountry(code: "+20", flag: "🇪🇬", name: "Egypt", phoneLength: 10...10),
        SWCountry(code: "+503", flag: "🇸🇻", name: "El Salvador", phoneLength: 8...8),
        SWCountry(code: "+240", flag: "🇬🇶", name: "Equatorial Guinea", phoneLength: 9...9),
        SWCountry(code: "+291", flag: "🇪🇷", name: "Eritrea", phoneLength: 7...7),
        SWCountry(code: "+372", flag: "🇪🇪", name: "Estonia", phoneLength: 7...8),
        SWCountry(code: "+251", flag: "🇪🇹", name: "Ethiopia", phoneLength: 9...9),

        // F
        SWCountry(code: "+500", flag: "🇫🇰", name: "Falkland Islands", phoneLength: 5...5),
        SWCountry(code: "+298", flag: "🇫🇴", name: "Faroe Islands", phoneLength: 6...6),
        SWCountry(code: "+679", flag: "🇫🇯", name: "Fiji", phoneLength: 7...7),
        SWCountry(code: "+358", flag: "🇫🇮", name: "Finland", phoneLength: 9...10),
        SWCountry(code: "+33", flag: "🇫🇷", name: "France", phoneLength: 9...9),
        SWCountry(code: "+594", flag: "🇬🇫", name: "French Guiana", phoneLength: 9...9),
        SWCountry(code: "+689", flag: "🇵🇫", name: "French Polynesia", phoneLength: 8...8),

        // G
        SWCountry(code: "+241", flag: "🇬🇦", name: "Gabon", phoneLength: 7...8),
        SWCountry(code: "+220", flag: "🇬🇲", name: "Gambia", phoneLength: 7...7),
        SWCountry(code: "+995", flag: "🇬🇪", name: "Georgia", phoneLength: 9...9),
        SWCountry(code: "+49", flag: "🇩🇪", name: "Germany", phoneLength: 10...11),
        SWCountry(code: "+233", flag: "🇬🇭", name: "Ghana", phoneLength: 9...9),
        SWCountry(code: "+350", flag: "🇬🇮", name: "Gibraltar", phoneLength: 8...8),
        SWCountry(code: "+30", flag: "🇬🇷", name: "Greece", phoneLength: 10...10),
        SWCountry(code: "+299", flag: "🇬🇱", name: "Greenland", phoneLength: 6...6),
        SWCountry(code: "+1", flag: "🇬🇩", name: "Grenada", phoneLength: 10...10),
        SWCountry(code: "+590", flag: "🇬🇵", name: "Guadeloupe", phoneLength: 9...9),
        SWCountry(code: "+1", flag: "🇬🇺", name: "Guam", phoneLength: 10...10),
        SWCountry(code: "+502", flag: "🇬🇹", name: "Guatemala", phoneLength: 8...8),
        SWCountry(code: "+224", flag: "🇬🇳", name: "Guinea", phoneLength: 9...9),
        SWCountry(code: "+245", flag: "🇬🇼", name: "Guinea-Bissau", phoneLength: 7...7),
        SWCountry(code: "+592", flag: "🇬🇾", name: "Guyana", phoneLength: 7...7),

        // H
        SWCountry(code: "+509", flag: "🇭🇹", name: "Haiti", phoneLength: 8...8),
        SWCountry(code: "+504", flag: "🇭🇳", name: "Honduras", phoneLength: 8...8),
        SWCountry(code: "+852", flag: "🇭🇰", name: "Hong Kong", phoneLength: 8...8),
        SWCountry(code: "+36", flag: "🇭🇺", name: "Hungary", phoneLength: 9...9),

        // I
        SWCountry(code: "+354", flag: "🇮🇸", name: "Iceland", phoneLength: 7...7),
        SWCountry(code: "+91", flag: "🇮🇳", name: "India", phoneLength: 10...10),
        SWCountry(code: "+62", flag: "🇮🇩", name: "Indonesia", phoneLength: 10...12),
        SWCountry(code: "+98", flag: "🇮🇷", name: "Iran", phoneLength: 10...10),
        SWCountry(code: "+964", flag: "🇮🇶", name: "Iraq", phoneLength: 10...10),
        SWCountry(code: "+353", flag: "🇮🇪", name: "Ireland", phoneLength: 9...9),
        SWCountry(code: "+972", flag: "🇮🇱", name: "Israel", phoneLength: 9...9),
        SWCountry(code: "+39", flag: "🇮🇹", name: "Italy", phoneLength: 10...10),

        // J
        SWCountry(code: "+1", flag: "🇯🇲", name: "Jamaica", phoneLength: 10...10),
        SWCountry(code: "+81", flag: "🇯🇵", name: "Japan", phoneLength: 10...10),
        SWCountry(code: "+962", flag: "🇯🇴", name: "Jordan", phoneLength: 9...9),

        // K
        SWCountry(code: "+7", flag: "🇰🇿", name: "Kazakhstan", phoneLength: 10...10),
        SWCountry(code: "+254", flag: "🇰🇪", name: "Kenya", phoneLength: 9...9),
        SWCountry(code: "+686", flag: "🇰🇮", name: "Kiribati", phoneLength: 8...8),
        SWCountry(code: "+383", flag: "🇽🇰", name: "Kosovo", phoneLength: 8...9),
        SWCountry(code: "+965", flag: "🇰🇼", name: "Kuwait", phoneLength: 8...8),
        SWCountry(code: "+996", flag: "🇰🇬", name: "Kyrgyzstan", phoneLength: 9...9),

        // L
        SWCountry(code: "+856", flag: "🇱🇦", name: "Laos", phoneLength: 10...10),
        SWCountry(code: "+371", flag: "🇱🇻", name: "Latvia", phoneLength: 8...8),
        SWCountry(code: "+961", flag: "🇱🇧", name: "Lebanon", phoneLength: 7...8),
        SWCountry(code: "+266", flag: "🇱🇸", name: "Lesotho", phoneLength: 8...8),
        SWCountry(code: "+231", flag: "🇱🇷", name: "Liberia", phoneLength: 7...8),
        SWCountry(code: "+218", flag: "🇱🇾", name: "Libya", phoneLength: 9...9),
        SWCountry(code: "+423", flag: "🇱🇮", name: "Liechtenstein", phoneLength: 7...7),
        SWCountry(code: "+370", flag: "🇱🇹", name: "Lithuania", phoneLength: 8...8),
        SWCountry(code: "+352", flag: "🇱🇺", name: "Luxembourg", phoneLength: 9...9),

        // M
        SWCountry(code: "+853", flag: "🇲🇴", name: "Macau", phoneLength: 8...8),
        SWCountry(code: "+389", flag: "🇲🇰", name: "Macedonia", phoneLength: 8...8),
        SWCountry(code: "+261", flag: "🇲🇬", name: "Madagascar", phoneLength: 9...9),
        SWCountry(code: "+265", flag: "🇲🇼", name: "Malawi", phoneLength: 9...9),
        SWCountry(code: "+60", flag: "🇲🇾", name: "Malaysia", phoneLength: 9...10),
        SWCountry(code: "+960", flag: "🇲🇻", name: "Maldives", phoneLength: 7...7),
        SWCountry(code: "+223", flag: "🇲🇱", name: "Mali", phoneLength: 8...8),
        SWCountry(code: "+356", flag: "🇲🇹", name: "Malta", phoneLength: 8...8),
        SWCountry(code: "+692", flag: "🇲🇭", name: "Marshall Islands", phoneLength: 7...7),
        SWCountry(code: "+596", flag: "🇲🇶", name: "Martinique", phoneLength: 9...9),
        SWCountry(code: "+222", flag: "🇲🇷", name: "Mauritania", phoneLength: 8...8),
        SWCountry(code: "+230", flag: "🇲🇺", name: "Mauritius", phoneLength: 8...8),
        SWCountry(code: "+52", flag: "🇲🇽", name: "Mexico", phoneLength: 10...10),
        SWCountry(code: "+691", flag: "🇫🇲", name: "Micronesia", phoneLength: 7...7),
        SWCountry(code: "+373", flag: "🇲🇩", name: "Moldova", phoneLength: 8...8),
        SWCountry(code: "+377", flag: "🇲🇨", name: "Monaco", phoneLength: 8...9),
        SWCountry(code: "+976", flag: "🇲🇳", name: "Mongolia", phoneLength: 8...8),
        SWCountry(code: "+382", flag: "🇲🇪", name: "Montenegro", phoneLength: 8...8),
        SWCountry(code: "+212", flag: "🇲🇦", name: "Morocco", phoneLength: 9...9),
        SWCountry(code: "+258", flag: "🇲🇿", name: "Mozambique", phoneLength: 9...9),
        SWCountry(code: "+95", flag: "🇲🇲", name: "Myanmar", phoneLength: 8...10),

        // N
        SWCountry(code: "+264", flag: "🇳🇦", name: "Namibia", phoneLength: 9...9),
        SWCountry(code: "+674", flag: "🇳🇷", name: "Nauru", phoneLength: 7...7),
        SWCountry(code: "+977", flag: "🇳🇵", name: "Nepal", phoneLength: 10...10),
        SWCountry(code: "+31", flag: "🇳🇱", name: "Netherlands", phoneLength: 9...9),
        SWCountry(code: "+687", flag: "🇳🇨", name: "New Caledonia", phoneLength: 6...6),
        SWCountry(code: "+64", flag: "🇳🇿", name: "New Zealand", phoneLength: 9...10),
        SWCountry(code: "+505", flag: "🇳🇮", name: "Nicaragua", phoneLength: 8...8),
        SWCountry(code: "+227", flag: "🇳🇪", name: "Niger", phoneLength: 8...8),
        SWCountry(code: "+234", flag: "🇳🇬", name: "Nigeria", phoneLength: 10...10),
        SWCountry(code: "+850", flag: "🇰🇵", name: "North Korea", phoneLength: 10...10),
        SWCountry(code: "+47", flag: "🇳🇴", name: "Norway", phoneLength: 8...8),

        // O
        SWCountry(code: "+968", flag: "🇴🇲", name: "Oman", phoneLength: 8...8),

        // P
        SWCountry(code: "+92", flag: "🇵🇰", name: "Pakistan", phoneLength: 10...10),
        SWCountry(code: "+680", flag: "🇵🇼", name: "Palau", phoneLength: 7...7),
        SWCountry(code: "+507", flag: "🇵🇦", name: "Panama", phoneLength: 8...8),
        SWCountry(code: "+675", flag: "🇵🇬", name: "Papua New Guinea", phoneLength: 8...8),
        SWCountry(code: "+595", flag: "🇵🇾", name: "Paraguay", phoneLength: 9...9),
        SWCountry(code: "+51", flag: "🇵🇪", name: "Peru", phoneLength: 9...9),
        SWCountry(code: "+63", flag: "🇵🇭", name: "Philippines", phoneLength: 10...10),
        SWCountry(code: "+48", flag: "🇵🇱", name: "Poland", phoneLength: 9...9),
        SWCountry(code: "+351", flag: "🇵🇹", name: "Portugal", phoneLength: 9...9),
        SWCountry(code: "+1", flag: "🇵🇷", name: "Puerto Rico", phoneLength: 10...10),

        // Q
        SWCountry(code: "+974", flag: "🇶🇦", name: "Qatar", phoneLength: 8...8),

        // R
        SWCountry(code: "+262", flag: "🇷🇪", name: "Reunion", phoneLength: 9...9),
        SWCountry(code: "+40", flag: "🇷🇴", name: "Romania", phoneLength: 9...9),
        SWCountry(code: "+7", flag: "🇷🇺", name: "Russia", phoneLength: 10...10),
        SWCountry(code: "+250", flag: "🇷🇼", name: "Rwanda", phoneLength: 9...9),

        // S
        SWCountry(code: "+1", flag: "🇰🇳", name: "Saint Kitts and Nevis", phoneLength: 10...10),
        SWCountry(code: "+1", flag: "🇱🇨", name: "Saint Lucia", phoneLength: 10...10),
        SWCountry(code: "+1", flag: "🇻🇨", name: "Saint Vincent and the Grenadines", phoneLength: 10...10),
        SWCountry(code: "+685", flag: "🇼🇸", name: "Samoa", phoneLength: 7...7),
        SWCountry(code: "+378", flag: "🇸🇲", name: "San Marino", phoneLength: 8...10),
        SWCountry(code: "+239", flag: "🇸🇹", name: "São Tomé and Príncipe", phoneLength: 7...7),
        SWCountry(code: "+966", flag: "🇸🇦", name: "Saudi Arabia", phoneLength: 9...9),
        SWCountry(code: "+221", flag: "🇸🇳", name: "Senegal", phoneLength: 9...9),
        SWCountry(code: "+381", flag: "🇷🇸", name: "Serbia", phoneLength: 9...9),
        SWCountry(code: "+248", flag: "🇸🇨", name: "Seychelles", phoneLength: 7...7),
        SWCountry(code: "+232", flag: "🇸🇱", name: "Sierra Leone", phoneLength: 8...8),
        SWCountry(code: "+65", flag: "🇸🇬", name: "Singapore", phoneLength: 8...8),
        SWCountry(code: "+421", flag: "🇸🇰", name: "Slovakia", phoneLength: 9...9),
        SWCountry(code: "+386", flag: "🇸🇮", name: "Slovenia", phoneLength: 8...8),
        SWCountry(code: "+677", flag: "🇸🇧", name: "Solomon Islands", phoneLength: 7...7),
        SWCountry(code: "+252", flag: "🇸🇴", name: "Somalia", phoneLength: 8...9),
        SWCountry(code: "+27", flag: "🇿🇦", name: "South Africa", phoneLength: 9...9),
        SWCountry(code: "+82", flag: "🇰🇷", name: "South Korea", phoneLength: 10...11),
        SWCountry(code: "+211", flag: "🇸🇸", name: "South Sudan", phoneLength: 9...9),
        SWCountry(code: "+34", flag: "🇪🇸", name: "Spain", phoneLength: 9...9),
        SWCountry(code: "+94", flag: "🇱🇰", name: "Sri Lanka", phoneLength: 9...9),
        SWCountry(code: "+249", flag: "🇸🇩", name: "Sudan", phoneLength: 9...9),
        SWCountry(code: "+597", flag: "🇸🇷", name: "Suriname", phoneLength: 7...7),
        SWCountry(code: "+268", flag: "🇸🇿", name: "Swaziland", phoneLength: 8...8),
        SWCountry(code: "+46", flag: "🇸🇪", name: "Sweden", phoneLength: 9...9),
        SWCountry(code: "+41", flag: "🇨🇭", name: "Switzerland", phoneLength: 9...9),
        SWCountry(code: "+963", flag: "🇸🇾", name: "Syria", phoneLength: 9...9),

        // T
        SWCountry(code: "+886", flag: "🇹🇼", name: "Taiwan", phoneLength: 9...9),
        SWCountry(code: "+992", flag: "🇹🇯", name: "Tajikistan", phoneLength: 9...9),
        SWCountry(code: "+255", flag: "🇹🇿", name: "Tanzania", phoneLength: 9...9),
        SWCountry(code: "+66", flag: "🇹🇭", name: "Thailand", phoneLength: 9...9),
        SWCountry(code: "+228", flag: "🇹🇬", name: "Togo", phoneLength: 8...8),
        SWCountry(code: "+676", flag: "🇹🇴", name: "Tonga", phoneLength: 7...7),
        SWCountry(code: "+1", flag: "🇹🇹", name: "Trinidad and Tobago", phoneLength: 10...10),
        SWCountry(code: "+216", flag: "🇹🇳", name: "Tunisia", phoneLength: 8...8),
        SWCountry(code: "+90", flag: "🇹🇷", name: "Turkey", phoneLength: 10...10),
        SWCountry(code: "+993", flag: "🇹🇲", name: "Turkmenistan", phoneLength: 8...8),
        SWCountry(code: "+1", flag: "🇹🇨", name: "Turks and Caicos Islands", phoneLength: 10...10),
        SWCountry(code: "+688", flag: "🇹🇻", name: "Tuvalu", phoneLength: 6...6),

        // U
        SWCountry(code: "+256", flag: "🇺🇬", name: "Uganda", phoneLength: 9...9),
        SWCountry(code: "+380", flag: "🇺🇦", name: "Ukraine", phoneLength: 9...9),
        SWCountry(code: "+971", flag: "🇦🇪", name: "United Arab Emirates", phoneLength: 9...9),
        SWCountry(code: "+44", flag: "🇬🇧", name: "United Kingdom", phoneLength: 10...10),
        SWCountry(code: "+1", flag: "🇺🇸", name: "United States", phoneLength: 10...10),
        SWCountry(code: "+598", flag: "🇺🇾", name: "Uruguay", phoneLength: 8...9),
        SWCountry(code: "+998", flag: "🇺🇿", name: "Uzbekistan", phoneLength: 9...9),

        // V
        SWCountry(code: "+678", flag: "🇻🇺", name: "Vanuatu", phoneLength: 7...7),
        SWCountry(code: "+379", flag: "🇻🇦", name: "Vatican City", phoneLength: 10...10),
        SWCountry(code: "+58", flag: "🇻🇪", name: "Venezuela", phoneLength: 10...10),
        SWCountry(code: "+84", flag: "🇻🇳", name: "Vietnam", phoneLength: 9...10),
        SWCountry(code: "+1", flag: "🇻🇮", name: "Virgin Islands (US)", phoneLength: 10...10),

        // Y
        SWCountry(code: "+967", flag: "🇾🇪", name: "Yemen", phoneLength: 9...9),

        // Z
        SWCountry(code: "+260", flag: "🇿🇲", name: "Zambia", phoneLength: 9...9),
        SWCountry(code: "+263", flag: "🇿🇼", name: "Zimbabwe", phoneLength: 9...9)
    ]
}
