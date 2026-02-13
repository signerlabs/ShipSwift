//
//  SWMeshGradient.swift
//  ShipSwift
//
//  Animated 3x3 mesh gradient background that smoothly transitions between
//  two indigo/blue/cyan color palettes using a repeating easeInOut animation.
//  Designed as a full-screen or section background layer.
//
//  Usage:
//    // As a full-screen background
//    ZStack {
//        SWMeshGradient()
//            .ignoresSafeArea()
//        // Your content here
//    }
//
//    // As a section background
//    myContent
//        .background {
//            SWMeshGradient()
//        }
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWMeshGradient: View {
    @State private var appear = false

    var body: some View {
        MeshGradient(width: 3, height: 3, points: [
            .init(0, 0), .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
            .init(0, 1), .init(0.5, 1), .init(1, 1)
        ], colors: appear ? [
            .indigo.opacity(0.9),  .blue.opacity(0.85),   .cyan.opacity(0.8),
            .blue.opacity(0.85),   .indigo.opacity(0.9),  .blue.opacity(0.85),
            .cyan.opacity(0.8),    .blue.opacity(0.85),   .indigo.opacity(0.9)
        ] : [
            .cyan.opacity(0.8),    .indigo.opacity(0.9),  .blue.opacity(0.85),
            .indigo.opacity(0.85), .blue.opacity(0.9),    .cyan.opacity(0.85),
            .blue.opacity(0.85),   .cyan.opacity(0.8),    .indigo.opacity(0.9)
        ])
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                appear = true
            }
        }
    }
}

#Preview {
    SWMeshGradient()
        .ignoresSafeArea()
}
