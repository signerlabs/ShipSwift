//
//  SWLabel.swift
//  ShipSwift
//
//  Reusable label components that pair a leading visual (SF Symbol or image
//  resource) with a localized text name. Commonly used in List rows,
//  settings screens, or menu items.
//
//  Usage:
//    // Label with an SF Symbol icon on a colored circle
//    SWLabelWithIcon(
//        icon: "gearshape",          // SF Symbol name, default "pencil"
//        bg: .orange,                // circle background color, default .blue
//        name: "Settings"            // LocalizedStringResource
//    )
//
//    // Label with a custom image resource
//    SWLabelWithImage(
//        image: .appIcon,            // ImageResource from asset catalog
//        name: "My App"              // LocalizedStringResource
//    )
//
//  Created by Wei Zhong on 3/1/26.
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
