//
//  SWFullScreenButton+iOS.swift
//  ShipSwift
//
//  Tappable card that expands to fill the device display using Apple's
//  native zoom transition — the same continuous, geometry-matched effect
//  Apple uses for App Store / Photos / Music album-to-detail navigations.
//  The compact card appears to spring into the entire screen rather than
//  sliding up as a generic modal.
//
//  Requires an enclosing `NavigationStack`:
//
//      NavigationStack {
//          SWFullScreenButton()
//      }
//
//  iOS 18+ only. Built on `.matchedTransitionSource(id:in:)` and
//  `.navigationTransition(.zoom(sourceID:in:))`, both introduced in iOS 18.
//
//  Usage:
//    // Zero-config: defaults reproduce the original showcase look
//    SWFullScreenButton()
//
//    // Custom copy
//    SWFullScreenButton(
//        title: "SmileMax",
//        subtitle: "Daily smile analytics",
//        footer: "Open"
//    )
//
//    // Custom palette and shape
//    SWFullScreenButton(
//        gradientColors: [.purple, .pink],
//        cornerRadius: 24
//    )
//
//  Parameters:
//    - title:          String   — Top headline shown in white (default "ShipSwift")
//    - subtitle:       String   — Single-line tagline under the title (default "Fullstack AI toolkit")
//    - footer:         String   — Bottom accent label (default "FullScreenCard")
//    - compactSize:    CGSize   — Frame size in the collapsed state (default 300 x 300)
//    - gradientColors: [Color]  — Background gradient, top to bottom (default [.brown, .white])
//    - cornerRadius:   CGFloat  — Card corner radius in the compact state (default 30)
//
//  Created by Wei Zhong on 12/5/26.
//

import SwiftUI

struct SWFullScreenButton: View {
    var title: String = "ShipSwift"
    var subtitle: String = "Fullstack AI toolkit"
    var footer: String = "FullScreenCard"
    var compactSize: CGSize = CGSize(width: 300, height: 300)
    var gradientColors: [Color] = [.brown, .white]
    var cornerRadius: CGFloat = 30

    @Namespace private var transitionNS
    @State private var shadowRadius: CGFloat = 30

    init(
        title: String = "ShipSwift",
        subtitle: String = "Fullstack AI toolkit",
        footer: String = "FullScreenCard",
        compactSize: CGSize = CGSize(width: 300, height: 300),
        gradientColors: [Color] = [.brown, .white],
        cornerRadius: CGFloat = 30
    ) {
        self.title = title
        self.subtitle = subtitle
        self.footer = footer
        self.compactSize = compactSize
        self.gradientColors = gradientColors
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        NavigationLink {
            SWFullScreenButtonExpandedView(
                title: title,
                subtitle: subtitle,
                footer: footer,
                gradientColors: gradientColors
            )
            .navigationTransition(.zoom(sourceID: "swFullScreenButton", in: transitionNS))
            .onAppear {
                // Source is hidden during the push; drop the shadow so it
                // doesn't pop in after the reverse zoom completes.
                shadowRadius = 0
            }
            .onDisappear {
                // Reverse zoom has finished and the source is visible again
                // — fade the shadow back in to mask the system's snapshot
                // hand-off frame.
                withAnimation(.easeOut(duration: 0.25)) {
                    shadowRadius = 30
                }
            }
        } label: {
            cardContent(expanded: false)
                .frame(width: compactSize.width, height: compactSize.height)
                .background(
                    LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(radius: shadowRadius)
                .matchedTransitionSource(id: "swFullScreenButton", in: transitionNS)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func cardContent(expanded: Bool) -> some View {
        VStack {
            Text(title)
                .foregroundStyle(.white)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, expanded ? 100 : 20)

            Text(subtitle)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Text(footer)
                .foregroundStyle(.accent)
                .brightness(0.1)
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, expanded ? 100 : 20)
        }
        .padding()
    }
}

/// Pushed destination for the zoom transition. Tapping anywhere on the
/// expanded card calls `dismiss()`, which pops the navigation stack and
/// triggers the reverse zoom animation. The standard edge-swipe-back
/// gesture also still works as a system-provided dismiss path.
private struct SWFullScreenButtonExpandedView: View {
    let title: String
    let subtitle: String
    let footer: String
    let gradientColors: [Color]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text(title)
                .foregroundStyle(.white)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 100)

            Text(subtitle)
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Text(footer)
                .foregroundStyle(.accent)
                .brightness(0.1)
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 100)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
        )
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        SWFullScreenButton()
    }
}
