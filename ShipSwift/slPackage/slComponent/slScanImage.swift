//
//  slScanImage.swift
//  ShipSwift
//
//  带扫描线动效的图片组件
//  适用于图片分析、加载等场景，显示从左到右扫过的光带效果
//
//  使用示例:
//  ```
//  slScanImage(.myImage)
//
//  slScanImage(.myImage, lineWidth: 100, duration: 2.0)
//  ```
//
//  参数说明:
//  - image: ImageResource 图片资源
//  - lineWidth: 扫描线宽度，默认 80
//  - duration: 扫描周期（秒），默认 1.5
//  - lineColor: 扫描线颜色，默认 .white.opacity(0.6)
//

import SwiftUI

struct slScanImage: View {
    @State private var animate = false

    var image: ImageResource
    var lineWidth: CGFloat = 80
    var duration: Double = 1.5
    var lineColor: Color = .white.opacity(0.6)

    var body: some View {
        Image(image)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                // 扫描线动效
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, lineColor, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: lineWidth)
                    .offset(x: animate ? geo.size.width : -lineWidth)
                    .animation(
                        .linear(duration: duration).repeatForever(autoreverses: false),
                        value: animate
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .onAppear {
                animate = true
            }
    }
}

// MARK: - Preview

#Preview("Default") {
    slScanImage(image: .init(name: "photo", bundle: nil))
        .frame(width: 300, height: 200)
        .padding()
}
