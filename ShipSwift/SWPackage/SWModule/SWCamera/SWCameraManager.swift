//
//  SWCameraManager.swift
//  ShipSwift
//
//  AVCaptureSession manager with photo capture and zoom control.
//  Handles camera permissions, session lifecycle, photo capture,
//  and pinch-to-zoom with configurable zoom range.
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
//    // 7. Access the AVCaptureSession for SWCameraPreview
//    SWCameraPreview(session: cameraManager.session)
//
//  Created by Wei Zhong on 3/1/26.
//

import SwiftUI
import AVFoundation

@Observable
class SWCameraManager: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    private var currentDevice: AVCaptureDevice?
    var isAuthorized = false
    var cameraPosition: AVCaptureDevice.Position = .back

    // Zoom
    var currentZoom: CGFloat = 1.0
    var minZoom: CGFloat = 1.0
    var maxZoom: CGFloat = 5.0

    // Error callback - wire this up in the view layer
    var onError: ((String) -> Void)?

    // Dedicated queue for thread-safe session operations
    private let sessionQueue = DispatchQueue(label: "com.shipswift.camera.session")
    private var isConfigured = false
    private var isConfiguring = false
    private var pendingStartSession = false

    override init() {
        super.init()
        checkCameraPermission()
    }

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

            // Set zoom range
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

    // MARK: - Switch Camera (前后镜头切换)

    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            let newPosition: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front

            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
                return
            }

            self.session.beginConfiguration()

            // 移除现有的输入源
            for input in self.session.inputs {
                self.session.removeInput(input)
            }

            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.currentDevice = newCamera

                    // 更新缩放范围
                    DispatchQueue.main.async {
                        self.minZoom = 1.0
                        self.maxZoom = min(newCamera.activeFormat.videoMaxZoomFactor, 5.0)
                        self.currentZoom = 1.0
                        self.cameraPosition = newPosition
                    }

                    // 重置缩放
                    self.applyZoom(1.0, to: newCamera)
                }
            } catch {
                // 切换失败，静默忽略
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
            // 缩放失败，静默忽略
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
