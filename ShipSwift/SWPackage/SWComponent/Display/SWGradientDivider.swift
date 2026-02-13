//
//  SWGradientDivider.swift
//  ShipSwift
//
//  Horizontal divider with a center-fade gradient (clear -> color -> clear).
//
//  Usage:
//    SWGradientDivider()                                  // cyan, 0.3 opacity, 1pt
//    SWGradientDivider(color: .purple, opacity: 0.5)      // purple variant
//    SWGradientDivider(color: .mint, height: 2)            // thicker mint line
//
//  Created by Wei Zhong on 3/1/26.
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
