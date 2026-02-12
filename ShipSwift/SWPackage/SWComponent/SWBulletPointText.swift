//
//  SWBulletPointText.swift
//  ShipSwift
//
//  Text label with a colored capsule bullet point indicator.
//  Accepts any View content via @ViewBuilder, displayed to the right of the bullet.
//
//  Usage:
//    // Simple text
//    SWBulletPointText(bulletColor: .blue) {
//        Text("Wealth")
//    }
//
//    // Custom content (HStack, Image, etc.)
//    SWBulletPointText(bulletColor: .green) {
//        HStack {
//            Text("Health")
//            Image(systemName: "heart.fill")
//        }
//    }
//
//  Parameters:
//    - bulletColor: Color  — Bullet point color
//    - content: @ViewBuilder — Any view displayed to the right of the bullet
//
//  Created by Wei Zhong on 3/1/26.
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
