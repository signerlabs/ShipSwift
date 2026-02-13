//
//  SWFaceCameraView.swift
//  ShipSwift
//
//  Face camera view with real-time landmark overlay.
//  Full camera UI with face landmark visualization, photo capture,
//  camera switching, and landmark display toggle.
//
//  Usage:
//    // 1. Basic usage with onCapture callback
//    SWFaceCameraView { capturedImage in
//        // handle the captured UIImage
//        processPhoto(capturedImage)
//    }
//
//    // 2. Custom landmark color scheme
//    SWFaceCameraView(
//        onCapture: { image in handlePhoto(image) },
//        landmarkColors: .mono   // tech-feel cyan monochrome
//    )
//
//    // 3. Available color schemes
//    //    .default — multi-color (cyan lips, green eyes, purple brows, yellow nose)
//    //    .mono    — all cyan with varying opacity (tech feel)
//    //    .warm    — pink lips, orange eyes, red brows, yellow nose
//
//    // 4. Custom color scheme
//    let colors = SWFaceLandmarkColors(
//        lips: .pink.opacity(0.6),
//        eyes: .green.opacity(0.6),
//        eyebrows: .purple.opacity(0.6),
//        nose: .yellow.opacity(0.6),
//        faceContour: .white.opacity(0.2)
//    )
//    SWFaceCameraView(onCapture: { _ in }, landmarkColors: colors)
//
//    // 5. Controls provided:
//    //    - Camera switch button (front/back)
//    //    - Shutter button for photo capture
//    //    - Landmark overlay toggle button
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI
import AVFoundation

// MARK: - Face Recognition Camera View

struct SWFaceCameraView: View {
    /// Photo capture callback
    var onCapture: ((UIImage) -> Void)?

    /// Landmark color scheme
    var landmarkColors: SWFaceLandmarkColors = .default

    @Environment(\.dismiss) private var dismiss
    @State private var cameraManager = SWCameraManager(position: .front)
    @State private var isCapturing = false
    @State private var showLandmarks = true

    var body: some View {
        Group {
            if cameraManager.isAuthorized {
                ZStack {
                    Color.black.ignoresSafeArea()

                    // 相机预览（纵向居中）
                    GeometryReader { geometry in
                        let previewWidth = geometry.size.width
                        let previewHeight = previewWidth * 4 / 3

                        SWFaceCameraPreview(session: cameraManager.session)
                            .frame(width: previewWidth, height: previewHeight)
                            .clipped()
                            .overlay {
                                if showLandmarks {
                                    SWFaceTrackingOverlay(
                                        landmarks: cameraManager.faceLandmarks,
                                        colors: landmarkColors
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .onAppear {
                        cameraManager.faceTrackingEnabled = true
                        cameraManager.startSession()
                    }
                    .onDisappear {
                        cameraManager.faceTrackingEnabled = false
                        cameraManager.stopSession()
                    }

                    // 底部控制栏
                    VStack {
                        Spacer()
                        controlBar
                    }

                    // 左上角关闭按钮
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

    // MARK: - Bottom Control Bar

    private var controlBar: some View {
        VStack {
            HStack(spacing: 50) {
                // 翻转镜头
                Button {
                    cameraManager.switchCamera()
                } label: {
                    controlButton(icon: "camera.rotate.fill")
                }

                // 快门按钮（和 SWCameraView 一致）
                Button {
                    capturePhoto()
                } label: {
                    shutterButton
                }
                .disabled(!cameraManager.isAuthorized || isCapturing)

                // 人脸标记开关
                Button {
                    showLandmarks.toggle()
                } label: {
                    controlButton(icon: showLandmarks ? "face.dashed.fill" : "face.dashed")
                }
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

    // MARK: - Photo Capture

    private func capturePhoto() {
        guard cameraManager.isAuthorized, !isCapturing else { return }

        isCapturing = true
        cameraManager.capturePhoto { photo in
            isCapturing = false
            if let photo {
                onCapture?(photo)
            }
        }
    }
}

// MARK: - Camera Preview

struct SWFaceCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> SWFacePreviewView {
        let view = SWFacePreviewView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: SWFacePreviewView, context: Context) {
        if uiView.session != session {
            uiView.session = session
        }
    }
}

final class SWFacePreviewView: UIView {
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

// MARK: - Face Landmark Real-time Rendering

struct SWFaceTrackingOverlay: View {
    let landmarks: [SWFaceLandmarkGroup]
    var colors: SWFaceLandmarkColors = .default

    var body: some View {
        Canvas { context, size in
            for group in landmarks {
                guard !group.points.isEmpty else { continue }

                let color = colors.color(for: group.region)
                let mapped = group.points.map {
                    CGPoint(x: $0.x * size.width, y: $0.y * size.height)
                }

                // Pupils and other few-point regions only draw dots, not paths
                if group.isClosed {
                    var path = Path()
                    path.addLines(mapped)
                    path.closeSubpath()

                    // Lip regions have semi-transparent fill
                    if group.region == .outerLips || group.region == .innerLips {
                        context.fill(path, with: .color(color.opacity(0.08)))
                    }
                    context.stroke(path, with: .color(color.opacity(0.8)), lineWidth: 1.5)
                }

                // Each point
                let dotSize: CGFloat = group.region == .leftPupil || group.region == .rightPupil ? 5 : 3
                for point in mapped {
                    let rect = CGRect(x: point.x - dotSize / 2, y: point.y - dotSize / 2,
                                      width: dotSize, height: dotSize)
                    context.fill(Circle().path(in: rect), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Landmark Color Scheme

struct SWFaceLandmarkColors {
    var lips: Color
    var eyes: Color
    var eyebrows: Color
    var nose: Color
    var faceContour: Color

    func color(for region: SWFaceLandmarkRegion) -> Color {
        switch region {
        case .outerLips, .innerLips:         return lips
        case .leftEye, .rightEye:            return eyes
        case .leftPupil, .rightPupil:        return eyes
        case .leftEyebrow, .rightEyebrow:    return eyebrows
        case .nose, .noseCrest:              return nose
        case .faceContour:                   return faceContour
        }
    }

    /// Default color scheme
    static let `default` = SWFaceLandmarkColors(
        lips: .cyan.opacity(0.6),
        eyes: .green.opacity(0.6),
        eyebrows: .purple.opacity(0.6),
        nose: .yellow.opacity(0.6),
        faceContour: .white.opacity(0.2)
    )

    /// Monochrome scheme (tech feel)
    static let mono = SWFaceLandmarkColors(
        lips: .cyan.opacity(0.7),
        eyes: .cyan.opacity(0.5),
        eyebrows: .cyan.opacity(0.4),
        nose: .cyan.opacity(0.5),
        faceContour: .cyan.opacity(0.15)
    )

    /// Warm color scheme
    static let warm = SWFaceLandmarkColors(
        lips: .pink.opacity(0.6),
        eyes: .orange.opacity(0.6),
        eyebrows: .red.opacity(0.5),
        nose: .yellow.opacity(0.6),
        faceContour: .white.opacity(0.15)
    )
}

// MARK: - Preview

#Preview {
    SWFaceCameraView()
}
