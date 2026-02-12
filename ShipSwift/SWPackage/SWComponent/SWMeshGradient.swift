//
//  SWMeshGradient.swift
//  ShipSwift
//
//  Animated mesh gradient background using indigo/blue/cyan color palette.
//  The gradient smoothly transitions between two color states in a 5-second loop.
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
