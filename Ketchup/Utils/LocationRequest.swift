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
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    static let shared = LocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        switch status {
//        case .notDetermined:
//            //print("DEBUG: not determined")
//        case .restricted:
//            //print("DEBUG: Restricted")
//        case .denied:
//            //print("DEBUG: Denied")
//        case .authorizedAlways:
//            //print("DEBUG: Auth always")
//        case .authorizedWhenInUse:
//            //print("DEBUG: Auth when in use")
//        @unknown default:
//            break
//        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
    }
    
    func fetchRoute(coordinates: CLLocationCoordinate2D) async -> (MKRoute?, TimeInterval?) {
        guard let userLocation = userLocation else {
            //print("User location not available")
            return (nil, nil)
        }
        
        let request = MKDirections.Request()
        let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
        let routeSource = MKMapItem(placemark: sourcePlacemark)
        let destinationPlacemark = MKPlacemark(coordinate: coordinates)
        let routeDestination = MKMapItem(placemark: destinationPlacemark)
        
        request.source = routeSource
        request.destination = routeDestination
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        do {
            let result = try await directions.calculate()
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
