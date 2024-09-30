//
//  PostCluster.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/3/24.
//

import MapKit
import Foundation
import FirebaseFirestoreInternal
import Firebase
struct ClusterIndividualPost: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let timestamp: Timestamp
    var restaurant: ClusterRestaurant
    var thumbnailUrl: String?
    var user: PostUser
    var overallRating: Double?
    var serviceRating: Double?
    var atmosphereRating: Double?
    var valueRating: Double?
    var foodRating: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case restaurant
        case thumbnailUrl
        case user
        case overallRating
        case serviceRating
        case atmosphereRating
        case valueRating
        case foodRating
    }

    // Custom initializer
    init(id: String = NSUUID().uuidString,
         timestamp: Timestamp,
         restaurant: ClusterRestaurant,
         thumbnailUrl: String? = nil,
         user: PostUser,
         overallRating: Double? = nil,
         serviceRating: Double? = nil,
         atmosphereRating: Double? = nil,
         valueRating: Double? = nil,
         foodRating: Double? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.restaurant = restaurant
        self.thumbnailUrl = thumbnailUrl
        self.user = user
        self.overallRating = overallRating
        self.serviceRating = serviceRating
        self.atmosphereRating = atmosphereRating
        self.valueRating = valueRating
        self.foodRating = foodRating
    }

    // Decoding initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? NSUUID().uuidString
        timestamp = try container.decode(Timestamp.self, forKey: .timestamp)
        restaurant = try container.decode(ClusterRestaurant.self, forKey: .restaurant)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        user = try container.decode(PostUser.self, forKey: .user)
        overallRating = try container.decodeIfPresent(Double.self, forKey: .overallRating)
        serviceRating = try container.decodeIfPresent(Double.self, forKey: .serviceRating)
        atmosphereRating = try container.decodeIfPresent(Double.self, forKey: .atmosphereRating)
        valueRating = try container.decodeIfPresent(Double.self, forKey: .valueRating)
        foodRating = try container.decodeIfPresent(Double.self, forKey: .foodRating)
    }
}

// PostUser struct (assuming it's not already defined elsewhere)

// Update the Cluster struct to use ClusterPost instead of ClusterRestaurant
struct PostCluster: Identifiable, Codable {
    let id: String
    let center: GeoPoint
    let posts: [ClusterIndividualPost]
    let count: Int
    var zoomLevel: String?
    var truncatedGeoHash: String?
    var geoHash: String?

    enum CodingKeys: String, CodingKey {
        case id
        case center
        case count
        case zoomLevel
        case truncatedGeoHash
        case geoHash
        case posts
    }

    // Custom initializer
    init(id: String, center: GeoPoint, posts: [ClusterIndividualPost], count: Int, zoomLevel: String? = nil, truncatedGeoHash: String? = nil, geoHash: String? = nil) {
        self.id = id
        self.center = center
        self.posts = posts
        self.count = count
        self.zoomLevel = zoomLevel
        self.truncatedGeoHash = truncatedGeoHash
        self.geoHash = geoHash
    }

    // Decoding function
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? NSUUID().uuidString
        center = try container.decode(GeoPoint.self, forKey: .center)
        posts = try container.decode([ClusterIndividualPost].self, forKey: .posts)
        count = try container.decode(Int.self, forKey: .count)
        zoomLevel = try container.decodeIfPresent(String.self, forKey: .zoomLevel)
        truncatedGeoHash = try container.decodeIfPresent(String.self, forKey: .truncatedGeoHash)
        geoHash = try container.decodeIfPresent(String.self, forKey: .geoHash)
    }
}
