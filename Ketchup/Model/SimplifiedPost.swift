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
import FirebaseFirestoreInternal
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
    let caption: String?

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
extension SimplifiedPost {
    func toPost() -> Post {
        return Post(
            id: self.id,
            mediaType: .photo,  // Default to photo since we have thumbnailUrl
            mediaUrls: [self.thumbnailUrl],  // Use thumbnailUrl as the only media
            mixedMediaUrls: nil,  // Default to nil since simplified doesn't have this
            caption: self.caption ?? "",  // Empty caption since simplified doesn't have this
            likes: 0,  // Default to 0
            commentCount: 0,  // Default to 0
            bookmarkCount: 0,  // Default to 0
            repostCount: 0,  // Default to 0
            thumbnailUrl: self.thumbnailUrl,
            timestamp: self.timestamp,
            user: self.user,
            restaurant: self.restaurant,
            didLike: false,  // Default to false
            didBookmark: false,  // Default to false
            fromInAppCamera: false,  // Default to false
            repost: false,  // Default to false
            didRepost: false,  // Default to false
            overallRating: self.overallRating,
            serviceRating: self.serviceRating,
            atmosphereRating: self.atmosphereRating,
            valueRating: self.valueRating,
            foodRating: self.foodRating,
            taggedUsers: [],  // Empty array since simplified doesn't have this
            captionMentions: [],  // Empty array since simplified doesn't have this
            isReported: false,  // Default to false
            goodFor: nil  // Default to nil since simplified doesn't have this
        )
    }
    func toClusterRestaurant() -> ClusterRestaurant {
            return ClusterRestaurant(
                id: self.restaurant.id,
                name: self.restaurant.name,
                geoPoint: self.restaurant.geoPoint ?? GeoPoint(latitude: 0, longitude: 0),
                cuisine: self.restaurant.cuisine,
                price: self.restaurant.price,
                profileImageUrl: self.thumbnailUrl,  // Use post image instead of restaurant profile
                fullGeoHash: nil,
                attributes: nil,
                postCount: nil,
                overallRating: self.overallRating,
                macrocategory: self.restaurant.cuisine,
                city: self.restaurant.city,
                topGoodFor: nil
            )
        }
}
