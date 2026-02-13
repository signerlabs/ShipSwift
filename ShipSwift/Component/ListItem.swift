//
//  ListItem.swift
//  ShipSwift
//
//  Created by Wei Zhong on 13/2/26.
//

import SwiftUI

struct ListItem: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        ListItem(
            title: "Before / After",
            icon: "slider.horizontal.below.rectangle",
            description: "Image comparison view with auto-oscillating slider and drag gesture."
        )
    }
}
