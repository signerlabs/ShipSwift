//
//  slFaceCameraView.swift
//  ShipSwift
//
//  面部识别相机视图
//  实时渲染 Vision 面部地标（眼睛、眉毛、鼻子、嘴唇、脸部轮廓、瞳孔）
//  支持前后摄像头切换 + 地标显示开关 + 拍照
//
//  使用方法:
//    slFaceCameraView(
//        onCapture: { image in
//            // 处理拍摄的照片
//        },
//        landmarkColors: .default   // 可自定义颜色方案
//    )
//

import SwiftUI
import AVFoundation

// MARK: - 面部识别相机视图

struct slFaceCameraView: View {
    /// 拍照回调
    var onCapture: ((UIImage) -> Void)?

    /// 地标颜色方案
    var landmarkColors: slFaceLandmarkColors = .default

    @State private var cameraManager = slFaceCameraManager(position: .front)
    @State private var isCapturing = false
    @State private var showLandmarks = true

    var body: some View {
        VStack(spacing: 0) {
            if cameraManager.isAuthorized {
                Spacer()

                GeometryReader { geometry in
                    let previewWidth = geometry.size.width
                    let previewHeight = previewWidth * 4 / 3

                    slFaceCameraPreview(session: cameraManager.session)
                        .frame(width: previewWidth, height: previewHeight)
                        .clipped()
                        .overlay {
                            if showLandmarks {
                                slFaceTrackingOverlay(
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

            // 底部控制栏
            controlBar
        }
    }

    // MARK: - 底部控制栏

    private var controlBar: some View {
        VStack {
            Text("Smile and show your teeth")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding()

            HStack(spacing: 60) {
                // 切换摄像头
                Button {
                    cameraManager.switchCamera()
                } label: {
                    Image(systemName: "camera.rotate.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                }

                // 拍照按钮
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

                // 地标显示开关
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

    // MARK: - 拍照

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

struct slFaceCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> slFacePreviewView {
        let view = slFacePreviewView()
        view.session = session
        return view
    }

    func updateUIView(_ uiView: slFacePreviewView, context: Context) {
        if uiView.session != session {
            uiView.session = session
        }
    }
}

final class slFacePreviewView: UIView {
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

// MARK: - 面部地标实时渲染

struct slFaceTrackingOverlay: View {
    let landmarks: [slFaceLandmarkGroup]
    var colors: slFaceLandmarkColors = .default

    var body: some View {
        Canvas { context, size in
            for group in landmarks {
                guard !group.points.isEmpty else { continue }

                let color = colors.color(for: group.region)
                let mapped = group.points.map {
                    CGPoint(x: $0.x * size.width, y: $0.y * size.height)
                }

                // 瞳孔等少量点只画点，不画路径
                if group.isClosed {
                    var path = Path()
                    path.addLines(mapped)
                    path.closeSubpath()

                    // 嘴唇区域有半透明填充
                    if group.region == .outerLips || group.region == .innerLips {
                        context.fill(path, with: .color(color.opacity(0.08)))
                    }
                    context.stroke(path, with: .color(color.opacity(0.8)), lineWidth: 1.5)
                }

                // 每个点
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

// MARK: - 地标颜色方案

struct slFaceLandmarkColors {
    var lips: Color
    var eyes: Color
    var eyebrows: Color
    var nose: Color
    var faceContour: Color

    func color(for region: slFaceLandmarkRegion) -> Color {
        switch region {
        case .outerLips, .innerLips:         return lips
        case .leftEye, .rightEye:            return eyes
        case .leftPupil, .rightPupil:        return eyes
        case .leftEyebrow, .rightEyebrow:    return eyebrows
        case .nose, .noseCrest:              return nose
        case .faceContour:                   return faceContour
        }
    }

    /// 默认颜色方案
    static let `default` = slFaceLandmarkColors(
        lips: .cyan.opacity(0.6),
        eyes: .green.opacity(0.6),
        eyebrows: .purple.opacity(0.6),
        nose: .yellow.opacity(0.6),
        faceContour: .white.opacity(0.2)
    )

    /// 单色方案（科技感）
    static let mono = slFaceLandmarkColors(
        lips: .cyan.opacity(0.7),
        eyes: .cyan.opacity(0.5),
        eyebrows: .cyan.opacity(0.4),
        nose: .cyan.opacity(0.5),
        faceContour: .cyan.opacity(0.15)
    )

    /// 暖色方案
    static let warm = slFaceLandmarkColors(
        lips: .pink.opacity(0.6),
        eyes: .orange.opacity(0.6),
        eyebrows: .red.opacity(0.5),
        nose: .yellow.opacity(0.6),
        faceContour: .white.opacity(0.15)
    )
}

// MARK: - Preview

#Preview {
    slFaceCameraView()
}
