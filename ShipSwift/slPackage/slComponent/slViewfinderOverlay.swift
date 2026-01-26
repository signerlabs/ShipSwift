//
//  slViewfinderOverlay.swift
//  ShipSwift
//
//  取景框遮罩组件 - 用于相机拍摄、扫描等场景
//  显示带圆角的裁剪框，周围是半透明遮罩
//
//  使用示例:
//  ```
//  slViewfinderOverlay()  // 使用默认参数
//
//  slViewfinderOverlay(
//      width: 280,
//      height: 280,
//      cornerRadius: 20,
//      borderColor: .yellow,
//      maskColor: .black.opacity(0.6),
//      verticalOffset: -40  // 向上偏移
//  )
//  ```
//

import SwiftUI

/// 取景框遮罩组件
/// 显示带圆角的裁剪框，周围是半透明遮罩
struct slViewfinderOverlay: View {
    /// 裁剪框宽度
    var width: CGFloat = 300
    /// 裁剪框高度
    var height: CGFloat = 180
    /// 圆角半径
    var cornerRadius: CGFloat = 40
    /// 边框颜色
    var borderColor: Color = .white.opacity(0.6)
    /// 边框宽度
    var borderWidth: CGFloat = 3
    /// 遮罩颜色
    var maskColor: Color = .black.opacity(0.8)
    /// 垂直偏移（负数向上，默认居中）
    var verticalOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2 + verticalOffset

            ZStack {
                // 灰色遮罩（只露出中间裁剪区域）
                Canvas { context, canvasSize in
                    // 绘制全屏遮罩
                    context.fill(
                        Path(CGRect(origin: .zero, size: canvasSize)),
                        with: .color(maskColor)
                    )

                    // 挖空中间区域
                    let cropRect = CGRect(
                        x: centerX - width / 2,
                        y: centerY - height / 2,
                        width: width,
                        height: height
                    )
                    let cropPath = Path(roundedRect: cropRect, cornerRadius: cornerRadius)
                    context.blendMode = .destinationOut
                    context.fill(cropPath, with: .color(.white))
                }
                .compositingGroup()

                // 裁剪框边框
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
                    .frame(width: width, height: height)
                    .position(x: centerX, y: centerY)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview("Default") {
    ZStack {
        Color.gray
        slViewfinderOverlay()
    }
}

#Preview("Custom Size") {
    ZStack {
        Color.gray
        slViewfinderOverlay(
            width: 250,
            height: 250,
            cornerRadius: 20,
            borderColor: .yellow,
            borderWidth: 4
        )
    }
}

#Preview("Square") {
    ZStack {
        Color.gray
        slViewfinderOverlay(
            width: 280,
            height: 280,
            cornerRadius: 16
        )
    }
}
