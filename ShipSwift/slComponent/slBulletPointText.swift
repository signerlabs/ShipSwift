//
//  slBulletPointText.swift
//  full-pack
//
//  Created by 仲炜 on 2025/12/14.
//  Copyright © 2025 Signer Labs. All rights reserved.
//

import SwiftUI

struct slBulletPointText<Content: View>: View {
    var bulletColor: Color
    @ViewBuilder var content: Content
    
    var body: some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(bulletColor)
                .frame(width: 4, height: 12)
            
            content
                .font(.subheadline)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 10) {
        // 简单文本
        slBulletPointText(bulletColor: .blue) {
            Text("财富")
        }
        
        // HStack 内容
        slBulletPointText(bulletColor: .green) {
            HStack {
                Text("健康")
                Image(systemName: "heart.fill")
            }
        }
    }
}
