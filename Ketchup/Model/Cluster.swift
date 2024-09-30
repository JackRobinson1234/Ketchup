//
//  Cluster.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/4/24.
//
import MapKit
import Foundation
import FirebaseFirestoreInternal
import Firebase
struct Cluster: Identifiable, Codable {
    let id: String
    let center: GeoPoint
    let restaurants: [ClusterRestaurant]
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
        case restaurants
    }

    // Custom initializer
    init(id: String, center: GeoPoint, restaurants: [ClusterRestaurant], count: Int, zoomLevel: String? = nil, truncatedGeoHash: String? = nil, geoHash: String? = nil) {
        self.id = id
        self.center = center
        self.restaurants = restaurants
        self.count = count
        self.zoomLevel = zoomLevel
        self.truncatedGeoHash = truncatedGeoHash
        self.geoHash = geoHash
    }

    // Decoding function
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        center = try container.decode(GeoPoint.self, forKey: .center)
        restaurants = try container.decode([ClusterRestaurant].self, forKey: .restaurants)
        count = try container.decode(Int.self, forKey: .count)
        zoomLevel = try container.decodeIfPresent(String.self, forKey: .zoomLevel)
        truncatedGeoHash = try container.decodeIfPresent(String.self, forKey: .truncatedGeoHash)
        geoHash = try container.decodeIfPresent(String.self, forKey: .geoHash)
    }
}

struct ClusterRestaurant: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    var cuisine: String?
    var price: String?
    var profileImageUrl: String?
    var geoPoint: GeoPoint
    var fullGeoHash: String?
    var attributes: [String: Bool]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case cuisine
        case price
        case profileImageUrl
        case geoPoint
        case fullGeoHash
        case attributes
    }

    // Custom initializer
    init(id: String, name: String, geoPoint: GeoPoint, cuisine: String? = nil, price: String? = nil, profileImageUrl: String? = nil, fullGeoHash: String? = nil, attributes: [String: Bool]? = nil) {
        self.id = id
        self.name = name
        self.geoPoint = geoPoint
        self.cuisine = cuisine
        self.price = price
        self.profileImageUrl = profileImageUrl
        self.fullGeoHash = fullGeoHash
        self.attributes = attributes
    }

    // Decoding function
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        geoPoint = try container.decode(GeoPoint.self, forKey: .geoPoint)
        cuisine = try container.decodeIfPresent(String.self, forKey: .cuisine)
        price = try container.decodeIfPresent(String.self, forKey: .price)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        fullGeoHash = try container.decodeIfPresent(String.self, forKey: .fullGeoHash)
        attributes = try container.decodeIfPresent([String: Bool].self, forKey: .attributes)
    }
}

// In MapViewModel


