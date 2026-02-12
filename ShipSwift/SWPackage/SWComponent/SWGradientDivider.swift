//
//  SWGradientDivider.swift
//  ShipSwift
//
//  Gradient divider component - a divider that is bright in the center and fades at both ends
//
//  Usage:
//  ```
//  SWGradientDivider()
//  SWGradientDivider(color: .purple, opacity: 0.5)
//  SWGradientDivider(color: .mint, height: 2)
//  ```
//

import SwiftUI

struct SWGradientDivider: View {
    var color: Color = .cyan
    var opacity: Double = 0.3
    var height: CGFloat = 1

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, color.opacity(opacity), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        SWGradientDivider()
        SWGradientDivider(color: .purple, opacity: 0.5)
        SWGradientDivider(color: .mint, height: 2)
    }
    .padding()
    .background(Color.black)
}
