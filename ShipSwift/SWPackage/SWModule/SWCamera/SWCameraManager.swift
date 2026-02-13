//
//  SWCameraManager.swift
//  ShipSwift
//
//  Unified AVCaptureSession manager with photo capture, zoom control,
//  and optional real-time Vision face landmark tracking.
//
//  Base camera features: permission handling, session lifecycle,
//  front/back switching, pinch-to-zoom, and photo capture.
//
//  Face tracking features (opt-in via faceTrackingEnabled):
//  real-time Vision face landmark detection with normalized coordinates,
//  suitable for overlay rendering in SWFaceCameraView.
//
//  Usage:
//    // 1. Create manager (automatically checks camera permission)
//    @State private var cameraManager = SWCameraManager()
//
//    // 2. Wire up error callback for UI alerts
//    cameraManager.onError = { message in
//        SWAlertManager.shared.show(.error, message: message)
//    }
//
//    // 3. Start/stop session (call in onAppear/onDisappear)
//    cameraManager.startSession()
//    cameraManager.stopSession()
//
//    // 4. Capture a photo
//    cameraManager.capturePhoto { image in
//        guard let image else { return }
//        // use captured UIImage
//    }
//
//    // 5. Zoom control
//    cameraManager.setZoom(2.0)               // set absolute zoom
//    cameraManager.zoom(by: 1.5)              // multiply current zoom
//    let current = cameraManager.currentZoom  // read current zoom level
//    // zoom range: cameraManager.minZoom ... cameraManager.maxZoom
//
//    // 6. Check authorization
//    if cameraManager.isAuthorized { /* show camera preview */ }
//
//    // 7. Access the AVCaptureSession for preview
//    SWCameraPreview(session: cameraManager.session)
//
//    // 8. Enable face tracking (for SWFaceCameraView)
//    cameraManager.faceTrackingEnabled = true
//    // Access real-time landmarks:
//    for group in cameraManager.faceLandmarks {
//        // group.region: SWFaceLandmarkRegion
//        // group.points: [CGPoint] in normalized coordinates (0...1)
//    }
//
//    // 9. Initialize with specific camera position
//    @State private var cameraManager = SWCameraManager(position: .front)
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI
import AVFoundation
import Vision

@Observable
final class SWCameraManager: NSObject, @unchecked Sendable {

    // MARK: - Public Properties (Base Camera)

    let session = AVCaptureSession()
    var isAuthorized = false
    var cameraPosition: AVCaptureDevice.Position = .back

    /// Zoom
    var currentZoom: CGFloat = 1.0
    var minZoom: CGFloat = 1.0
    var maxZoom: CGFloat = 5.0

    /// Error callback - wire this up in the view layer
    var onError: ((String) -> Void)?

    // MARK: - Public Properties (Face Tracking, opt-in)

    /// Whether real-time face detection is enabled (default off; SWFaceCameraView turns it on)
    @ObservationIgnored
    nonisolated(unsafe) var faceTrackingEnabled = false

    /// Real-time detected face landmarks (capture device normalized coordinates, top-left origin)
    var faceLandmarks: [SWFaceLandmarkGroup] = []

    // MARK: - Private Properties (Session)

    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    private var currentDevice: AVCaptureDevice?

    /// Dedicated queue for thread-safe session operations
    private let sessionQueue = DispatchQueue(label: "com.shipswift.camera.session")
    private var isConfigured = false
    private var isConfiguring = false
    private var pendingStartSession = false

    // MARK: - Private Properties (Face Tracking)

    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataQueue = DispatchQueue(label: "com.shipswift.camera.videodata", qos: .userInitiated)
    @ObservationIgnored
    private nonisolated(unsafe) let sequenceHandler = VNSequenceRequestHandler()
    /// Background-thread-safe copy of camera position (for Vision orientation)
    @ObservationIgnored
    private nonisolated(unsafe) var _bgCameraPosition: AVCaptureDevice.Position = .back

    // MARK: - Initialization

    /// Default initializer (rear camera)
    override init() {
        super.init()
        checkCameraPermission()
    }

    /// Initialize with specific camera position
    init(position: AVCaptureDevice.Position) {
        self.cameraPosition = position
        self._bgCameraPosition = position
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
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted {
                        self.setupCamera()
                    } else {
                        self.onError?(String(localized: "Camera permission denied"))
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.onError?(String(localized: "Camera permission denied. Please enable in Settings"))
            }
        @unknown default:
            DispatchQueue.main.async {
                self.onError?(String(localized: "Unknown permission status"))
            }
        }
    }

    // MARK: - Camera Configuration

    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isConfigured, !self.isConfiguring else { return }

            self.isConfiguring = true
            self.session.beginConfiguration()

            // Clear existing inputs and outputs
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition) else {
                DispatchQueue.main.async {
                    self.onError?(String(localized: "Unable to access camera"))
                }
                self.session.commitConfiguration()
                self.isConfiguring = false
                return
            }

            self.currentDevice = camera

            // Update zoom range
            DispatchQueue.main.async {
                self.minZoom = 1.0
                self.maxZoom = min(camera.activeFormat.videoMaxZoomFactor, 5.0)
                self.currentZoom = 1.0
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)

                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                } else {
                    DispatchQueue.main.async {
                        self.onError?(String(localized: "Unable to add camera input"))
                    }
                    self.session.commitConfiguration()
                    self.isConfiguring = false
                    return
                }

                self.session.sessionPreset = .photo

                // Photo output
                if self.photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.hevc) {
                    self.photoOutput.maxPhotoQualityPrioritization = .balanced
                }

                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                } else {
                    DispatchQueue.main.async {
                        self.onError?(String(localized: "Unable to add photo output"))
                    }
                    self.session.commitConfiguration()
                    self.isConfiguring = false
                    return
                }

                // Video data output (for face tracking; always added so tracking can be toggled at runtime)
                self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoDataQueue)
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                if self.session.canAddOutput(self.videoDataOutput) {
                    self.session.addOutput(self.videoDataOutput)
                }

                // Auto focus / exposure / white balance configuration
                self.configureAutoFocus(camera)

                self.session.commitConfiguration()
                self.isConfigured = true
                self.isConfiguring = false

                // If there's a pending start request, start immediately
                if self.pendingStartSession {
                    self.pendingStartSession = false
                    if !self.session.isRunning {
                        self.session.startRunning()
                    }
                }

            } catch {
                self.session.commitConfiguration()
                self.isConfiguring = false
                DispatchQueue.main.async {
                    self.onError?(String(localized: "Camera setup failed"))
                }
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

    // MARK: - Zoom Control

    func setZoom(_ factor: CGFloat) {
        guard let device = currentDevice else { return }

        let zoomFactor = max(minZoom, min(factor, maxZoom))

        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = zoomFactor
            device.unlockForConfiguration()

            DispatchQueue.main.async {
                self.currentZoom = zoomFactor
            }
        } catch {
            // Zoom failed, silently ignore
        }
    }

    func zoom(by delta: CGFloat) {
        setZoom(currentZoom * delta)
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

            // Remove existing inputs
            for input in self.session.inputs {
                self.session.removeInput(input)
            }

            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.currentDevice = newCamera

                    // Update background-thread-safe camera position (for Vision orientation)
                    self._bgCameraPosition = newPosition

                    // Configure auto focus for the new camera
                    self.configureAutoFocus(newCamera)

                    // Reset zoom
                    self.applyZoom(1.0, to: newCamera)

                    // Update main-thread properties
                    DispatchQueue.main.async {
                        self.cameraPosition = newPosition
                        self.minZoom = 1.0
                        self.maxZoom = min(newCamera.activeFormat.videoMaxZoomFactor, 5.0)
                        self.currentZoom = 1.0
                    }
                }
            } catch {
                // Switch failed, silently ignore
            }

            self.session.commitConfiguration()
        }
    }

    // MARK: - Private Helpers

    private func applyZoom(_ factor: CGFloat, to device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = max(1.0, min(factor, device.activeFormat.videoMaxZoomFactor))
            device.unlockForConfiguration()
        } catch {
            // Zoom failed, silently ignore
        }
    }

    /// Configure auto focus, exposure, and white balance for optimal camera performance
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
            // Configuration failed, silently ignore
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension SWCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            DispatchQueue.main.async {
                self.onError?(String(localized: "Photo capture failed"))
            }
            captureCompletion?(nil)
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.onError?(String(localized: "Unable to process photo data"))
            }
            captureCompletion?(nil)
            return
        }

        captureCompletion?(image)
    }
}

// MARK: - Real-time Face Landmark Detection (Vision)

extension SWCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Skip processing when face tracking is disabled
        guard faceTrackingEnabled else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Front camera is mirrored, rear camera is normal
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
