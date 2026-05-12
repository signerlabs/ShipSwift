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
    var color: Color = .accentColor

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(
                    color.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.swCardTitle)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.swMeta)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ListItem(
            title: "Before / After",
            icon: "slider.horizontal.below.rectangle",
            description: "Image comparison view with auto-oscillating slider and drag gesture."
        )
        ListItem(
            title: "Camera",
            icon: "camera.fill",
            description: "Full camera capture view with viewfinder overlay, pinch-to-zoom, and permission handling.",
            color: .orange
        )
        ListItem(
            title: "Donut Chart",
            icon: "chart.pie.fill",
            description: "Interactive donut chart with selection state.",
            color: .green
        )
    }
}
