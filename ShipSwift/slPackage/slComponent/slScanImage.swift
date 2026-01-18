//
//  slScanImage.swift
//  ShipSwift
//
//  带扫描线动效的图片组件
//  适用于图片分析、加载等场景，显示从左到右扫过的光带效果
//
//  使用示例:
//  ```
//  slScanImage {
//      Image(.myImage)
//          .resizable()
//          .scaledToFit()
//  }
//
//  slScanImage(lineWidth: 100, duration: 2.0) {
//      AsyncImage(url: imageURL)
//  }
//  ```
//
//  参数说明:
//  - content: 要显示的图片视图
//  - lineWidth: 扫描线宽度，默认 80
//  - duration: 扫描周期（秒），默认 1.5
//  - lineColor: 扫描线颜色，默认 .white.opacity(0.6)
//

import SwiftUI

struct slScanImage<Content: View>: View {
    @State private var animate = false

    let content: Content
    var lineWidth: CGFloat
    var duration: Double
    var lineColor: Color

    init(
        lineWidth: CGFloat = 80,
        duration: Double = 1.5,
        lineColor: Color = .white.opacity(0.6),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.lineWidth = lineWidth
        self.duration = duration
        self.lineColor = lineColor
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
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

#Preview {
    slScanImage {
        Rectangle()
            .fill(.gray)
            .frame(width: 300, height: 200)
    }
    .padding()
}
