//
//  Collection.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import Foundation
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore

struct Collection: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var uid: String
    var username: String
    var fullname: String
    var timestamp: Timestamp?
    var description: String?
    var coverImageUrl: String?
    var restaurantCount: Int
    var atHomeCount: Int
    var privateMode: Bool
    var profileImageUrl: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .timestamp)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.username = try container.decode(String.self, forKey: .username)
        self.fullname = try container.decode(String.self, forKey: .fullname)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.coverImageUrl = try container.decodeIfPresent(String.self, forKey: .coverImageUrl)
        self.restaurantCount = try container.decode(Int.self, forKey: .restaurantCount)
        self.atHomeCount = try container.decode(Int.self, forKey: .atHomeCount)
        self.privateMode = try container.decode(Bool.self, forKey: .privateMode)
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .coverImageUrl)
       
        
    }
    
    init(id: String, name: String, timestamp: Timestamp? = nil, description: String? = nil, username: String, fullname: String, uid: String, coverImageUrl: String? = nil, restaurantCount: Int, atHomeCount: Int, privateMode: Bool, profileImageUrl: String? = nil) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.description = description
        self.username = username
        self.fullname = fullname
        self.uid = uid
        self.coverImageUrl = coverImageUrl
        self.restaurantCount = restaurantCount
        self.atHomeCount = atHomeCount
        self.privateMode = privateMode
        self.profileImageUrl = profileImageUrl
    }
    
}

struct CollectionItem: Codable, Hashable, Identifiable {
    var collectionId: String
    var id: String
    var postType: PostType //defined in post
    var name: String
    var image: String?
    //atHome post type specific
    var postUserFullname: String?
    var postUserId: String?
    //restaurant post type Specific
    
    var city: String?
    var state: String?
    var geoPoint: GeoPoint?
    var privateMode: Bool
    
    var notes: String?
    
}
