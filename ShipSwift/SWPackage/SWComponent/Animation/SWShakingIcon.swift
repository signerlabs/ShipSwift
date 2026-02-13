//
//  SWShakingIcon.swift
//  ShipSwift
//
//  Animated icon that periodically zooms in and shakes side-to-side,
//  mimicking the iOS home-screen jiggle/notification effect. Uses
//  PhaseAnimator with a multi-step ShakePhase sequence: idle -> zoom in
//  -> three shake pairs (left/right) -> zoom out, then repeats.
//
//  Usage:
//    // Default size (80pt)
//    SWShakingIcon()
//
//    // Custom height
//    SWShakingIcon(height: 120)
//
//  Note:
//    The icon defaults to "apple.logo" SF Symbol. To use a different icon,
//    modify the Image(systemName:) call inside the view body.
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWShakingIcon: View {
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
            case .idle: .easeInOut(duration: 0.01)
            case .zoomIn: .easeInOut(duration: 0.2).delay(1.5)
            case .shake1L, .shake1R, .shake2L, .shake2R, .shake3L, .shake3R:
                    .easeInOut(duration: 0.08)
            case .zoomOut: .easeInOut(duration: 0.2)
            }
        }
    }
}

#Preview {
    SWShakingIcon()
}
