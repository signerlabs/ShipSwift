//
//  slTypewriter.swift
//  ShipSwift
//
//  打字机效果文字组件 - 支持多条文案循环切换，出现和消失都有动画
//

import SwiftUI

// MARK: - slTypewriter
/// 打字机效果文字组件
///
/// 逐字符打印文字，支持多条文案循环切换，出现和消失都有平滑动画效果。
/// 适合用于首页标语、AI 对话、引导提示等场景。
///
/// ## 使用方法
///
/// ```swift
/// // 基本用法
/// slTypewriter(texts: ["Hello World", "Welcome Back", "Let's Go"])
///
/// // 自定义渐变色
/// slTypewriter(
///     texts: ["Message 1", "Message 2"],
///     gradient: LinearGradient(colors: [.pink, .orange], startPoint: .leading, endPoint: .trailing)
/// )
///
/// // 自定义动画风格
/// slTypewriter(
///     texts: ["Message 1", "Message 2"],
///     animationStyle: .blur
/// )
///
/// // 完整参数
/// slTypewriter(
///     texts: ["Message 1", "Message 2"],
///     typingSpeed: 0.05,      // 打字速度（秒/字符）
///     deletingSpeed: 0.03,    // 删除速度（秒/字符）
///     pauseDuration: 3.0,     // 停留时间（秒）
///     animationStyle: .spring,
///     gradient: LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing)
/// )
/// .font(.title3.weight(.semibold))
/// ```
///
/// ## 动画风格 (slTypewriterStyle)
///
/// | 风格 | 出现效果 | 消失效果 |
/// |------|----------|----------|
/// | `.none` | 无动画 | 无动画 |
/// | `.spring` | 从小弹入 + 淡入 | 缩小 + 淡出 |
/// | `.blur` | 从模糊变清晰 | 模糊 + 淡出 |
/// | `.fade` | 从上方滑入 + 淡入 | 向下滑出 + 淡出 |
/// | `.scale` | 从大缩小 + 淡入 | 放大 + 淡出 |
/// | `.wave` | 从上方弹入 + 淡入 | 向下偏移 + 淡出 |
///
/// ## 参数说明
/// - `texts`: 要循环显示的文案数组
/// - `typingSpeed`: 打字速度，每个字符的间隔（秒），默认 0.04
/// - `deletingSpeed`: 删除速度，每个字符的间隔（秒），默认 0.03
/// - `pauseDuration`: 文案显示完后的停留时间（秒），默认 2.5
/// - `animationStyle`: 动画风格，默认 `.spring`
/// - `gradient`: 文字渐变色，默认 cyan → purple
///
/// ## 注意事项
/// - 组件会无限循环播放
/// - 建议搭配 `.font()` 修饰符设置字体大小和粗细
/// - 使用 `|` 字符作为隐形占位符防止高度跳动

// MARK: - 动画风格枚举

enum slTypewriterStyle {
    case none           // 无动画，纯打字机
    case spring         // 弹性效果：每个字符弹入/弹出
    case blur           // 模糊效果：字符从模糊变清晰
    case fade           // 渐入效果：字符淡入/淡出
    case scale          // 缩放效果：字符从小变大/从大变小
    case wave           // 波浪效果：字符有上下波动
}

// MARK: - 主组件

struct slTypewriter: View {
    let texts: [String]
    var typingSpeed: Double = 0.04
    var deletingSpeed: Double = 0.03
    var pauseDuration: Double = 2.5
    var animationStyle: slTypewriterStyle = .spring
    var gradient: LinearGradient = LinearGradient(
        colors: [.cyan, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )

    @State private var displayedText = ""
    @State private var currentIndex = 0
    @State private var isDeleting = false
    @State private var charStates: [slTypewriterCharState] = []

    var body: some View {
        HStack(spacing: 0) {
            // 字符级别动画
            HStack(spacing: 0) {
                ForEach(charStates) { state in
                    Text(state.character)
                        .foregroundStyle(gradient)
                        .transition(transitionForStyle)
                }
            }
            .animation(animationForCurrentAction, value: charStates.count)

            // 纵向占位，防止高度跳动
            Text("|")
                .foregroundStyle(.clear)
        }
        .onAppear {
            startTyping()
        }
    }

    // MARK: - Transition 配置

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
                insertion: .opacity.combined(with: .slBlur),
                removal: .opacity.combined(with: .slBlur)
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
            // 删除动画
            switch animationStyle {
            case .none: return .linear(duration: 0)
            case .spring: return .easeOut(duration: 0.15)
            case .blur: return .easeOut(duration: 0.12)
            case .fade: return .easeOut(duration: 0.12)
            case .scale: return .easeOut(duration: 0.12)
            case .wave: return .easeOut(duration: 0.12)
            }
        } else {
            // 添加动画
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

    // MARK: - 打字逻辑

    private func startTyping() {
        guard !texts.isEmpty else { return }
        typeNextCharacter()
    }

    private func typeNextCharacter() {
        let currentText = texts[currentIndex]

        if isDeleting {
            if charStates.isEmpty {
                // 所有字符已删除，切换到下一条
                isDeleting = false
                displayedText = ""
                currentIndex = (currentIndex + 1) % texts.count
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    typeNextCharacter()
                }
            } else {
                // 移除最后一个字符
                DispatchQueue.main.asyncAfter(deadline: .now() + deletingSpeed) {
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

                DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed) {
                    displayedText.append(newChar)
                    charStates.append(slTypewriterCharState(character: String(newChar)))
                    typeNextCharacter()
                }
            } else {
                // 打字完成，等待后开始删除
                DispatchQueue.main.asyncAfter(deadline: .now() + pauseDuration) {
                    isDeleting = true
                    typeNextCharacter()
                }
            }
        }
    }
}

// MARK: - 字符状态

private struct slTypewriterCharState: Identifiable, Equatable {
    let id = UUID()
    var character: String
}

// MARK: - 自定义 Blur Transition

extension AnyTransition {
    static var slBlur: AnyTransition {
        .modifier(
            active: slBlurModifier(radius: 10, opacity: 0),
            identity: slBlurModifier(radius: 0, opacity: 1)
        )
    }
}

private struct slBlurModifier: ViewModifier {
    let radius: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .blur(radius: radius)
            .opacity(opacity)
    }
}

// MARK: - 便捷初始化扩展

extension slTypewriter {
    /// 弹性风格（推荐）
    static func spring(texts: [String]) -> slTypewriter {
        slTypewriter(texts: texts, animationStyle: .spring)
    }

    /// 模糊风格
    static func blur(texts: [String]) -> slTypewriter {
        slTypewriter(texts: texts, animationStyle: .blur)
    }

    /// 缩放风格
    static func scale(texts: [String]) -> slTypewriter {
        slTypewriter(texts: texts, animationStyle: .scale)
    }

    /// 渐入风格
    static func fade(texts: [String]) -> slTypewriter {
        slTypewriter(texts: texts, animationStyle: .fade)
    }
}

// MARK: - Preview

#Preview("Spring Style (Default)") {
    slTypewriter(
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
    slTypewriter(
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

#Preview("Scale Style") {
    slTypewriter(
        texts: [
            "Level up your smile game",
            "AI-powered smile analysis",
            "Join the glow up era"
        ],
        animationStyle: .scale
    )
    .font(.title3.weight(.semibold))
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Fade Style") {
    slTypewriter(
        texts: [
            "Level up your smile game",
            "AI-powered smile analysis",
            "Join the glow up era"
        ],
        animationStyle: .fade
    )
    .font(.title3.weight(.semibold))
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Custom Gradient") {
    slTypewriter(
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

#Preview("White Text") {
    slTypewriter(
        texts: [
            "Simple and clean",
            "Minimalist design",
            "Pure elegance"
        ],
        animationStyle: .fade,
        gradient: LinearGradient(
            colors: [.white],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .font(.headline)
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
