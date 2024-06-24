//
//  Review.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import Foundation
import Firebase
import SwiftUI
import AVKit
import FirebaseFirestore

struct Review: Identifiable, Codable, Hashable, Equatable{
    let id: String
    let description: String
    var likes: Int
    var timestamp: Timestamp
    var user: ReviewUser
    var restaurant: ReviewRestaurant
    var didLike = false
    var recommendation: Bool
    var favoriteItems: [String]?
    var serviceRating: Bool?
    var atmosphereRating: Bool?
    var valueRating: Bool?
    var foodRating: Bool?
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
               self.id = try container.decode(String.self, forKey: .id)
               self.description = try container.decode(String.self, forKey: .description)
               self.likes = try container.decode(Int.self, forKey: .likes)
               self.timestamp = try container.decode(Timestamp.self, forKey: .timestamp)
               self.user = try container.decode(ReviewUser.self, forKey: .user)
               self.restaurant = try container.decode(ReviewRestaurant.self, forKey: .restaurant)
               self.didLike = try container.decodeIfPresent(Bool.self, forKey: .didLike) ?? false
               self.recommendation = try container.decode(Bool.self, forKey: .recommendation)
               self.favoriteItems = try container.decodeIfPresent([String].self, forKey: .favoriteItems)
    }
    
    init(
        id: String,
        description: String,
        likes: Int,
        timestamp: Timestamp,
        user: ReviewUser,
        restaurant: ReviewRestaurant,
        didLike: Bool = false,
        recommendation: Bool,
        favoriteItems: [String]? = nil
    ) {
        self.id = id
        self.description = description
        self.likes = likes
        self.timestamp = timestamp
        self.user = user
        self.restaurant = restaurant
        self.didLike = didLike
        self.recommendation = recommendation
        self.favoriteItems = favoriteItems
    }
}



struct ReviewRestaurant: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let geoPoint: GeoPoint?
    let geoHash: String?
    let address: String?
    let city: String?
    let state: String?
    var profileImageUrl: String?
    
}

struct ReviewUser: Codable, Hashable, Identifiable {
    let id: String
    let fullname: String
    var profileImageUrl: String? = nil
    var privateMode: Bool
    var username: String
}

