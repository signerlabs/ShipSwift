//
//  slCameraView.swift
//  full-pack
//
//  Created by Wei on 2025/5/20.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct slCameraView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var cameraManager = slCameraManager()
    @State private var isCapturing = false

    var body: some View {
        Group {
            if cameraManager.isAuthorized {
                ZStack {
                    CameraPreview(session: cameraManager.session)
                        .ignoresSafeArea()
                        .onAppear { cameraManager.startSession() }
                        .onDisappear { cameraManager.stopSession() }

                    // 取景框和提示文字
                    viewfinderOverlay

                    VStack {
                        Spacer()
                        controlBar
                    }
                }
            } else {
                unauthorizedView
            }
        }
        .background(.black.opacity(0.9))
        .onChange(of: selectedPhotoItem) {
            Task {
                await loadSelectedPhoto()
            }
        }
    }

    // MARK: - 未授权视图
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

    // MARK: - 取景框和提示
    private var viewfinderOverlay: some View {
        VStack(spacing: 0) {
            // 顶部提示文字
            VStack(spacing: 8) {
                Text("Place item in the frame.")
                    .font(.headline)

                HStack(spacing: 16) {
                    Label("Centered", systemImage: "scope")
                    Label("Bright", systemImage: "sun.max")
                    Label("Clear", systemImage: "eye")
                }
                .font(.caption)
            }
            .foregroundStyle(.ultraThickMaterial)
            .padding(.top, 60)
            .padding(.bottom, 20)

            Spacer()

            // 取景框
            viewfinderFrame
                .frame(width: 280, height: 280)

            Spacer()

            // 底部提示
            Text("For best results, use a plain background.")
                .font(.caption)
                .foregroundStyle(.ultraThickMaterial)
                .padding(.bottom, 160)
        }
    }

    // MARK: - 取景框
    private var viewfinderFrame: some View {
        ZStack {
            // 四个角的装饰线
            GeometryReader { geo in
                let cornerLength: CGFloat = 30
                let lineWidth: CGFloat = 3
                let color = Color.white

                // 左上角
                Path { path in
                    path.move(to: CGPoint(x: 0, y: cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cornerLength, y: 0))
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // 右上角
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width - cornerLength, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width, y: cornerLength))
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // 左下角
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height - cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                    path.addLine(to: CGPoint(x: cornerLength, y: geo.size.height))
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // 右下角
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width - cornerLength, y: geo.size.height))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - cornerLength))
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
    }

    // MARK: - 底部控制栏
    private var controlBar: some View {
        HStack(spacing: 50) {
            // 相册按钮
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                controlButton(icon: "photo.on.rectangle")
            }

            // 拍照按钮
            Button {
                capturePhoto()
            } label: {
                shutterButton
            }
            .disabled(!cameraManager.isAuthorized || isCapturing)

            // 关闭按钮
            Button { dismiss() } label: {
                controlButton(icon: "xmark")
            }
        }
        .padding(.bottom, 50)
        .padding(.top, 20)
    }

    // MARK: - 控制按钮样式
    private func controlButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 快门按钮
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
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // 确保 session 是最新的
        if uiView.session != session {
            uiView.session = session
        }
    }
}

class PreviewView: UIView {
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
        videoPreviewLayer.videoGravity = .resizeAspect
    }
}

// MARK: - Preview

#Preview("Unauthorized") {
    slCameraView(image: .constant(nil))
        .slAlert()
        .onAppear {
            slAlertManager.shared.show(.error, message: String(localized: "Camera permission denied. Please enable in Settings"))
        }
}

#Preview("Camera Error") {
    slCameraView(image: .constant(nil))
        .slAlert()
        .onAppear {
            slAlertManager.shared.show(.error, message: String(localized: "Unable to access rear camera"))
        }
}

#Preview("Capture Failed") {
    slCameraView(image: .constant(nil))
        .slAlert()
        .onAppear {
            slAlertManager.shared.show(.error, message: String(localized: "Photo capture failed"))
        }
}
