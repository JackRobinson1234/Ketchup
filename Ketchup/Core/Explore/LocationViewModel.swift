//
//  LocationViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/17/24.
//

import Foundation
import SwiftUI
import CoreLocation
import Firebase
import GeoFire
@MainActor
class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var city: String?
    @Published var state: String?
    @Published var surroundingGeohash: String?
    @Published var surroundingCounty: String = "Nearby"
    @Published var selectedLocationCoordinate: CLLocationCoordinate2D?
    @Published var isLoadingLocation: Bool = false
    
    private let locationManager = LocationManager.shared
    

    func requestLocation() {
        isLoadingLocation = true
        locationManager.requestLocation{success in
            if success, let coordinate = self.locationManager.userLocation?.coordinate {
                self.selectedLocationCoordinate = coordinate
                self.surroundingGeohash = GFUtils.geoHash(forLocation: self.selectedLocationCoordinate!)
                self.reverseGeocodeLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            } else if let coordinate = AuthService.shared.userSession?.location?.geoPoint {
                let latitude = coordinate.latitude
                let longitude = coordinate.longitude
                self.selectedLocationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                self.surroundingGeohash = GFUtils.geoHash(forLocation: self.selectedLocationCoordinate!)
                self.reverseGeocodeLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
        }
    }
    
    func updateLocation(latitude: Double, longitude: Double) {
        selectedLocationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        surroundingGeohash = GFUtils.geoHash(forLocation: selectedLocationCoordinate!)
        reverseGeocodeLocation(latitude: latitude, longitude: longitude)
    }
    
    private func reverseGeocodeLocation(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLoadingLocation = false
            }
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self?.city = placemark.locality
                    self?.state = placemark.administrativeArea
                    self?.surroundingCounty = placemark.subAdministrativeArea ?? "Nearby"
                }
            } else {
                print("Placemark not available.")
            }
        }
    }
    
    // CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first?.coordinate {
            updateLocation(latitude: location.latitude, longitude: location.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoadingLocation = false
        print("Failed to get user location: \(error.localizedDescription)")
    }
}
