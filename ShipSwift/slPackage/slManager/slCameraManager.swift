//
//  slCameraManager.swift
//  full-pack
//
//  Created by Wei on 2025/6/25.
//

import SwiftUI
import AVFoundation

@Observable
class slCameraManager: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    private var currentDevice: AVCaptureDevice?
    var isAuthorized = false

    // 缩放相关
    var currentZoom: CGFloat = 1.0
    var minZoom: CGFloat = 1.0
    var maxZoom: CGFloat = 5.0

    // 使用专用队列确保线程安全，所有 session 操作都在此队列上串行执行
    private let sessionQueue = DispatchQueue(label: "com.fullpack.camera.session")
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
                        slAlertManager.shared.show(.error, message: String(localized: "Camera permission denied"))
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                slAlertManager.shared.show(.error, message: String(localized: "Camera permission denied. Please enable in Settings"))
            }
        @unknown default:
            DispatchQueue.main.async {
                slAlertManager.shared.show(.error, message: String(localized: "Unknown permission status"))
            }
        }
    }

    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            // 如果已配置或正在配置，直接返回
            guard !self.isConfigured, !self.isConfiguring else { return }

            self.isConfiguring = true
            self.session.beginConfiguration()

            // 清除现有输入和输出
            for input in self.session.inputs {
                self.session.removeInput(input)
            }
            for output in self.session.outputs {
                self.session.removeOutput(output)
            }

            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async {
                    slAlertManager.shared.show(.error, message: String(localized: "Unable to access rear camera"))
                }
                self.session.commitConfiguration()
                self.isConfiguring = false
                return
            }

            self.currentDevice = camera

            // 设置缩放范围
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
                        slAlertManager.shared.show(.error, message: String(localized: "Unable to add camera input"))
                    }
                    self.session.commitConfiguration()
                    self.isConfiguring = false
                    return
                }

                // 配置照片输出前先设置会话预设
                self.session.sessionPreset = .photo

                // 配置照片输出设置
                if self.photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.hevc) {
                    self.photoOutput.maxPhotoQualityPrioritization = .balanced
                }

                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                } else {
                    DispatchQueue.main.async {
                        slAlertManager.shared.show(.error, message: String(localized: "Unable to add photo output"))
                    }
                    self.session.commitConfiguration()
                    self.isConfiguring = false
                    return
                }

                self.session.commitConfiguration()
                self.isConfigured = true
                self.isConfiguring = false

                // 如果有待处理的启动请求，立即启动
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
                    slAlertManager.shared.show(.error, message: String(localized: "Camera setup failed"))
                }
            }
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            // 如果正在配置中，标记待启动
            if self.isConfiguring {
                self.pendingStartSession = true
                return
            }

            // 如果尚未配置完成，标记待启动
            guard self.isConfigured else {
                self.pendingStartSession = true
                return
            }

            // 配置完成，直接启动
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

        // 创建照片设置，使用兼容的格式
        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(AVVideoCodecType.jpeg) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            settings = AVCapturePhotoSettings()
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - 缩放控制

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
            // 缩放失败，静默处理
        }
    }

    func zoom(by delta: CGFloat) {
        setZoom(currentZoom * delta)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension slCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            DispatchQueue.main.async {
                slAlertManager.shared.show(.error, message: String(localized: "Photo capture failed"))
            }
            captureCompletion?(nil)
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                slAlertManager.shared.show(.error, message: String(localized: "Unable to process photo data"))
            }
            captureCompletion?(nil)
            return
        }

        captureCompletion?(image)
    }
}
