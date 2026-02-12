//
//  SWFaceCameraManager.swift
//  ShipSwift
//
//  Face detection camera manager with Vision landmark tracking.
//  Extends camera functionality with real-time face landmark detection,
//  front/back camera switching, per-camera zoom, and photo capture.
//
//  Usage:
//    // 1. Create manager with initial camera position and zoom
//    @State private var cameraManager = SWFaceCameraManager(
//        position: .front,
//        frontZoom: 1.0,
//        backZoom: 1.0
//    )
//
//    // 2. Enable face tracking and start session
//    cameraManager.faceTrackingEnabled = true
//    cameraManager.startSession()
//
//    // 3. Access real-time face landmarks (updated every frame)
//    for group in cameraManager.faceLandmarks {
//        // group.region: SWFaceLandmarkRegion (.leftEye, .outerLips, etc.)
//        // group.points: [CGPoint] in normalized coordinates (0...1)
//        // group.isClosed: Bool (true if > 2 points)
//    }
//
//    // 4. Switch between front and back cameras
//    cameraManager.switchCamera()
//    let position = cameraManager.cameraPosition  // .front or .back
//
//    // 5. Capture a photo
//    cameraManager.capturePhoto { image in
//        guard let image else { return }
//        // use captured UIImage
//    }
//
//    // 6. Stop session and disable tracking (in onDisappear)
//    cameraManager.faceTrackingEnabled = false
//    cameraManager.stopSession()
//
//    // 7. Access the AVCaptureSession for preview
//    SWFaceCameraPreview(session: cameraManager.session)
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI
import AVFoundation
import Vision

@Observable
final class SWFaceCameraManager: NSObject, @unchecked Sendable {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    var isAuthorized = false

    /// Current camera position
    var cameraPosition: AVCaptureDevice.Position = .front

    /// Background-thread-safe copy of camera position
    @ObservationIgnored
    private nonisolated(unsafe) var _bgCameraPosition: AVCaptureDevice.Position = .front

    /// Front camera zoom factor
    var frontZoomFactor: CGFloat = 1.0

    /// Rear camera zoom factor
    var backZoomFactor: CGFloat = 1.0

    /// Real-time detected face landmarks (capture device normalized coordinates, top-left origin)
    var faceLandmarks: [SWFaceLandmarkGroup] = []

    /// Whether real-time face detection is enabled (also read from background thread)
    @ObservationIgnored
    nonisolated(unsafe) var faceTrackingEnabled = false

    // Use a dedicated queue to ensure thread safety
    private let sessionQueue = DispatchQueue(label: "com.shipswift.facecamera.session")
    private var isConfigured = false
    private var isConfiguring = false
    private var pendingStartSession = false

    // Video frame processing (for real-time detection, accessed from background thread)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataQueue = DispatchQueue(label: "com.shipswift.facecamera.videodata", qos: .userInitiated)
    private nonisolated(unsafe) let sequenceHandler = VNSequenceRequestHandler()

    override init() {
        super.init()
        checkCameraPermission()
    }

    /// Initialize with specified camera position
    init(position: AVCaptureDevice.Position, frontZoom: CGFloat = 1.0, backZoom: CGFloat = 1.0) {
        self.cameraPosition = position
        self._bgCameraPosition = position
        self.frontZoomFactor = frontZoom
        self.backZoomFactor = backZoom
        super.init()
        checkCameraPermission()
    }

    // MARK: - Permission Check

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted {
                        self.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Camera Configuration

    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isConfigured, !self.isConfiguring else { return }

            self.isConfiguring = true
            self.session.beginConfiguration()

            // Remove existing inputs and outputs
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition) else {
                self.session.commitConfiguration()
                self.isConfiguring = false
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)

                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    self.session.commitConfiguration()
                    self.isConfiguring = false
                    return
                }

                self.session.sessionPreset = .photo

                if self.photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.hevc) {
                    self.photoOutput.maxPhotoQualityPrioritization = .balanced
                }

                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                } else {
                    self.session.commitConfiguration()
                    self.isConfiguring = false
                    return
                }

                // Add video frame output (for real-time face detection)
                self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoDataQueue)
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                if self.session.canAddOutput(self.videoDataOutput) {
                    self.session.addOutput(self.videoDataOutput)
                }

                self.applyZoomFactor(camera, factor: self.zoomFactor(for: self.cameraPosition))
                self.configureAutoFocus(camera)

                self.session.commitConfiguration()
                self.isConfigured = true
                self.isConfiguring = false

                if self.pendingStartSession {
                    self.pendingStartSession = false
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                }

            } catch {
                self.session.commitConfiguration()
                self.isConfiguring = false
            }
        }
    }

    // MARK: - Session Control

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if self.isConfiguring {
                self.pendingStartSession = true
                return
            }

            guard self.isConfigured else {
                self.pendingStartSession = true
                return
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    // MARK: - Switch Camera

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            let newPosition: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front

            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
                return
            }

            self.session.beginConfiguration()

            for input in self.session.inputs {
                self.session.removeInput(input)
            }

            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.applyZoomFactor(newCamera, factor: self.zoomFactor(for: newPosition))
                    self.configureAutoFocus(newCamera)
                    self._bgCameraPosition = newPosition
                    DispatchQueue.main.async {
                        self.cameraPosition = newPosition
                    }
                }
            } catch {
                // Switch failed
            }

            self.session.commitConfiguration()
        }
    }

    // MARK: - Photo Capture

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.captureCompletion = completion

        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            settings = AVCapturePhotoSettings()
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Internal Utilities

    private func zoomFactor(for position: AVCaptureDevice.Position) -> CGFloat {
        return position == .front ? frontZoomFactor : backZoomFactor
    }

    private func configureAutoFocus(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()

            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            } else if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }

            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }

            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }

            device.unlockForConfiguration()
        } catch {
            // Configuration failed
        }
    }

    private func applyZoomFactor(_ device: AVCaptureDevice, factor: CGFloat) {
        do {
            try device.lockForConfiguration()
            let minZoom = device.minAvailableVideoZoomFactor
            let maxZoom = device.maxAvailableVideoZoomFactor
            let clampedFactor = max(minZoom, min(factor, maxZoom))
            device.videoZoomFactor = clampedFactor
            device.unlockForConfiguration()
        } catch {
            // Zoom failed
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension SWFaceCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            DispatchQueue.main.async {
                self.captureCompletion?(nil)
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.captureCompletion?(nil)
            }
            return
        }

        DispatchQueue.main.async {
            self.captureCompletion?(image)
        }
    }
}

// MARK: - Real-time Face Landmark Detection

extension SWFaceCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard faceTrackingEnabled else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Front camera mirrored, rear camera normal
        let orientation: CGImagePropertyOrientation = _bgCameraPosition == .front ? .leftMirrored : .right

        let request = VNDetectFaceLandmarksRequest()
        try? sequenceHandler.perform([request], on: pixelBuffer, orientation: orientation)

        guard let face = request.results?.first,
              let landmarks = face.landmarks else {
            Task { @MainActor in
                self.faceLandmarks = []
            }
            return
        }

        let bbox = face.boundingBox
        var groups: [SWFaceLandmarkGroup] = []

        /// Convert Vision landmark points to capture device normalized coordinates
        func convert(_ region: VNFaceLandmarkRegion2D?, type: SWFaceLandmarkRegion) {
            guard let region else { return }
            let pts = region.normalizedPoints.map { p in
                let x = bbox.origin.x + p.x * bbox.width
                let y = bbox.origin.y + p.y * bbox.height
                return CGPoint(x: x, y: 1.0 - y)
            }
            groups.append(SWFaceLandmarkGroup(region: type, points: pts))
        }

        // Extract all supported face landmarks
        convert(landmarks.faceContour, type: .faceContour)
        convert(landmarks.leftEyebrow, type: .leftEyebrow)
        convert(landmarks.rightEyebrow, type: .rightEyebrow)
        convert(landmarks.leftEye, type: .leftEye)
        convert(landmarks.rightEye, type: .rightEye)
        convert(landmarks.leftPupil, type: .leftPupil)
        convert(landmarks.rightPupil, type: .rightPupil)
        convert(landmarks.nose, type: .nose)
        convert(landmarks.noseCrest, type: .noseCrest)
        convert(landmarks.outerLips, type: .outerLips)
        convert(landmarks.innerLips, type: .innerLips)

        let result = groups
        Task { @MainActor in
            self.faceLandmarks = result
        }
    }
}
