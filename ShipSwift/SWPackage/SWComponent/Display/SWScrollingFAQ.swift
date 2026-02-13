//
//  SWScrollingFAQ.swift
//  ShipSwift
//
//  Auto-scrolling horizontal FAQ carousel that displays rows of
//  question pills scrolling in alternating directions (left, right, left).
//  Uses UIScrollView with a CADisplayLink for smooth infinite looping.
//  Tapping a pill triggers the onTap callback with the question text.
//
//  Usage:
//    SWScrollingFAQ(
//        rows: [
//            ["How does AI work?", "What can I ask?", "How accurate?", "Help with coding?",
//             "Remember chat?", "Languages supported?", "Get started?", "Explain topics?"],
//            ["Write an email", "Summarize article", "Translate text", "Creative ideas",
//             "Debug code", "Explain concept", "Meal plan", "Brainstorm"],
//            ["Best approach?", "How to improve?", "Give examples", "Compare options",
//             "Suggest alternatives", "Pros and cons?", "Help understand", "Walk through"]
//        ],
//        title: "Let's talk about new topics"   // optional, nil hides the title
//    ) { question in
//        print("User tapped: \(question)")
//    }
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI

struct SWScrollingFAQ: View {

    // MARK: - Configuration

    /// FAQ data organized by rows. Each inner array is displayed as one scrolling row.
    let rows: [[String]]

    /// Optional title displayed above the scrolling rows
    var title: String? = nil

    /// Callback when a question pill is tapped
    var onTap: (String) -> Void

    // MARK: - Internal

    private enum Direction { case left, right }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            if let title {
                Text(title)
                    .padding(8)
                    .font(.headline)
            }

            Group {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    InfiniteScrollView(
                        questions: row,
                        direction: index % 2 == 0 ? .left : .right,
                        onTap: onTap
                    )
                    .frame(height: 34)
                }
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.08),
                        .init(color: .black, location: 0.92),
                        .init(color: .clear, location: 1.0),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
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
                        .buttonStyle(.bordered)
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
}

// MARK: - Preview

#Preview {
    SWScrollingFAQ(
        rows: [
            ["How does AI work?", "What can I ask?", "How accurate?", "Help with coding?",
             "Remember chat?", "Languages supported?", "Get started?", "Explain topics?"],
            ["Write an email", "Summarize article", "Translate text", "Creative ideas",
             "Debug code", "Explain concept", "Meal plan", "Brainstorm"],
            ["Best approach?", "How to improve?", "Give examples", "Compare options",
             "Suggest alternatives", "Pros and cons?", "Help understand", "Walk through"]
        ],
        title: "Let's talk about new topics"
    ) { question in
        print("Tapped: \(question)")
    }
}
