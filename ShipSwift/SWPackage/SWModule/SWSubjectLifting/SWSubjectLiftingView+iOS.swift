//
//  SWSubjectLiftingView+iOS.swift
//  ShipSwift
//
//  Demo view showcasing subject lifting (background removal).
//  Provides camera capture and photo library picking, then
//  extracts the primary subject from the selected image.
//
//  Usage:
//    // Present as a full-screen cover or push destination
//    SWSubjectLiftingView()
//
//  Created by Wei Zhong on 3/8/26.
//

import SwiftUI
import PhotosUI

struct SWSubjectLiftingView: View {
    @State private var manager = SWSubjectLiftingManager()

    // Image source
    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                // Result display area
                resultArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Action buttons
                actionButtons
                    .padding(.bottom, 32)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Subject Lifting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Reset button when there's a result
            if manager.extractedImage != nil || manager.originalImage != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        withAnimation {
                            manager.cleanup()
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            // SWCameraView has no close button of its own: host it in a NavigationStack with one
            NavigationStack {
                SWCameraView(image: Binding(
                    get: { nil },
                    set: { image in
                        guard let image else { return }
                        Task { await manager.processImage(image) }
                    }
                ))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showCamera = false }
                    }
                }
            }
        }
        .onChange(of: selectedPhotoItem) {
            Task {
                await loadSelectedPhoto()
            }
        }
    }

    // MARK: - Result Area

    @ViewBuilder
    private var resultArea: some View {
        switch manager.processingState {
        case .idle:
            // Empty state — prompt user to pick or capture
            VStack(spacing: 16) {
                Image(systemName: "person.crop.rectangle.badge.plus")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text("Select or capture a photo to extract the subject")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

        case .processing:
            VStack(spacing: 16) {
                if let original = manager.originalImage {
                    Image(uiImage: original)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.black.opacity(0.3))
                        }
                        .overlay {
                            ProgressView()
                                .controlSize(.large)
                                .tint(.white)
                        }
                }
                Text("Extracting subject...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

        case .completed:
            VStack(spacing: 16) {
                if let extracted = manager.extractedImage {
                    Image(uiImage: extracted)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                Text("Subject extracted successfully")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }

        case .failed:
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                Text("Could not extract subject")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Camera button
            Button {
                showCamera = true
            } label: {
                Label("Camera", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(manager.processingState == .processing)

            // Photo library picker
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Library", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .disabled(manager.processingState == .processing)
        }
    }

    // MARK: - Photo Loading

    private func loadSelectedPhoto() async {
        guard let item = selectedPhotoItem,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        selectedPhotoItem = nil
        await manager.processImage(image)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SWSubjectLiftingView()
    }
}

