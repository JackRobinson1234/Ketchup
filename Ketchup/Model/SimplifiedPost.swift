//
//  SimplifiedPost.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/3/24.
//

import Foundation
import FirebaseCore
import SwiftUI
import MapKit
import ClusterMap
struct SimplifiedPost: Identifiable, Codable, Hashable {
    let id: String
    let timestamp: Timestamp?
    let restaurant: PostRestaurant
    let thumbnailUrl: String
    let user: PostUser
    let overallRating: Double?
    let serviceRating: Double?
    let atmosphereRating: Double?
    let valueRating: Double?
    let foodRating: Double?

    var coordinates: CLLocationCoordinate2D? {
        if let point = self.restaurant.geoPoint {
            return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        } else {
            return nil
        }
    }
}

struct SimplifiedPostMapAnnotation: CoordinateIdentifiable, Identifiable, Hashable, Equatable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var post: SimplifiedPost
}
