//
//  ListItem.swift
//  ShipSwift
//
//  Created by Wei Zhong on 13/2/26.
//

import SwiftUI

struct ListItem: View {
    /// Component name — shown as written (matches the type name in code).
    let title: String
    let icon: String
    /// Localized via the String Catalog.
    let description: LocalizedStringKey

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
