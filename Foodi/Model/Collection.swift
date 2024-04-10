//
//  Collection.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import Foundation
import Foundation
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore

struct Collection: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var description: String?
    var items: [CollectionItem]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.items = try container.decodeIfPresent([CollectionItem].self, forKey: .items)
    }
    
    init(id: String, name: String, description: String? = nil, items: [CollectionItem]? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.items = items
    }
    
    struct CollectionItem: Codable, Hashable {
        var id: String
        var postType: String
        var name: String
        var image: String?
        var notes: String?
    }
}
