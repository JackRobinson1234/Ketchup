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
    var timestamp: Timestamp
    var description: String?
    var coverImageUrl: String?
    var items: [CollectionItem]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.timestamp = try container.decode(Timestamp.self, forKey: .timestamp)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.username = try container.decode(String.self, forKey: .username)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.coverImageUrl = try container.decodeIfPresent(String.self, forKey: .coverImageUrl)
        self.items = try container.decodeIfPresent([CollectionItem].self, forKey: .items)
        
    }
    
    init(id: String, name: String, timestamp: Timestamp, description: String? = nil, username: String, uid: String, coverImageUrl: String? = nil, items: [CollectionItem]? = nil) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.description = description
        self.username = username
        self.uid = uid
        self.coverImageUrl = coverImageUrl
        self.items = items
        
    }
    
}
struct CollectionItem: Codable, Hashable {
    var id: String
    var postType: String
    var name: String
    var image: String?
    var notes: String?
    
    //atHome post type specific
    var postUsername: String?
    
    //restaurant post type Specific
    var city: String?
    var state: String?
    var geoPoint: GeoPoint?
    
}
