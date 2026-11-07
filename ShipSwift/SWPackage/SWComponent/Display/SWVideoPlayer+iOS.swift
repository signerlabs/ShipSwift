//
//  SWVideoPlayer+iOS.swift
//  ShipSwift
//
//  A video showcase player with a paused first-frame preview + center play
//  button, tap-to-fullscreen playback via AVKit, and orientation callbacks.
//
//  Created by Wei Zhong on 2026/04/14.
//

import SwiftUI
import AVKit

public struct SWVideoPlayer: View {

    // MARK: - Configuration

    public let videoURL: URL
    public var cornerRadius: CGFloat

    /// Invoked when the user taps the play button and fullscreen appears.
    public var onEnterFullscreen: (() -> Void)?

    /// Invoked when the fullscreen player is dismissed.
    public var onExitFullscreen: (() -> Void)?

    // MARK: - State

    /// Created on first appearance rather than in `init` (SwiftUI re-runs `init`
    /// on every parent update), and replaced when `videoURL` changes.
    @State private var player: AVPlayer?
    @State private var showFullscreen = false

    // MARK: - Init

    public init(
        resource: String,
        ext: String = "mp4",
        cornerRadius: CGFloat = 20,
        onEnterFullscreen: (() -> Void)? = nil,
        onExitFullscreen: (() -> Void)? = nil
    ) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            fatalError("SWVideoPlayer: resource \(resource).\(ext) not found in bundle")
        }
        self.videoURL = url
        self.cornerRadius = cornerRadius
        self.onEnterFullscreen = onEnterFullscreen
        self.onExitFullscreen = onExitFullscreen
    }

    public init(
        url: URL,
        cornerRadius: CGFloat = 20,
        onEnterFullscreen: (() -> Void)? = nil,
        onExitFullscreen: (() -> Void)? = nil
    ) {
        self.videoURL = url
        self.cornerRadius = cornerRadius
        self.onEnterFullscreen = onEnterFullscreen
        self.onExitFullscreen = onExitFullscreen
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // AVPlayerLayer paused at time 0 displays the first frame as the poster
            if let player {
                InlineVideoLayerView(player: player)
            }

            // Dimming to make the play button stand out
            Color.black.opacity(0.25)

            // Center play button
            Image(systemName: "play.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showFullscreen = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Play video")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { showFullscreen = true }
        .onAppear {
            if player == nil {
                player = AVPlayer(url: videoURL)
            }
        }
        .onChange(of: videoURL) { _, newURL in
            player = AVPlayer(url: newURL)
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            if let player {
                SWVideoFullscreenPlayer(
                    player: player,
                    isPresented: $showFullscreen,
                    onEnter: onEnterFullscreen,
                    onExit: onExitFullscreen
                )
            }
        }
    }
}

// MARK: - Inline video layer (shows current paused frame as poster)

private struct InlineVideoLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        player.pause()
        // Seek to 0 forces first-frame decode so the layer shows it as poster
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        // A new player (the video URL changed) needs its own first-frame poster
        guard uiView.playerLayer.player !== player else { return }
        uiView.playerLayer.player = player
        player.pause()
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    final class PlayerUIView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

// MARK: - Fullscreen player

private struct SWVideoFullscreenPlayer: View {
    let player: AVPlayer
    @Binding var isPresented: Bool
    let onEnter: (() -> Void)?
    let onExit: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            VideoPlayer(player: player)
                .ignoresSafeArea()

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 8)
            .padding(.trailing, 16)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try? AVAudioSession.sharedInstance().setActive(true)
            onEnter?()
            player.play()
        }
        .onDisappear {
            player.pause()
            onExit?()
        }
    }
}

#Preview {
    if let sampleURL = Bundle.main.url(forResource: "spacex_demo", withExtension: "mp4") {
        ZStack {
            Color.black.ignoresSafeArea()
            SWVideoPlayer(url: sampleURL)
                .aspectRatio(16 / 9, contentMode: .fit)
                .padding()
        }
    } else {
        Text("Add a video to the bundle to preview SWVideoPlayer")
            .foregroundStyle(.secondary)
    }
}
