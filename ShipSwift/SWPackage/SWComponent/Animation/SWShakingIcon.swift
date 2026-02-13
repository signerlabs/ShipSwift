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
//    // Default SF Symbol ("apple.logo", 80pt)
//    SWShakingIcon()
//
//    // Custom SF Symbol
//    SWShakingIcon(systemName: "bell.fill")
//
//    // Custom size and timing
//    SWShakingIcon(
//        systemName: "heart.fill",
//        height: 120,
//        idleDelay: 2.0    // seconds before each shake cycle, default 1.5
//    )
//
//    // Asset image instead of SF Symbol
//    SWShakingIcon(imageName: "custom-logo", height: 100)
//
//  Parameters:
//    - systemName: SF Symbol name (default "apple.logo", ignored if imageName is set)
//    - imageName: Asset image name (takes priority over systemName)
//    - height: Icon height in points (default 80)
//    - idleDelay: Pause before each shake cycle in seconds (default 1.5)
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWShakingIcon: View {
    /// SF Symbol name, used when `imageName` is nil
    var systemName: String = "apple.logo"
    /// Asset image name; when set, takes priority over `systemName`
    var imageName: String? = nil
    /// Icon height in points
    var height: CGFloat = 80
    /// Pause duration before each shake cycle (seconds)
    var idleDelay: Double = 1.5

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
            iconImage
                .frame(height: height)
                .scaleEffect(phase.scale)
                .rotationEffect(.degrees(phase.rotation))
        } animation: { phase in
            switch phase {
            case .idle: .easeInOut(duration: 0.01)
            case .zoomIn: .easeInOut(duration: 0.2).delay(idleDelay)
            case .shake1L, .shake1R, .shake2L, .shake2R, .shake3L, .shake3R:
                    .easeInOut(duration: 0.08)
            case .zoomOut: .easeInOut(duration: 0.2)
            }
        }
    }

    @ViewBuilder
    private var iconImage: some View {
        if let imageName {
            Image(imageName)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
        }
    }
}

// MARK: - Preview

#Preview("Default") {
    SWShakingIcon()
}

#Preview("Custom Icon") {
    SWShakingIcon(systemName: "bell.fill", height: 100)
}

#Preview("Slow Shake") {
    SWShakingIcon(systemName: "heart.fill", idleDelay: 3.0)
}
