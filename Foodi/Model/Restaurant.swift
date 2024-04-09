//
//  Restaurant.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore

struct Restaurant: Identifiable, Codable, Hashable {
    let id: String
    let cuisine: String?
    let price: String?
    let name: String
    let geoPoint: GeoPoint?
    let geoHash: String?
    let address: String?
    let city: String?
    let state: String?
    var imageURLs: [String]?
    var profileImageUrl: String?
    var bio: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.cuisine = try container.decode(String.self, forKey: .cuisine)
        self.price = try container.decodeIfPresent(String.self, forKey: .price)
        self.name = try container.decode(String.self, forKey: .name)
        self.geoPoint = try container.decodeIfPresent(GeoPoint.self, forKey: .geoPoint)
        self.geoHash = try container.decodeIfPresent(String.self, forKey: .geoHash)
        self.address = try container.decodeIfPresent(String.self, forKey: .address)
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
        self.state = try container.decodeIfPresent(String.self, forKey: .state)
        self.imageURLs = try container.decodeIfPresent([String].self, forKey: .imageURLs)
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
    }
    
    init(id: String, cuisine: String? = nil, price: String? = nil, name: String, geoPoint: GeoPoint? = nil, geoHash: String? = nil, address: String? = nil, city: String? = nil, state: String? = nil, imageURLs: [String]? = nil, profileImageUrl: String? = nil, bio: String? = nil) {
        self.id = id
        self.cuisine = cuisine
        self.price = price
        self.name = name
        self.geoPoint = geoPoint
        self.geoHash = geoHash
        self.address = address
        self.city = city
        self.state = state
        self.imageURLs = imageURLs
        self.profileImageUrl = profileImageUrl
        self.bio = bio
    }
    var coordinates: CLLocationCoordinate2D? {
        if let point = self.geoPoint {
            return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)}
        else{
            return nil
        }
    }
}


