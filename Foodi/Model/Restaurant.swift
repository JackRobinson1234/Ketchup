//
//  Restaurant.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Restaurant: Identifiable, Codable, Hashable {
    let id: String
    let cuisine: String?
    let price: String
    let name: String
    let latitude: Double?
    let longitude: Double?
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
        self.price = try container.decode(String.self, forKey: .price)
        self.name = try container.decode(String.self, forKey: .name)
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        self.address = try container.decodeIfPresent(String.self, forKey: .address)
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
        self.state = try container.decodeIfPresent(String.self, forKey: .state)
        self.imageURLs = try container.decodeIfPresent([String].self, forKey: .imageURLs)
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
    }
    
    init(id: String, cuisine: String? = nil, price: String, name: String, latitude: Double? = 0.0, longitude: Double? = 0.0, address: String? = nil, city: String? = nil, state: String? = nil, imageURLs: [String]? = nil, profileImageUrl: String? = nil, bio: String? = nil) {
            self.id = id
            self.cuisine = cuisine
            self.price = price
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
            self.city = city
            self.state = state
            self.imageURLs = imageURLs
            self.profileImageUrl = profileImageUrl
            self.bio = bio
        }
}
