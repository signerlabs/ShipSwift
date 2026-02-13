//
//  SWThinkingIndicator.swift
//  ShipSwift
//
//  Animated thinking/typing indicator with three bouncing dots.
//  Commonly used in chat interfaces to show that the AI or remote user is typing.
//
//  Usage:
//    // Show "typing" state in a chat bubble
//    if isThinking {
//        SWThinkingIndicator()
//    }
//
//    // Place in an HStack alongside text
//    HStack {
//        Text("AI is thinking")
//        SWThinkingIndicator()
//    }
//
//  Notes:
//    - No parameters required, animation starts automatically on appear
//    - Three dots bounce up and down sequentially at 0.3 second intervals
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWThinkingIndicator: View {
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
    SWThinkingIndicator()
}
