//
//  SWFaceCameraView.swift
//  ShipSwift
//
//  Face recognition camera view
//  Real-time rendering of Vision face landmarks (eyes, eyebrows, nose, lips, face contour, pupils)
//  Supports front/rear camera switching + landmark display toggle + photo capture
//
//  Usage:
//    SWFaceCameraView(
//        onCapture: { image in
//            // Handle captured photo
//        },
//        landmarkColors: .default   // Customizable color scheme
//    )
//

import SwiftUI
import AVFoundation

// MARK: - Face Recognition Camera View

struct SWFaceCameraView: View {
    /// Photo capture callback
    var onCapture: ((UIImage) -> Void)?

    /// Landmark color scheme
    var landmarkColors: SWFaceLandmarkColors = .default

    @State private var cameraManager = SWFaceCameraManager(position: .front)
    @State private var isCapturing = false
    @State private var showLandmarks = true

    var body: some View {
        VStack(spacing: 0) {
            if cameraManager.isAuthorized {
                Spacer()

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

                Spacer()
            } else {
                ContentUnavailableView(
                    "Camera Access Required",
                    systemImage: "camera.fill",
                    description: Text("Please enable camera access in Settings")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Bottom control bar
            controlBar
        }
    }

    // MARK: - Bottom Control Bar

    private var controlBar: some View {
        VStack {
            Text("Smile and show your teeth")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()

            HStack(spacing: 60) {
                // Switch camera
                Button {
                    cameraManager.switchCamera()
                } label: {
                    Image(systemName: "camera.rotate.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                }

                // Capture button
                Button {
                    capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(.white, lineWidth: 4)
                            .frame(width: 75, height: 75)

                        Circle()
                            .fill(.white)
                            .frame(width: 60, height: 60)
                            .scaleEffect(isCapturing ? 0.85 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: isCapturing)
                    }
                }
                .disabled(!cameraManager.isAuthorized || isCapturing)

                // Landmark display toggle
                Button {
                    showLandmarks.toggle()
                } label: {
                    Image(systemName: showLandmarks ? "face.dashed.fill" : "face.dashed")
                        .font(.title)
                        .foregroundStyle(showLandmarks ? .cyan : .white.opacity(0.4))
                        .frame(width: 50, height: 50)
                }
            }
        }
        .padding(.bottom)
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
