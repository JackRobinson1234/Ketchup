//
//  Cluster.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/4/24.
//
import MapKit
import Foundation
import FirebaseFirestoreInternal
struct Cluster: Identifiable, Codable {
    var id: String?
    var center: GeoPoint
    var count: Int
    var restaurantIds: [String]
    var zoomLevel: String

    enum CodingKeys: String, CodingKey {
        case id
        case center
        case count
        case restaurantIds = "restaurant_ids"
        case zoomLevel
    }

    // Custom initializer
    init(id: String? = nil, center: GeoPoint, count: Int = 0, restaurantIds: [String] = [], zoomLevel: String) {
        self.id = id
        self.center = center
        self.count = count
        self.restaurantIds = restaurantIds
        self.zoomLevel = zoomLevel
    }

    // Encoding function
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(center, forKey: .center)
        try container.encode(count, forKey: .count)
        try container.encode(restaurantIds, forKey: .restaurantIds)
        try container.encode(zoomLevel, forKey: .zoomLevel)
    }

    // Decoding function
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        center = try container.decode(GeoPoint.self, forKey: .center)
        count = try container.decode(Int.self, forKey: .count)
        restaurantIds = try container.decode([String].self, forKey: .restaurantIds)
        zoomLevel = try container.decode(String.self, forKey: .zoomLevel)
    }
}
