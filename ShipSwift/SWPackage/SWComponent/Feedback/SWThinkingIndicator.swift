//
//  SWThinkingIndicator.swift
//  ShipSwift
//
//  Animated thinking/typing indicator with three bouncing dots.
//  Commonly used in chat interfaces to show that the AI or remote user is typing.
//
//  Usage:
//    // Default style
//    SWThinkingIndicator()
//
//    // Custom dot size, color, and spacing
//    SWThinkingIndicator(dotSize: 8, dotColor: .blue, spacing: 5)
//
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
//  Parameters:
//    - dotSize:  Diameter of each dot (default: 5)
//    - dotColor: Fill color of the dots (default: .secondary)
//    - spacing:  Horizontal spacing between dots (default: 3)
//
//  Notes:
//    - Uses TimelineView for zero-lifecycle-management animation
//    - Three dots bounce up and down sequentially at 0.3 second intervals
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

// MARK: - SWThinkingIndicator

struct SWThinkingIndicator: View {

    // MARK: - Configurable Parameters

    var dotSize: CGFloat = 5
    var dotColor: Color = .secondary
    var spacing: CGFloat = 3

    // MARK: - Body

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.3)) { timeline in
            let phase = Int(timeline.date.timeIntervalSinceReferenceDate / 0.3) % 3
            HStack(spacing: spacing) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(dotColor)
                        .frame(width: dotSize, height: dotSize)
                        .offset(y: phase == index ? -(dotSize * 0.6) : 0)
                        .animation(.easeInOut(duration: 0.2), value: phase)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Default style
        VStack(spacing: 8) {
            Text("Default")
                .font(.caption)
                .foregroundStyle(.secondary)
            SWThinkingIndicator()
        }

        // Chat bubble usage
        VStack(spacing: 8) {
            Text("Chat Bubble")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.purple)
                HStack(spacing: 4) {
                    Text("Thinking")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    SWThinkingIndicator()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }

        // Custom color and size
        VStack(spacing: 8) {
            Text("Custom (blue, large)")
                .font(.caption)
                .foregroundStyle(.secondary)
            SWThinkingIndicator(dotSize: 10, dotColor: .blue, spacing: 6)
        }
    }
    .padding()
}
