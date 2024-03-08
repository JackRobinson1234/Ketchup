//
//  Post.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import SwiftUI
import AVKit

struct Post: Identifiable, Codable {
    let id: String
    let videoUrl: String
    let caption: String
    var likes: Int
    var commentCount: Int
    var saveCount: Int
    var shareCount: Int
    var views: Int
    var thumbnailUrl: String
    var timestamp: Timestamp
    var user: postUser
    var restaurant: postRestaurant? = nil
    var recipe: postRecipe? = nil
    var brand: postBrand? = nil
    var didLike = false
    var didSave = false
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.videoUrl = try container.decode(String.self, forKey: .videoUrl)
        self.caption = try container.decode(String.self, forKey: .caption)
        self.likes = try container.decode(Int.self, forKey: .likes)
        self.commentCount = try container.decode(Int.self, forKey: .commentCount)
        self.saveCount = try container.decode(Int.self, forKey: .saveCount)
        self.shareCount = try container.decode(Int.self, forKey: .shareCount)
        self.views = try container.decode(Int.self, forKey: .views)
        self.thumbnailUrl = try container.decode(String.self, forKey: .thumbnailUrl)
        self.timestamp = try container.decode(Timestamp.self, forKey: .timestamp)
        self.user = try container.decode(postUser.self, forKey: .user)
        self.restaurant = try container.decodeIfPresent(postRestaurant.self, forKey: .restaurant)
        self.didLike = try container.decodeIfPresent(Bool.self, forKey: .didLike) ?? false
        self.didSave = try container.decodeIfPresent(Bool.self, forKey: .didSave) ?? false
        self.recipe = try container.decodeIfPresent(postRecipe.self, forKey: .recipe)
        self.brand = try container.decodeIfPresent(postBrand.self, forKey: .brand)
    }
    
    init(
        id: String,
        videoUrl: String,
        caption: String,
        likes: Int,
        commentCount: Int,
        saveCount: Int,
        shareCount: Int,
        views: Int,
        thumbnailUrl: String,
        timestamp: Timestamp,
        user: postUser,
        restaurant: postRestaurant? = nil,
        didLike: Bool = false,
        didSave: Bool = false,
        recipe: postRecipe? = nil,
        brand: postBrand? = nil
    ) {
        self.id = id
        self.videoUrl = videoUrl
        self.caption = caption
        self.likes = likes
        self.commentCount = commentCount
        self.saveCount = saveCount
        self.shareCount = shareCount
        self.views = views
        self.thumbnailUrl = thumbnailUrl
        self.timestamp = timestamp
        self.user = user
        self.didLike = didLike
        self.restaurant = restaurant
        self.didSave = didSave
        self.recipe = recipe
        self.brand = brand
    }
}

extension Post: Hashable { }

extension Post: Equatable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
}

struct postRestaurant: Codable, Hashable, Identifiable {
    let id: String
    let cuisine: String?
    let price: String?
    let name: String
    let geoPoint: GeoPoint?
    let address: String?
    let city: String?
    let state: String?
    var profileImageUrl: String?
    
}

struct postUser: Codable, Hashable, Identifiable {
    let id: String
    let fullname: String
    let profileImageUrl: String?
}

struct postRecipe: Codable, Hashable {
    var name: String
    var cuisine: String?
    var time: Int?
    var dietary: [String]?
    var instructions: [instruction]?
    var ingredients: [ingredient]?
}

struct instruction: Codable, Hashable {
    var title: String
    var description: String
}

struct ingredient: Codable, Hashable {
    var quantity: String
    var item: String
}

struct postBrand: Codable, Hashable {
    var name: String
    var price: Int
}
