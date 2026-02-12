//
//  SWBulletPointText.swift
//  ShipSwift
//
//  Copyright © 2025 Signer Labs. All rights reserved.
//

import SwiftUI

struct SWBulletPointText<Content: View>: View {
    var bulletColor: Color
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(bulletColor)
                .frame(width: 4, height: 12)

            content
                .font(.subheadline)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 10) {
        // Simple text
        SWBulletPointText(bulletColor: .blue) {
            Text("Wealth")
        }

        // HStack content
        SWBulletPointText(bulletColor: .green) {
            HStack {
                Text("Health")
                Image(systemName: "heart.fill")
            }
        }
    }
}
