//
//  SWLabel.swift
//  ShipSwift
//
//  Created by Wei on 2025/5/12.
//

import SwiftUI

struct SWLabelWithIcon: View {
    var icon: String = "pencil"
    var bg: Color = .blue
    var name: LocalizedStringResource = "Name"

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(bg.gradient.opacity(0.9))
                Image(systemName: icon)
                    .fontWeight(.light)
                    .foregroundStyle(.ultraThickMaterial)
            }
            .padding(5)
            Text(name)
        }
    }
}

struct SWLabelWithImage: View {
    var image: ImageResource
    var name: LocalizedStringResource = "Name"
    var body: some View {
        HStack {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(5)
            Text(name)
        }
    }
}

#Preview {
    VStack {
        SWLabelWithIcon()
    }
}
