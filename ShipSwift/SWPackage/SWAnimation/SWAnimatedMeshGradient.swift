//
//  SWAnimatedMeshGradient.swift
//  ShipSwift
//
//  Animated 3x3 mesh gradient background that smoothly transitions between
//  two color palettes using a repeating easeInOut animation. Designed as a
//  full-screen or section background layer.
//
//  Usage:
//    // Default indigo/blue/cyan palette
//    ZStack {
//        SWAnimatedMeshGradient()
//            .ignoresSafeArea()
//        // Your content here
//    }
//
//    // As a section background
//    myContent
//        .background { SWAnimatedMeshGradient() }
//
//    // Custom color palette
//    SWAnimatedMeshGradient(
//        paletteA: [
//            .red.opacity(0.9),  .orange.opacity(0.85), .yellow.opacity(0.8),
//            .orange.opacity(0.85), .red.opacity(0.9),  .orange.opacity(0.85),
//            .yellow.opacity(0.8),  .orange.opacity(0.85), .red.opacity(0.9)
//        ],
//        paletteB: [
//            .yellow.opacity(0.8),  .red.opacity(0.9),    .orange.opacity(0.85),
//            .red.opacity(0.85),    .orange.opacity(0.9),  .yellow.opacity(0.85),
//            .orange.opacity(0.85), .yellow.opacity(0.8),  .red.opacity(0.9)
//        ]
//    )
//
//    // Custom animation duration
//    SWAnimatedMeshGradient(duration: 8.0)
//
//  Parameters:
//    - paletteA: First 9-color array for the 3x3 mesh (row-major order)
//    - paletteB: Second 9-color array to transition to
//    - duration: Animation cycle duration in seconds (default 5.0)
//
//  Notes:
//    - Both palettes must contain exactly 9 colors for the 3x3 grid
//    - The animation auto-reverses, creating a seamless loop
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWAnimatedMeshGradient: View {
    /// First color palette (9 colors, 3x3 grid, row-major order)
    var paletteA: [Color] = [
        .indigo.opacity(0.9),  .blue.opacity(0.85),   .cyan.opacity(0.8),
        .blue.opacity(0.85),   .indigo.opacity(0.9),  .blue.opacity(0.85),
        .cyan.opacity(0.8),    .blue.opacity(0.85),   .indigo.opacity(0.9)
    ]

    /// Second color palette (9 colors, 3x3 grid, row-major order)
    var paletteB: [Color] = [
        .cyan.opacity(0.8),    .indigo.opacity(0.9),  .blue.opacity(0.85),
        .indigo.opacity(0.85), .blue.opacity(0.9),    .cyan.opacity(0.85),
        .blue.opacity(0.85),   .cyan.opacity(0.8),    .indigo.opacity(0.9)
    ]

    /// Animation cycle duration in seconds
    var duration: Double = 5.0

    @State private var appear = false

    var body: some View {
        MeshGradient(width: 3, height: 3, points: [
            .init(0, 0), .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
            .init(0, 1), .init(0.5, 1), .init(1, 1)
        ], colors: appear ? paletteA : paletteB)
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                appear = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Default") {
    SWAnimatedMeshGradient()
        .ignoresSafeArea()
}

#Preview("Custom Palette") {
    SWAnimatedMeshGradient(
        paletteA: [
            .red.opacity(0.9),  .orange.opacity(0.85), .yellow.opacity(0.8),
            .orange.opacity(0.85), .red.opacity(0.9),  .orange.opacity(0.85),
            .yellow.opacity(0.8),  .orange.opacity(0.85), .red.opacity(0.9)
        ],
        paletteB: [
            .yellow.opacity(0.8),  .red.opacity(0.9),    .orange.opacity(0.85),
            .red.opacity(0.85),    .orange.opacity(0.9),  .yellow.opacity(0.85),
            .orange.opacity(0.85), .yellow.opacity(0.8),  .red.opacity(0.9)
        ],
        duration: 3.0
    )
    .ignoresSafeArea()
}
