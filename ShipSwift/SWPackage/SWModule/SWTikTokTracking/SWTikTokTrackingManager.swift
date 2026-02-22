//
//  SWTikTokTrackingManager.swift
//  ShipSwift
//
//  TikTok ad attribution and event tracking manager with ATT permission flow.
//  SDK-agnostic: consumer app injects actual SDK calls via eventHandler closure.
//
//  Prerequisites:
//    Add TikTok Business SDK via SPM in consumer app.
//
//  Usage:
//    // 1. Configure in App init() with event handler:
//    SWTikTokTrackingManager.shared.configure { eventName, properties in
//        let event = TikTokBaseEvent(eventName: eventName)
//        properties?.forEach { event.addProperty(withKey: $0.key, value: $0.value) }
//        TikTokBusiness.trackTTEvent(event)
//    }
//
//    // 2. Request ATT on scenePhase .active:
//    SWTikTokTrackingManager.shared.requestTrackingAuthorization()
//
//    // 3. Track standard events:
//    SWTikTokTrackingManager.shared.track(.subscribe)
//    SWTikTokTrackingManager.shared.track(.viewContent, properties: ["content_type": "report"])
//
//    // 4. Track custom events:
//    SWTikTokTrackingManager.shared.trackCustom("SmileScan")
//

import SwiftUI
import AppTrackingTransparency

// MARK: - Tracking Event Types

/// Standard event types supported by TikTok App Events SDK.
enum SWTikTokTrackingEvent: String, CaseIterable {
    case purchase = "Purchase"
    case subscribe = "Subscribe"
    case viewContent = "ViewContent"
    case completeTutorial = "CompleteTutorial"
    case addToCart = "AddToCart"
    case addPaymentInfo = "AddPaymentInfo"
    case completeRegistration = "CompleteRegistration"
    case search = "Search"
    case startTrial = "StartTrial"
}

// MARK: - ATT Authorization Status

/// Wrapper for AppTrackingTransparency authorization status.
enum SWTikTokTrackingAuthStatus: String {
    case notDetermined = "Not Determined"
    case restricted = "Restricted"
    case denied = "Denied"
    case authorized = "Authorized"

    init(from status: ATTrackingManager.AuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        case .denied: self = .denied
        case .authorized: self = .authorized
        @unknown default: self = .notDetermined
        }
    }
}

// MARK: - Tracking Manager

@MainActor
@Observable
final class SWTikTokTrackingManager {

    static let shared = SWTikTokTrackingManager()

    // MARK: - Properties

    /// Current ATT authorization status.
    private(set) var authStatus: SWTikTokTrackingAuthStatus = .notDetermined

    /// Whether the manager has been configured with an event handler.
    private(set) var isConfigured = false

    /// Whether debug logging is enabled.
    private(set) var isDebugMode = false

    // MARK: - Private

    /// Consumer-injected event handler that bridges to the actual tracking SDK.
    private var eventHandler: ((String, [String: String]?) -> Void)?

    private var hasRequestedATT = false

    private init() {
        updateAuthStatus()
    }

    // MARK: - Configuration

    /// Configure tracking with an event handler closure.
    /// The handler bridges to TikTok Business SDK.
    ///
    /// - Parameters:
    ///   - debugMode: Enable verbose logging (default: true in DEBUG builds)
    ///   - eventHandler: Closure that receives event name and optional properties,
    ///                   responsible for calling the actual SDK
    func configure(
        debugMode: Bool? = nil,
        eventHandler: @escaping (String, [String: String]?) -> Void
    ) {
        self.eventHandler = eventHandler
        isConfigured = true

        #if DEBUG
        isDebugMode = debugMode ?? true
        #else
        isDebugMode = debugMode ?? false
        #endif

        debugLog("SWTikTokTrackingManager configured (debug: \(isDebugMode))")
    }

    // MARK: - ATT Permission

    /// Request App Tracking Transparency authorization.
    /// Automatically delays 0.5 second to ensure the app is fully loaded.
    /// Call from scenePhase .active, NOT from App init().
    func requestTrackingAuthorization() {
        guard !hasRequestedATT else { return }
        hasRequestedATT = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                Task { @MainActor in
                    self?.authStatus = SWTikTokTrackingAuthStatus(from: status)
                    self?.debugLog("ATT status: \(self?.authStatus.rawValue ?? "unknown")")
                    // Reset if not determined (e.g., dialog was blocked by network permission)
                    if status == .notDetermined {
                        self?.hasRequestedATT = false
                    }
                }
            }
        }
    }

    // MARK: - Event Tracking

    /// Track a standard event.
    func track(_ event: SWTikTokTrackingEvent, properties: [String: String]? = nil) {
        guard isConfigured else {
            debugLog("SWTikTokTrackingManager not configured. Call configure() first.")
            return
        }

        eventHandler?(event.rawValue, properties)
        debugLog("Track: \(event.rawValue) \(properties ?? [:])")
    }

    /// Track a custom event with an arbitrary name.
    func trackCustom(_ eventName: String, properties: [String: String]? = nil) {
        guard isConfigured else {
            debugLog("SWTikTokTrackingManager not configured. Call configure() first.")
            return
        }

        eventHandler?(eventName, properties)
        debugLog("Track custom: \(eventName) \(properties ?? [:])")
    }

    // MARK: - Status

    /// Refresh the current ATT authorization status.
    func updateAuthStatus() {
        authStatus = SWTikTokTrackingAuthStatus(from: ATTrackingManager.trackingAuthorizationStatus)
    }

    // MARK: - Private

    private func debugLog(_ message: String) {
        #if DEBUG
        if isDebugMode {
            print("[SWTikTokTracking] \(message)")
        }
        #endif
    }
}
