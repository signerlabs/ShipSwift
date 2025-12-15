//
//  slLocationManager.swift
//  full-pack
//
//  Created by Wei on 2025/5/9.
//

import CoreLocation
import UIKit

@MainActor
@Observable
final class slLocationManager: NSObject {

    // MARK: - 内置数据模型

    /// 位置信息模型
    struct Location: Identifiable, Equatable, Codable {
        let id: UUID
        let name: String
        let latitude: Double
        let longitude: Double

        init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double) {
            self.id = id
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
        }

        /// 转换为 CLLocationCoordinate2D
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        /// 转换为 CLLocation
        var clLocation: CLLocation {
            CLLocation(latitude: latitude, longitude: longitude)
        }
    }

    // MARK: - 属性

    private(set) var userLocation: CLLocation?
    private(set) var currentLocation: Location?
    private(set) var isAuthorized = false
    
    var isAuthorizationDetermined: Bool {
        manager.authorizationStatus != .notDetermined
    }
    
    @ObservationIgnored
    private let manager = CLLocationManager()
    
    @ObservationIgnored
    private let geocoder = CLGeocoder()
    
    private static let authorizedStatuses: Set<CLAuthorizationStatus> = [
        .authorizedAlways,
        .authorizedWhenInUse
    ]
    
    // MARK: - 初始化
    
    override init() {
        super.init()
        manager.delegate = self
        updateAuthorizationStatus()
    }
    
    // MARK: - 公开方法
    
    func startLocationServices() {
        userLocation = nil
        currentLocation = nil
        updateAuthorizationStatus()
        
        if isAuthorized {
            manager.startUpdatingLocation()
        } else if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - 私有方法
    
    private func updateAuthorizationStatus() {
        isAuthorized = Self.authorizedStatuses.contains(manager.authorizationStatus)
    }
    
    private func resolveLocationName(for location: CLLocation) async -> String {
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        return placemarks?.first?.locality ?? ""
    }
}

// MARK: - CLLocationManagerDelegate

extension slLocationManager: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            userLocation = location
            let name = await resolveLocationName(for: location)
            currentLocation = Location(
                name: name,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            manager.stopUpdatingLocation()
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            updateAuthorizationStatus()
            if isAuthorized {
                manager.startUpdatingLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // 静默处理错误
    }
}
