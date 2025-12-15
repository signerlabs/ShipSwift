//
//  slMeshGradient.swift
//  full-pack
//
//  Created by Wei on 2025/5/17.
//

import SwiftUI

struct slMeshGradient: View {
    @State var appear: Bool = false
    @State var appear2: Bool = false
    
    var body: some View {
        MeshGradient(width: 3, height: 3, points: [
            .init(0, 0), .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
            .init(0, 1), .init(0.5, 1), .init(1, 1)
        ], colors: [
            .mint.opacity(0.6), .cyan.opacity(0.6), .yellow.opacity(0.6),
            .brown.opacity(0.6), .blue.opacity(0.6), .green.opacity(0.6),
            .gray.opacity(0.6), .blue.opacity(0.6), .teal.opacity(0.6)
        ])
    }
}

#Preview {
    slMeshGradient()
        .ignoresSafeArea()
}
