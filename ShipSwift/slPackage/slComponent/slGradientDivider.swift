//
//  slGradientDivider.swift
//  ShipSwift
//
//  渐变分割线组件 - 中间亮两边淡的分割线
//
//  使用示例:
//  ```
//  slGradientDivider()
//  slGradientDivider(color: .purple, opacity: 0.5)
//  slGradientDivider(color: .mint, height: 2)
//  ```
//

import SwiftUI

struct slGradientDivider: View {
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
        slGradientDivider()
        slGradientDivider(color: .purple, opacity: 0.5)
        slGradientDivider(color: .mint, height: 2)
    }
    .padding()
    .background(Color.black)
}
