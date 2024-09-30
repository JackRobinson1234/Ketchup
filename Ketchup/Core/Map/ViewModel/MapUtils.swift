//
//  MapUtils.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/3/24.
//

import Foundation
import CoreLocation
import MapKit
class MapUtils {
    static func calculateDistanceThreshold(for region: MKCoordinateRegion) -> Double {
        let northEast = CLLocation(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude + region.span.longitudeDelta / 2
        )
        let southWest = CLLocation(
            latitude: region.center.latitude - region.span.latitudeDelta / 2,
            longitude: region.center.longitude - region.span.longitudeDelta / 2
        )
        let diagonalDistance = northEast.distance(from: southWest) / 1000 // Convert to km

        if diagonalDistance > 1000 {
            return 500  // 500 km threshold
        } else if diagonalDistance > 500 {
            return 200  // 200 km threshold
        } else if diagonalDistance > 100 {
            return 50   // 50 km threshold
        } else if diagonalDistance > 50 {
            return 10   // 10 km threshold
        } else {
            return max(diagonalDistance * 0.15, 0.5)  // 15% of diagonal or at least 0.5 km
        }
    }

    
    static func calculateDistance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }
}
