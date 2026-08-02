//
//  ComponentListShared.swift
//  ShipSwift
//
//  Shared helpers for the category list views (Modules / Animation /
//  Charts / UI): the tab-bar-hiding navigation link used by every
//  component entry, plus the camera / face-camera / chat demo wrappers.
//
//  Created by Wei Zhong on 2/8/26.
//

import SwiftUI

// MARK: - Tab Bar Hiding

/// Hides the tab bar when a view is pushed via NavigationLink on iOS.
/// No-op on macOS where tab bars don't exist.
extension View {
    @ViewBuilder func hideTabBar() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .tabBar)
        #else
        self
        #endif
    }
}

// MARK: - Component Navigation Link

/// Drop-in replacement for `NavigationLink { destination } label: { … }` that
/// automatically hides the floating tab bar when the destination is pushed.
///
/// Convention for this showcase: every component preview is a subpage of the
/// root tab — the tab bar should only be visible on top-level tabs, never on
/// pushed component previews. Using this wrapper instead of `NavigationLink`
/// makes that the default; no per-call `.hideTabBar()` needed.
struct ComponentNavigationLink<Label: View, Destination: View>: View {
    @ViewBuilder let destination: () -> Destination
    @ViewBuilder let label: () -> Label

    var body: some View {
        NavigationLink {
            destination()
                .hideTabBar()
        } label: {
            label()
        }
    }
}

// MARK: - Camera Demo View (Real Camera, No Processing)

#if os(iOS)
/// Demo using real SWCameraView — captured or selected photos are not processed or saved.
struct ComponentViewCameraDemo: View {
    @State private var capturedImage: UIImage?

    var body: some View {
        SWCameraView(image: $capturedImage)
            .swAlert()
    }
}

// MARK: - Face Camera Demo View (Real Camera with Face Tracking)

/// SWFaceCameraView includes its own close button — present it directly.
struct ComponentViewFaceCameraDemo: View {
    var body: some View {
        SWFaceCameraView()
    }
}

// MARK: - Chat Demo View (SWChatView with Simulated Response)

/// Demo showcasing SWChatView with a simulated echo-style AI response.
/// No ASR config is provided so the microphone button is hidden in demo mode.
struct ComponentViewChatDemo: View {
    @State private var messages: [SWChatMessage] = [
        SWChatMessage(
            content: "Welcome! Send a message to see the demo response.",
            isUser: false
        ),
    ]
    @State private var isWaiting = false

    var body: some View {
        SWChatView(
            messages: $messages,
            isDisabled: isWaiting
        ) { text in
            // Simulate AI response with a 1-second delay
            isWaiting = true
            Task {
                try? await Task.sleep(for: .seconds(1))
                messages.append(
                    SWChatMessage(
                        content: "This is a demo response. The SWChat module ships with message bubbles, text input, and voice waveform UI.",
                        isUser: false
                    )
                )
                isWaiting = false
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
