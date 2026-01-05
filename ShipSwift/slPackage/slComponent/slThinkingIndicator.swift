//
//  slThinkingIndicator.swift
//  ShipSwift
//
//  Created by Wei Zhong on 5/1/26.
//

import SwiftUI

struct slThinkingIndicator: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 5, height: 5)
                    .offset(y: animationPhase == index ? -3 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

#Preview {
    slThinkingIndicator()
}
