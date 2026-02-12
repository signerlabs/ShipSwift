//
//  SWLocationManager.swift
//  ShipSwift
//
//  CoreLocation-based location manager (@Observable) that encapsulates authorization
//  requests, location updates, and reverse geocoding. Automatically stops updates after
//  obtaining a location to conserve battery. Results are stored in currentLocation
//  (SWLocationManager.Location).
//
//  Usage:
//    // 1. Initialize (recommended at the App level or in a ViewModel):
//    @State private var locationManager = SWLocationManager()
//
//    // 2. Request location (automatically handles authorization status: requests authorization
//    //    if not determined, starts updates directly if already authorized):
//    locationManager.startLocationServices()
//
//    // 3. Read location results (@Observable drives automatic UI refresh):
//    if let location = locationManager.currentLocation {
//        Text(location.name)                    // City name (reverse geocoding)
//        Text("\(location.latitude), \(location.longitude)")
//        let coord = location.coordinate        // CLLocationCoordinate2D
//    }
//
//    // 4. Check authorization status:
//    locationManager.isAuthorized               // Whether authorized
//    locationManager.isAuthorizationDetermined  // Whether the user has made a choice
//
//    // 5. Guide the user to system Settings (when authorization is denied):
//    locationManager.openSettings()
//
//    // 6. Built-in Location data model (Identifiable, Equatable, Codable):
//    let saved = SWLocationManager.Location(
//        name: "Beijing", latitude: 39.9042, longitude: 116.4074
//    )
//
//  Created by Wei Zhong on 3/1/26.
//

import CoreLocation
import UIKit

@MainActor
@Observable
final class SWLocationManager: NSObject {

    // MARK: - Built-in Data Model

    /// Location info model
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

        /// Convert to CLLocationCoordinate2D
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        /// Convert to CLLocation
        var clLocation: CLLocation {
            CLLocation(latitude: latitude, longitude: longitude)
        }
    }

    // MARK: - Properties

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

    // MARK: - Initialization

    override init() {
        super.init()
        manager.delegate = self
        updateAuthorizationStatus()
    }

    // MARK: - Public Methods

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

    // MARK: - Private Methods

    private func updateAuthorizationStatus() {
        isAuthorized = Self.authorizedStatuses.contains(manager.authorizationStatus)
    }

    private func resolveLocationName(for location: CLLocation) async -> String {
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        return placemarks?.first?.locality ?? ""
    }
}

// MARK: - CLLocationManagerDelegate

extension SWLocationManager: CLLocationManagerDelegate {

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
        // Silently handle errors
    }
}
