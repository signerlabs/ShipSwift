//
//  SWCameraView.swift
//  ShipSwift
//
//  Camera capture view with photo picker and zoom control.
//  Full-screen camera UI with shutter button, photo library picker,
//  pinch-to-zoom gesture, and zoom slider.
//
//  Usage:
//    // 1. Present as a sheet with a @Binding UIImage
//    @State private var capturedImage: UIImage?
//    @State private var showCamera = false
//
//    Button("Take Photo") { showCamera = true }
//    .fullScreenCover(isPresented: $showCamera) {
//        SWCameraView(image: $capturedImage)
//    }
//
//    // 2. The view auto-dismisses after capture or photo selection.
//    //    The captured/selected image is written to the binding.
//
//    // 3. Features included:
//    //    - Live camera preview
//    //    - Shutter button for photo capture
//    //    - PhotosPicker for selecting from photo library
//    //    - Pinch-to-zoom gesture and zoom slider
//    //    - Front/back camera switching
//    //    - Close button (top-left corner)
//    //    - Unauthorized state with "Open Settings" button
//
//    // 4. Errors are shown via SWAlertManager.shared
//    //    Attach .swAlert() in your root view.
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct SWCameraView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var cameraManager = SWCameraManager()
    @State private var isCapturing = false
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        Group {
            if cameraManager.isAuthorized {
                ZStack {
                    Color.black.ignoresSafeArea()

                    // Camera preview (vertically centered)
                    GeometryReader { geometry in
                        let previewWidth = geometry.size.width
                        let previewHeight = previewWidth * 4 / 3

                        SWCameraPreview(session: cameraManager.session)
                            .frame(width: previewWidth, height: previewHeight)
                            .clipped()
                            .overlay(alignment: .bottom) {
                                zoomControl
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .gesture(pinchGesture)
                    .onAppear {
                        cameraManager.onError = { SWAlertManager.shared.show(.error, message: $0) }
                        cameraManager.startSession()
                    }
                    .onDisappear { cameraManager.stopSession() }

                    // Bottom control bar
                    VStack {
                        Spacer()
                        controlBar
                    }

                    // Top-left close button
                    VStack {
                        HStack {
                            Button { dismiss() } label: {
                                Image(systemName: "xmark")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.black.opacity(0.4), in: Circle())
                            }
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.top, 8)
                        Spacer()
                    }
                }
            } else {
                unauthorizedView
            }
        }
        .background(.black)
        .onChange(of: selectedPhotoItem) {
            Task {
                await loadSelectedPhoto()
            }
        }
    }

    // MARK: - Pinch-to-Zoom Gesture

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let delta = value.magnification / lastScale
                lastScale = value.magnification
                cameraManager.zoom(by: delta)
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }

    // MARK: - Unauthorized View

    private var unauthorizedView: some View {
        VStack(spacing: 20) {
            Label("Camera permission required", systemImage: "camera.fill")
                .foregroundStyle(.regularMaterial)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Zoom Control

    private var zoomControl: some View {
        VStack(spacing: 8) {
            // Current zoom level
            Text(String(format: "%.1fx", cameraManager.currentZoom))
                .font(.system(size: 14, weight: .medium, design: .monospaced))

            // Zoom slider
            HStack(spacing: 12) {
                Text("1x")
                    .font(.caption)

                Slider(
                    value: Binding(
                        get: { cameraManager.currentZoom },
                        set: { cameraManager.setZoom($0) }
                    ),
                    in: cameraManager.minZoom...cameraManager.maxZoom
                )
                .tint(.accent)

                Text(String(format: "%.0fx", cameraManager.maxZoom))
                    .font(.caption)
            }
            .padding(.horizontal, 60)
        }
        .foregroundStyle(.white.opacity(0.7))
        .padding()
    }

    // MARK: - Bottom Control Bar

    private var controlBar: some View {
        HStack(spacing: 50) {
            // Photo library picker
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                controlButton(icon: "photo.on.rectangle")
            }

            // Capture button
            Button {
                capturePhoto()
            } label: {
                shutterButton
            }
            .disabled(!cameraManager.isAuthorized || isCapturing)

            // Switch camera
            Button { cameraManager.switchCamera() } label: {
                controlButton(icon: "camera.rotate.fill")
            }
        }
        .padding(.bottom, 50)
        .padding(.top, 20)
    }

    // MARK: - Control Button Style

    private func controlButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Shutter Button

    private var shutterButton: some View {
        Circle()
            .fill(cameraManager.isAuthorized && !isCapturing ? .white : .gray)
            .frame(width: 70, height: 70)
            .overlay {
                Circle()
                    .strokeBorder(.black.opacity(0.2), lineWidth: 2)
                    .frame(width: 60, height: 60)
            }
            .scaleEffect(isCapturing ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isCapturing)
    }

    // MARK: - Actions

    private func capturePhoto() {
        guard cameraManager.isAuthorized, !isCapturing else { return }

        isCapturing = true
        cameraManager.capturePhoto { photo in
            isCapturing = false
            if let photo {
                image = photo
                dismiss()
            }
        }
    }

    private func loadSelectedPhoto() async {
        guard let item = selectedPhotoItem,
              let data = try? await item.loadTransferable(type: Data.self),
              let selectedImage = UIImage(data: data) else { return }

        image = selectedImage
        dismiss()
    }
}

// MARK: - Camera Preview

struct SWCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> SWPreviewView {
        let view = SWPreviewView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: SWPreviewView, context: Context) {
        if uiView.session != session {
            uiView.session = session
        }
    }
}

class SWPreviewView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session = session else { return }
            videoPreviewLayer.session = session
        }
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }
}

// MARK: - Preview

#Preview("Unauthorized") {
    SWCameraView(image: .constant(nil))
        .swAlert()
        .onAppear {
            SWAlertManager.shared.show(.error, message: "Camera permission denied")
        }
}
