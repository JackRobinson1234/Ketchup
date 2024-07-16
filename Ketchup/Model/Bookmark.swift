//
//  Bookmark.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/15/24.
//

import Foundation
import FirebaseFirestoreInternal
struct Bookmark: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var restaurantName: String
    var restaurantCity: String?
    var restaurantState: String?
    var geoPoint: GeoPoint?
    let timestamp: Timestamp
    var image: String?

    enum CodingKeys: String, CodingKey {
        case id
        case restaurantName
        case restaurantCity
        case restaurantState
        case geoPoint
        case timestamp
        case image
    }
    
    init(id: String,
         restaurantName: String,
         restaurantCity: String? = nil,
         restaurantState: String? = nil,
         geoPoint: GeoPoint? = nil,
         timestamp: Timestamp,
         image: String? = nil) {
        self.id = id
        self.restaurantName = restaurantName
        self.restaurantCity = restaurantCity
        self.restaurantState = restaurantState
        self.geoPoint = geoPoint
        self.timestamp = timestamp
        self.image = image
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        restaurantName = try container.decode(String.self, forKey: .restaurantName)
        restaurantCity = try container.decodeIfPresent(String.self, forKey: .restaurantCity)
        restaurantState = try container.decodeIfPresent(String.self, forKey: .restaurantState)
        geoPoint = try container.decodeIfPresent(GeoPoint.self, forKey: .geoPoint)
        timestamp = try container.decode(Timestamp.self, forKey: .timestamp)
        image = try container.decodeIfPresent(String.self, forKey: .image)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(restaurantName, forKey: .restaurantName)
        try container.encodeIfPresent(restaurantCity, forKey: .restaurantCity)
        try container.encodeIfPresent(restaurantState, forKey: .restaurantState)
        try container.encodeIfPresent(geoPoint, forKey: .geoPoint)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(image, forKey: .image)
    }
}
