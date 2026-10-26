//
//  SWSubjectLiftingManager.swift
//  ShipSwift
//
//  Subject lifting (background removal) manager using VisionKit's
//  ImageAnalyzer and ImageAnalysisInteraction.
//
//  Analyzes a UIImage, detects the primary subject, and returns
//  a background-removed PNG image.
//
//  Requirements: iOS 18+, VisionKit framework.
//
//  Usage:
//    @State private var manager = SWSubjectLiftingManager()
//
//    // Wire up error callback
//    manager.onError = { message in print(message) }
//
//    // Process an image
//    let result = await manager.processImage(photo)
//    if let result {
//        let extractedImage = result.image  // UIImage with background removed
//        let pngData = result.data          // PNG Data
//    }
//
//    // Check processing state
//    switch manager.processingState {
//    case .idle: // Ready
//    case .processing: // Working
//    case .completed: // Done — result available
//    case .failed: // Error occurred
//    }
//
//    // Cleanup when done
//    manager.cleanup()
//
//  Created by Wei Zhong on 3/8/26.
//

import VisionKit
import SwiftUI

// MARK: - Extracted Result

/// Result of a subject lifting operation containing the extracted image and its PNG data.
struct SWExtractedResult {
    let image: UIImage
    let data: Data
}

// MARK: - Manager

@MainActor
@Observable
final class SWSubjectLiftingManager {

    // MARK: - Processing State

    enum ProcessingState: Equatable {
        case idle
        case processing
        case failed
        case completed
    }

    // MARK: - Public Properties

    var processingState: ProcessingState = .idle

    /// Original image before extraction (set immediately on processImage call)
    var originalImage: UIImage?

    /// Extracted subject image with background removed
    var extractedImage: UIImage?

    /// Error callback — wire this up in the view layer for alert display
    var onError: ((String) -> Void)?

    // MARK: - Private Properties

    private let analyzer = ImageAnalyzer()
    private let configuration = ImageAnalyzer.Configuration(.visualLookUp)
    private var interaction: ImageAnalysisInteraction

    // MARK: - Initialization

    init() {
        let interaction = ImageAnalysisInteraction()
        interaction.preferredInteractionTypes = .imageSubject
        self.interaction = interaction
    }

    // MARK: - Public API

    /// Analyze an image and extract the primary subject with background removed.
    ///
    /// Returns an `SWExtractedResult` on success, or `nil` on failure.
    /// Updates `processingState`, `originalImage`, and `extractedImage` throughout.
    @discardableResult
    func processImage(_ image: UIImage) async -> SWExtractedResult? {
        originalImage = image
        extractedImage = nil
        processingState = .processing

        do {
            // Analyze the image for visual lookup subjects
            let analysis = try await analyzer.analyze(image, configuration: configuration)
            interaction.analysis = analysis

            // Get detected subjects
            let subjects = await interaction.subjects
            guard let firstSubject = subjects.first else {
                processingState = .failed
                onError?(String(localized: "No subject detected in the image"))
                scheduleReset(after: 3)
                return nil
            }

            // Extract the subject image (background removed)
            let subjectImage = try await firstSubject.image

            guard let pngData = subjectImage.pngData() else {
                processingState = .failed
                onError?(String(localized: "Failed to convert extracted image"))
                scheduleReset(after: 3)
                return nil
            }

            let result = SWExtractedResult(image: subjectImage, data: pngData)
            extractedImage = subjectImage
            processingState = .completed

            return result

        } catch {
            processingState = .failed
            onError?(String(localized: "Subject extraction failed"))
            scheduleReset(after: 3)
            return nil
        }
    }

    /// Reset manager to idle state and release image references.
    func cleanup() {
        interaction.analysis = nil
        processingState = .idle
        originalImage = nil
        extractedImage = nil
    }

    // MARK: - Private Helpers

    /// Auto-reset to idle after a delay (for failed/completed states).
    private func scheduleReset(after seconds: Int) {
        Task {
            try? await Task.sleep(for: .seconds(seconds))
            if processingState == .failed {
                processingState = .idle
                originalImage = nil
            }
        }
    }
}
