//
//  slConstants.swift
//  full-pack
//
//  Created by Wei on 2025/7/30.
//  Copyright © 2025 Signer Labs. All rights reserved.
//

import Foundation

enum slConstants {
    
    // MARK: - URLs
    enum URL {
        static let privacyPolicy = "https://signerlabs.com/fullpack/privacy"
        static let termsOfService = "https://signerlabs.com/fullpack/terms"
        static let website = "https://signerlabs.com/fullpack"
        static let appStoreJourney = "https://apps.apple.com/us/app/journey-goal-tracker-diary/id6748666816"
        static let appStoreFullpack = "https://apps.apple.com/us/app/fullpack-packing-outfit/id6745692929"
    }
    
    // MARK: - Paywall
    enum Paywall {
        static let title = "Fullpack Pro"
        static let tripLimitForFreeUser = 3
        static let itemLimitForFreeUser = 20
        
        // Product IDs
        enum ProductID {
            static let monthly = "com.signerlabs.fullpack.monthly.0.99"
            static let yearly = "com.signerlabs.fullpack.yearly.6.99"
            static let lifetime = "com.signerlabs.fullpack.lifetime.9.99"
            
            static let allSubscriptions = [monthly, yearly]
        }
        
        // Features
        struct Feature {
            let id = UUID()
            let icon: String
            let text: LocalizedStringResource
        }
        
        static let features = [
            Feature(icon: "checkmark.seal.fill", text: "Unlimited trips & items."),
            Feature(icon: "checkmark.seal.fill", text: "Unlimited outfit creations."),
            Feature(icon: "checkmark.seal.fill", text: "iCloud sync - your data stays private and in sync."),
            Feature(icon: "checkmark.seal.fill", text: "All future premium features.")
        ]
    }
}
