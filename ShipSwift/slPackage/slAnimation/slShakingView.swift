//
//  slShakingView.swift
//  full-pack
//
//  Created by Wei on 2025/12/10.
//  Copyright © 2025 Signer Labs. All rights reserved.
//

import SwiftUI

struct slShakingView: View {
    var height: CGFloat = 80
    
    enum ShakePhase: CaseIterable {
        case idle
        case zoomIn
        case shake1L, shake1R
        case shake2L, shake2R
        case shake3L, shake3R
        case zoomOut
        
        var scale: Double {
            switch self {
            case .idle, .zoomOut: 1.0
            case .zoomIn, .shake1L, .shake1R, .shake2L, .shake2R, .shake3L, .shake3R: 1.1
            }
        }
        
        var rotation: Double {
            switch self {
            case .idle, .zoomIn, .zoomOut: 10
            case .shake1L: 12
            case .shake1R: 8
            case .shake2L: 15
            case .shake2R: 5
            case .shake3L: 12
            case .shake3R: 8
            }
        }
    }
    
    var body: some View {
        PhaseAnimator(ShakePhase.allCases) { phase in
            Image(systemName: "apple.logo")
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .scaleEffect(phase.scale)
                .rotationEffect(.degrees(phase.rotation))
        } animation: { phase in
            switch phase {
            case .idle: .easeInOut(duration: 0.01) // 快速回到 idle
            case .zoomIn: .easeInOut(duration: 0.2).delay(1.5) // 停顿 1.5 秒后放大
            case .shake1L, .shake1R, .shake2L, .shake2R, .shake3L, .shake3R:
                    .easeInOut(duration: 0.08) // 每次摇晃
            case .zoomOut: .easeInOut(duration: 0.2) // 缩回
            }
        }
    }
}

#Preview {
    slShakingView()
}
