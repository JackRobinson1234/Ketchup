//
//  LocationRequest.swift
//  Foodi
//
//  Created by Jack Robinson on 3/1/24.
//

import Foundation
import CoreLocation
import MapKit


class LocationManager: NSObject, ObservableObject {
    @Published var userLocation: CLLocation?
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    private var locationCompletion: ((Bool) -> Void)?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation(completion: @escaping (Bool) -> Void) {
        locationCompletion = completion
        
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            locationCompletion?(false)
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        @unknown default:
            locationCompletion?(false)
        }
    }
    
    func fetchRoute(coordinates: CLLocationCoordinate2D) async -> (MKRoute?, TimeInterval?) {
        guard let userLocation = userLocation else {
            //print("User location not available")
            return (nil, nil)
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates))
        request.transportType = .automobile
        
        do {
            let result = try await MKDirections(request: request).calculate()
            if let firstRoute = result.routes.first {
                return (firstRoute, firstRoute.expectedTravelTime)
            } else {
                //print("No routes found")
                return (nil, nil)
            }
        } catch {
            //print("Failed to calculate route: \(error)")
            return (nil, nil)
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .restricted, .denied:
            locationCompletion?(false)
        case .notDetermined:
            // Wait for the user to make a choice
            break
        @unknown default:
            locationCompletion?(false)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        locationCompletion?(true)
        locationCompletion = nil
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //print("Location manager failed with error: \(error)")
        locationCompletion?(false)
        locationCompletion = nil
    }
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
    }
}
