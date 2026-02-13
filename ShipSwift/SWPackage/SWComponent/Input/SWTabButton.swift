//
//  SWTabButton.swift
//  ShipSwift
//
//  Capsule-shaped tab button that toggles between selected (accent color)
//  and unselected (gray) states. Suitable for building custom segmented
//  controls or horizontal filter bars.
//
//  Usage:
//    @State private var selectedTab = 0
//
//    HStack {
//        SWTabButton(title: "All", isSelected: selectedTab == 0) {
//            selectedTab = 0
//        }
//        SWTabButton(title: "Favorites", isSelected: selectedTab == 1) {
//            selectedTab = 1
//        }
//    }
//
//  Parameters:
//    title      — LocalizedStringKey displayed on the button
//    isSelected — drives the visual state (accent bg vs gray bg)
//    action     — closure called on tap
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWTabButton: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        SWTabButton(title: "Selected", isSelected: true) {}
        SWTabButton(title: "Unselected", isSelected: false) {}
    }
    .padding()
}
