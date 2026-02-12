//
//  SWScrollingFAQ.swift
//  ShipSwift
//
//  Horizontally scrolling FAQ suggestion component
//  Displays rows of infinitely scrolling question buttons that users can tap.
//

import SwiftUI

struct SWScrollingFAQ: View {
    var onTap: (String) -> Void

    private enum Direction { case left, right }

    var body: some View {
        VStack(spacing: 8) {
            Text("Let's talk about new topics")
                .padding(8)
                .font(.headline)

            Group {
                InfiniteScrollView(questions: Array(faqData[0..<8]),
                                   direction: .left,
                                   onTap: onTap)
                .frame(height: 34)
                InfiniteScrollView(questions: Array(faqData[8..<16]),
                                   direction: .right,
                                   onTap: onTap)
                .frame(height: 34)
                InfiniteScrollView(questions: Array(faqData[16..<24]),
                                   direction: .left,
                                   onTap: onTap)
                .frame(height: 34)
            }
            .overlay(alignment: .leading) {
                LinearGradient(
                    colors: [.white.opacity(0.4), .clear, .clear, .clear, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .allowsHitTesting(false)
            }
            .overlay(alignment: .trailing) {
                LinearGradient(
                    colors: [.white.opacity(0.4), .clear, .clear, .clear, .clear],
                    startPoint: .trailing,
                    endPoint: .leading
                )
                .allowsHitTesting(false)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Infinite Scroll

    private struct InfiniteScrollView: UIViewRepresentable {
        let questions: [String]
        let direction: Direction
        var onTap: (String) -> Void

        func makeUIView(context: Context) -> UIScrollView {
            let scrollView = UIScrollView()
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.isScrollEnabled = false

            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 0
            stackView.alignment = .center
            stackView.distribution = .equalSpacing

            // Create 3 copies for seamless looping
            for _ in 0..<3 {
                for question in questions {
                    let button = Button(question) { onTap(question) }
                        .font(.subheadline)
                        .buttonStyle(.borderedProminent)
                    let host = UIHostingController(rootView: button)
                    host.view.backgroundColor = .clear
                    host.safeAreaRegions = []
                    host.view.setContentHuggingPriority(.required, for: .horizontal)
                    host.view.setContentCompressionResistancePriority(.required, for: .horizontal)
                    let size = host.sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 34))
                    host.view.frame = CGRect(origin: .zero, size: size)
                    stackView.addArrangedSubview(host.view)
                }
            }

            scrollView.addSubview(stackView)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ])

            context.coordinator.scrollView = scrollView
            context.coordinator.stackView = stackView
            context.coordinator.direction = direction

            return scrollView
        }

        func updateUIView(_ uiView: UIScrollView, context: Context) {
            DispatchQueue.main.async {
                context.coordinator.startIfNeeded()
            }
        }

        func makeCoordinator() -> Coordinator { Coordinator() }

        class Coordinator {
            weak var scrollView: UIScrollView?
            weak var stackView: UIStackView?
            var direction: Direction = .left

            private var displayLink: CADisplayLink?
            private var unitWidth: CGFloat = 0
            private var started = false

            func startIfNeeded() {
                guard !started, let scrollView, let stackView else { return }

                stackView.layoutIfNeeded()
                let totalWidth = stackView.bounds.width
                guard totalWidth > 0 else { return }

                unitWidth = totalWidth / 3
                scrollView.contentSize = CGSize(width: totalWidth, height: stackView.bounds.height)

                // Start from the middle copy so there's room in both directions
                scrollView.contentOffset.x = unitWidth

                started = true
                displayLink = CADisplayLink(target: self, selector: #selector(tick))
                displayLink?.add(to: .main, forMode: .common)
            }

            @objc private func tick() {
                guard let scrollView, unitWidth > 0 else { return }

                let speed: CGFloat = 30 / 60.0
                var x = scrollView.contentOffset.x

                if direction == .left {
                    x += speed
                    if x >= unitWidth * 2 {
                        x -= unitWidth
                    }
                } else {
                    x -= speed
                    if x <= 0 {
                        x += unitWidth
                    }
                }

                scrollView.contentOffset.x = x
            }

            deinit {
                displayLink?.invalidate()
            }
        }
    }

    // MARK: - FAQ Data

    private let faqData: [String] = [
        // Row 1 (0-7)
        "How does AI assistance work?", "What can I ask you?", "How accurate are the answers?", "Can you help with coding?",
        "Do you remember our chat?", "What languages do you support?", "How do I get started?", "Can you explain complex topics?",
        // Row 2 (8-15)
        "Help me write an email", "Summarize this article", "Translate this text", "Generate creative ideas",
        "Debug my code", "Explain this concept", "Create a meal plan", "Help me brainstorm",
        // Row 3 (16-23)
        "What's the best approach?", "How can I improve this?", "Give me examples", "Compare these options",
        "Suggest alternatives", "What are the pros and cons?", "Help me understand", "Walk me through this"
    ]
}

#Preview {
    SWScrollingFAQ { question in
        print("Tapped: \(question)")
    }
}
