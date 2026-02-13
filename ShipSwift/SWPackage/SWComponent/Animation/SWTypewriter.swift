//
//  SWTypewriter.swift
//  ShipSwift
//
//  Typewriter text animation that cycles through an array of strings,
//  typing and deleting characters one by one with configurable animation
//  styles. Ideal for landing page headlines, onboarding prompts, and
//  AI chat UIs.
//
//  Usage:
//    // Basic — cycles through texts with default spring animation
//    SWTypewriter(texts: ["Hello World", "Welcome Back", "Let's Go"])
//
//    // Choose an animation style (SWTypewriterStyle):
//    //   .none, .spring, .blur, .fade, .scale, .wave
//    SWTypewriter(texts: ["Line 1", "Line 2"], animationStyle: .blur)
//
//    // Convenience factory methods
//    SWTypewriter.spring(texts: ["A", "B"])
//    SWTypewriter.blur(texts: ["A", "B"])
//    SWTypewriter.fade(texts: ["A", "B"])
//    SWTypewriter.scale(texts: ["A", "B"])
//
//    // Custom gradient and timing
//    SWTypewriter(
//        texts: ["Message 1", "Message 2"],
//        typingSpeed: 0.05,       // seconds per character typed
//        deletingSpeed: 0.03,     // seconds per character deleted
//        pauseDuration: 3.0,      // seconds to hold completed text
//        animationStyle: .spring,
//        gradient: LinearGradient(
//            colors: [.pink, .orange],
//            startPoint: .leading,
//            endPoint: .trailing
//        )
//    )
//    .font(.title3.weight(.semibold))
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

// MARK: - SWTypewriterStyle

/// Animation style for the typewriter effect
enum SWTypewriterStyle {
    case none       // No animation, plain typewriter
    case spring     // Spring effect: characters bounce in/out
    case blur       // Blur effect: characters transition from blurry to clear
    case fade       // Fade effect: characters fade in/out with slide
    case scale      // Scale effect: characters grow/shrink
    case wave       // Wave effect: characters have vertical oscillation
}

// MARK: - SWTypewriter

/// Typewriter text component
///
/// Prints text character by character, supporting multiple texts in a cycle with smooth animations.
/// Ideal for landing page headlines, AI chat, onboarding prompts, etc.
///
/// ## Usage
///
/// ```swift
/// // Basic usage
/// SWTypewriter(texts: ["Hello World", "Welcome Back", "Let's Go"])
///
/// // Custom gradient
/// SWTypewriter(
///     texts: ["Message 1", "Message 2"],
///     gradient: LinearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing)
/// )
///
/// // Custom animation style
/// SWTypewriter(
///     texts: ["Message 1", "Message 2"],
///     animationStyle: .blur
/// )
///
/// // Full parameters
/// SWTypewriter(
///     texts: ["Message 1", "Message 2"],
///     typingSpeed: 0.05,      // Typing speed (seconds per character)
///     deletingSpeed: 0.03,    // Deleting speed (seconds per character)
///     pauseDuration: 3.0,     // Pause duration (seconds)
///     animationStyle: .spring,
///     gradient: LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing)
/// )
/// .font(.title3.weight(.semibold))
/// ```
///
/// ## Animation Styles (SWTypewriterStyle)
///
/// | Style     | Insertion          | Removal            |
/// |-----------|--------------------|--------------------|
/// | `.none`   | No animation       | No animation       |
/// | `.spring` | Bounce in + fade   | Shrink + fade out  |
/// | `.blur`   | Blur → clear       | Blur + fade out    |
/// | `.fade`   | Slide down + fade  | Slide down + fade  |
/// | `.scale`  | Scale down + fade  | Scale up + fade    |
/// | `.wave`   | Drop in + fade     | Drop out + fade    |
///
/// ## Parameters
/// - `texts`: Array of texts to cycle through
/// - `typingSpeed`: Interval per character when typing (seconds), default 0.04
/// - `deletingSpeed`: Interval per character when deleting (seconds), default 0.03
/// - `pauseDuration`: How long to display completed text (seconds), default 2.5
/// - `animationStyle`: Animation style, default `.spring`
/// - `gradient`: Text gradient, default cyan → purple
///
/// ## Notes
/// - The component loops infinitely
/// - Pair with `.font()` modifier to set size and weight
/// - Uses an invisible `|` character as height placeholder to prevent layout jumps

struct SWTypewriter: View {
    let texts: [String]
    var typingSpeed: Double = 0.04
    var deletingSpeed: Double = 0.03
    var pauseDuration: Double = 2.5
    var animationStyle: SWTypewriterStyle = .spring
    var gradient: LinearGradient = LinearGradient(
        colors: [.cyan, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )

    @State private var displayedText = ""
    @State private var currentIndex = 0
    @State private var isDeleting = false
    @State private var charStates: [SWTypewriterCharState] = []
    @State private var isActive = false

    var body: some View {
        HStack(spacing: 0) {
            // Character-level animation
            HStack(spacing: 0) {
                ForEach(charStates) { state in
                    Text(state.character)
                        .foregroundStyle(gradient)
                        .transition(transitionForStyle)
                }
            }
            .animation(animationForCurrentAction, value: charStates.count)

            // Invisible height placeholder to prevent layout jumps
            Text("|")
                .foregroundStyle(.clear)
        }
        .onAppear {
            isActive = true
            displayedText = ""
            charStates = []
            currentIndex = 0
            isDeleting = false
            startTyping()
        }
        .onDisappear {
            isActive = false
        }
    }

    // MARK: - Transition Configuration

    private var transitionForStyle: AnyTransition {
        switch animationStyle {
        case .none:
            return .identity

        case .spring:
            return .asymmetric(
                insertion: .scale(scale: 0.3).combined(with: .opacity),
                removal: .scale(scale: 0.3).combined(with: .opacity)
            )

        case .blur:
            return .asymmetric(
                insertion: .opacity.combined(with: .swBlur),
                removal: .opacity.combined(with: .swBlur)
            )

        case .fade:
            return .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )

        case .scale:
            return .asymmetric(
                insertion: .scale(scale: 1.5).combined(with: .opacity),
                removal: .scale(scale: 1.5).combined(with: .opacity)
            )

        case .wave:
            return .asymmetric(
                insertion: .offset(y: -8).combined(with: .opacity),
                removal: .offset(y: 8).combined(with: .opacity)
            )
        }
    }

    private var animationForCurrentAction: Animation {
        if isDeleting {
            switch animationStyle {
            case .none: return .linear(duration: 0)
            case .spring: return .easeOut(duration: 0.15)
            case .blur: return .easeOut(duration: 0.12)
            case .fade: return .easeOut(duration: 0.12)
            case .scale: return .easeOut(duration: 0.12)
            case .wave: return .easeOut(duration: 0.12)
            }
        } else {
            switch animationStyle {
            case .none: return .linear(duration: 0)
            case .spring: return .spring(response: 0.3, dampingFraction: 0.6)
            case .blur: return .easeOut(duration: 0.2)
            case .fade: return .easeOut(duration: 0.2)
            case .scale: return .spring(response: 0.25, dampingFraction: 0.7)
            case .wave: return .easeInOut(duration: 0.15)
            }
        }
    }

    // MARK: - Typing Logic

    private func startTyping() {
        guard !texts.isEmpty, isActive else { return }
        typeNextCharacter()
    }

    private func typeNextCharacter() {
        guard isActive else { return }

        let currentText = texts[currentIndex]

        if isDeleting {
            if charStates.isEmpty {
                // All characters deleted, switch to next text
                isDeleting = false
                displayedText = ""
                currentIndex = (currentIndex + 1) % texts.count
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                    guard isActive else { return }
                    typeNextCharacter()
                }
            } else {
                // Remove last character
                DispatchQueue.main.asyncAfter(deadline: .now() + deletingSpeed) { [self] in
                    guard isActive else { return }
                    if !charStates.isEmpty {
                        _ = charStates.removeLast()
                        displayedText = String(displayedText.dropLast())
                    }
                    typeNextCharacter()
                }
            }
        } else {
            if displayedText.count < currentText.count {
                let charIndex = currentText.index(currentText.startIndex, offsetBy: displayedText.count)
                let newChar = currentText[charIndex]

                DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed) { [self] in
                    guard isActive else { return }
                    displayedText.append(newChar)
                    charStates.append(SWTypewriterCharState(character: String(newChar)))
                    typeNextCharacter()
                }
            } else {
                // Typing complete, wait before deleting
                DispatchQueue.main.asyncAfter(deadline: .now() + pauseDuration) { [self] in
                    guard isActive else { return }
                    isDeleting = true
                    typeNextCharacter()
                }
            }
        }
    }
}

// MARK: - Character State

private struct SWTypewriterCharState: Identifiable, Equatable {
    let id = UUID()
    var character: String
}

// MARK: - Custom Blur Transition

extension AnyTransition {
    static var swBlur: AnyTransition {
        .modifier(
            active: SWBlurModifier(radius: 10, opacity: 0),
            identity: SWBlurModifier(radius: 0, opacity: 1)
        )
    }
}

private struct SWBlurModifier: ViewModifier {
    let radius: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: radius)
            .opacity(opacity)
    }
}

// MARK: - Convenience Initializers

extension SWTypewriter {
    /// Spring style (recommended)
    static func spring(texts: [String]) -> SWTypewriter {
        SWTypewriter(texts: texts, animationStyle: .spring)
    }

    /// Blur style
    static func blur(texts: [String]) -> SWTypewriter {
        SWTypewriter(texts: texts, animationStyle: .blur)
    }

    /// Scale style
    static func scale(texts: [String]) -> SWTypewriter {
        SWTypewriter(texts: texts, animationStyle: .scale)
    }

    /// Fade style
    static func fade(texts: [String]) -> SWTypewriter {
        SWTypewriter(texts: texts, animationStyle: .fade)
    }
}

// MARK: - Preview

#Preview("Spring Style (Default)") {
    SWTypewriter(
        texts: [
            "Level up your smile game",
            "AI-powered smile analysis",
            "Join the glow up era"
        ],
        animationStyle: .spring
    )
    .font(.title3.weight(.semibold))
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Blur Style") {
    SWTypewriter(
        texts: [
            "Level up your smile game",
            "AI-powered smile analysis",
            "Join the glow up era"
        ],
        animationStyle: .blur
    )
    .font(.title3.weight(.semibold))
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Custom Gradient") {
    SWTypewriter(
        texts: [
            "Hello World",
            "Welcome Back",
            "Let's Go"
        ],
        animationStyle: .spring,
        gradient: LinearGradient(
            colors: [.pink, .orange],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .font(.title.weight(.bold))
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
