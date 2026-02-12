//
//  SWTabButton.swift
//  ShipSwift
//
//  Created by Wei on 2025/12/7.
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
