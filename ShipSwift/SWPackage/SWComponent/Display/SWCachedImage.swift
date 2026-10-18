//
//  SWCachedImage.swift
//  ShipSwift
//
//  Drop-in replacement for AsyncImage backed by a memory + disk cache, so
//  remote images (avatars, covers, photos) never flash their placeholder when
//  a view is re-created.
//
//  Why not AsyncImage:
//    AsyncImage keeps no in-memory cache. Whenever its view identity is
//    re-created (a ForEach id that changes, a parent re-rendering under a 1 Hz
//    countdown, a lazy stack scrolling back, a card flip) it starts over from
//    the empty phase: the placeholder shows for at least one frame, then the
//    image reloads. A row of avatars rebuilt once per second flickers between
//    photo and placeholder, which users report as a bug.
//
//  How it works:
//    * Memory: decoded CGImages live in an NSCache priced by byte size. The
//      view looks its URL up synchronously while it is being built, so a
//      cached image is on screen in the very first frame.
//    * Disk: a dedicated URLCache (Caches/SWImageCache) with
//      `.returnCacheDataElseLoad`; relaunches read from disk, not the network.
//      URLs are treated as immutable: a new upload must get a new URL.
//    * One request per URL at a time, shared by every view that asks for it.
//    * 404 / 410 are remembered for the session; network errors are not, so
//      the next appearance retries.
//    * Decoding runs off the main thread through ImageIO (EXIF orientation
//      applied, longest side capped at `maxPixelSize`).
//    * Cross-platform: caches CGImage and renders with Image(decorative:scale:),
//      so the same file builds for iOS and macOS.
//
//  Usage:
//    // Same shape as AsyncImage(url:content:placeholder:)
//    SWCachedImage(url: user.avatarURL) { image in
//        image.resizable().scaledToFill()
//    } placeholder: {
//        Circle().fill(.quaternary)
//    }
//    .frame(width: 40, height: 40)
//    .clipShape(Circle())
//
//    // Warm the cache before a screen appears (optional)
//    Task { _ = await SWImageCache.shared.image(for: url) }
//
//  Parameters:
//    - url: URL?                       -- nil shows the placeholder
//    - scale: CGFloat                  -- Pixels per point, as in AsyncImage (default 1)
//    - content: (Image) -> Content     -- Builds the view for the loaded image
//    - placeholder: () -> Placeholder  -- Shown with no URL, while loading, and after a failure
//
//  Created by Wei Zhong on 10/18/26.
//

import SwiftUI
import ImageIO

// MARK: - SWCachedImage

struct SWCachedImage<Content: View, Placeholder: View>: View {
    // MARK: - Properties

    let url: URL?

    /// Pixels per point of the loaded image, matching AsyncImage's `scale`.
    var scale: CGFloat = 1

    @ViewBuilder var content: (Image) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    /// The loaded image paired with its URL; a different URL ignores it.
    /// Holding it here keeps the image on screen even if the memory cache evicts it.
    @State private var loaded: (url: URL, image: CGImage)?

    /// The image for the current URL: the one this view loaded, or one already in
    /// memory (looked up synchronously, so a re-created view shows it on its first frame).
    private var cgImage: CGImage? {
        guard let url else { return nil }
        if let loaded, loaded.url == url { return loaded.image }
        return SWImageCache.shared.cached(url)
    }

    // MARK: - Body

    var body: some View {
        picture
            .task(id: url) {
                guard let url, loaded?.url != url else { return }
                // A cancelled task means the URL changed or the view went away: drop the result
                if let image = await SWImageCache.shared.image(for: url), !Task.isCancelled {
                    loaded = (url, image)
                }
            }
    }

    @ViewBuilder
    private var picture: some View {
        if let cgImage {
            content(Image(decorative: cgImage, scale: scale))
        } else {
            placeholder()
        }
    }
}

// MARK: - SWImageCache

/// Memory + disk cache behind SWCachedImage. State lives on the main actor;
/// downloads run in URLSession and decoding runs on a background task.
@MainActor
final class SWImageCache {
    static let shared = SWImageCache()

    /// Decoded images priced by byte size; the system also purges them under memory pressure.
    private let memory = NSCache<NSURL, CGImage>()
    /// In-flight requests, so every view asking for the same URL shares one download.
    private var inflight: [URL: Task<CGImage?, Never>] = [:]
    /// URLs the server confirmed missing (404 / 410); not requested again this session.
    private var missing: Set<URL> = []
    private let session: URLSession
    /// Longest side after decoding; larger images are downsampled to bound memory.
    private let maxPixelSize: Int

    init(memoryLimit: Int = 200 * 1024 * 1024,
         diskLimit: Int = 200 * 1024 * 1024,
         directoryName: String = "SWImageCache",
         maxPixelSize: Int = 2400) {
        memory.totalCostLimit = memoryLimit
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 0, diskCapacity: diskLimit,
                                   directory: caches.appendingPathComponent(directoryName, isDirectory: true))
        // URLs are immutable, so a cached response is used as-is (offline included)
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
        self.maxPixelSize = maxPixelSize
    }

    /// The decoded image if it is in memory. Synchronous, safe to call while building a view.
    func cached(_ url: URL) -> CGImage? {
        memory.object(forKey: url as NSURL)
    }

    /// Memory, then disk, then network. Returns nil on failure; the caller shows its placeholder.
    func image(for url: URL) async -> CGImage? {
        if let hit = cached(url) { return hit }
        if missing.contains(url) { return nil }
        if let running = inflight[url] { return await running.value }
        let task = Task<CGImage?, Never> {
            defer { inflight[url] = nil }
            guard let (data, response) = try? await session.data(from: url) else { return nil }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == 200 else {
                if status == 404 || status == 410 { missing.insert(url) }
                return nil
            }
            let maxPixelSize = maxPixelSize
            let decoded = await Task.detached(priority: .userInitiated) {
                Self.decode(data, maxPixelSize: maxPixelSize)
            }.value
            guard let decoded else { return nil }
            memory.setObject(decoded, forKey: url as NSURL, cost: decoded.bytesPerRow * decoded.height)
            return decoded
        }
        inflight[url] = task
        return await task.value
    }

    /// Decodes into a ready-to-draw bitmap with ImageIO (EXIF orientation applied,
    /// downsampled to `maxPixelSize`), so the first frame on screen does no JPEG work.
    private nonisolated static func decode(_ data: Data, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Loads once; scrolling away and back, or re-creating the view, shows it instantly
        SWCachedImage(url: URL(string: "https://picsum.photos/id/64/400/400")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.secondary.opacity(0.2)
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())

        // No URL: the placeholder stays
        SWCachedImage(url: nil) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .foregroundStyle(.secondary)
        }
        .frame(width: 60, height: 60)
    }
    .padding()
}
