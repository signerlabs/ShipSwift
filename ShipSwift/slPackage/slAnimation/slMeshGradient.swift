//
//  slMeshGradient.swift
//  full-pack
//
//  Created by Wei on 2025/5/17.
//

import SwiftUI

struct slMeshGradient: View {
    @State private var appear = false
    
    var body: some View {
        MeshGradient(width: 3, height: 3, points: [
            .init(0, 0), .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
            .init(0, 1), .init(0.5, 1), .init(1, 1)
        ], colors: appear ? [
            // appear = true 时的颜色（indigo/blue/cyan）
            .indigo.opacity(0.9),  .blue.opacity(0.85),   .cyan.opacity(0.8),
            .blue.opacity(0.85),   .indigo.opacity(0.9),  .blue.opacity(0.85),
            .cyan.opacity(0.8),    .blue.opacity(0.85),   .indigo.opacity(0.9)
        ] : [
            // appear = false 时的颜色（indigo/blue/cyan）
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
    slMeshGradient()
        .ignoresSafeArea()
}
