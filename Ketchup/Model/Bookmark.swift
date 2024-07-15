//
//  Bookmark.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/15/24.
//

import Foundation
import FirebaseFirestoreInternal
struct Bookmark: Identifiable, Codable, Equatable{
    let id: String
    var restaurantId: String
    var restaurantName: String
    var restaurantCity: String?
    var retaurantState: String?
    var geoPoint: GeoPoint?
    var postIds: [String]?
    let timestamp: Timestamp
    var image: String?
}
