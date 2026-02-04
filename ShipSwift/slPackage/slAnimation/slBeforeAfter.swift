//
//  slBeforeAfter.swift
//  ShipSwift
//
//  前后对比滑动组件
//  自动来回滑动展示两张图片的对比效果，适用于美颜、滤镜、修图等前后对比场景
//
//  使用示例:
//  ```
//  slBeforeAfter(
//      before: Image(.photoBefore),
//      after: Image(.photoAfter)
//  )
//
//  slBeforeAfter(
//      before: Image(.photoBefore),
//      after: Image(.photoAfter),
//      width: 300,
//      aspectRatio: 16/9,
//      cornerRadius: 16,
//      speed: 1.0
//  )
//  ```
//
//  参数说明:
//  - before: 原图 (底层)
//  - after: 效果图 (顶层，被 mask 裁切)
//  - width: 图片宽度，默认 360
//  - aspectRatio: 宽高比 (宽/高)，默认 4/3
//  - cornerRadius: 圆角半径，默认 24
//  - speed: 滑动速度，默认 0.8
//  - showLabels: 是否显示 Before/After 标签，默认 true
//

import SwiftUI

struct slBeforeAfter: View {
    let before: Image
    let after: Image
    var width: CGFloat = 360
    var aspectRatio: CGFloat = 4.0 / 3.0
    var cornerRadius: CGFloat = 24
    var speed: Double = 0.8
    var showLabels: Bool = true

    private var height: CGFloat { width / aspectRatio }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            // 滑块来回移动：0.2 到 0.8 之间
            let sliderPos = 0.5 + sin(t * speed) * 0.3
            let sliderX = sliderPos * width

            ZStack {
                // 底层图片 (Before)
                before
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                // 顶层图片 (After) - 用 mask 控制显示区域
                after
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: sliderX)
                            Spacer(minLength: 0)
                        }
                        .frame(width: width)
                    )

                // 滑动分割线
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 3, height: height)
                    .offset(x: sliderX - width / 2)

                // 滑块手柄
                Image(systemName: "arrow.left.and.right.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(
                        .ultraThinMaterial,
                        .white.opacity(0.8)
                    )
                    .offset(x: sliderX - width / 2)

                // Before / After 标签
                if showLabels {
                    HStack {
                        Text("Before")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(12)

                        Spacer()

                        Text("After")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(12)
                    }
                    .frame(width: width, height: height, alignment: .bottom)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    slBeforeAfter(
        before: Image(systemName: "photo"),
        after: Image(systemName: "photo.fill")
    )
    .padding()
    .background(Color.black)
}
