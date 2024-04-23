//
//  Post.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import Firebase
import SwiftUI
import AVKit
import FirebaseFirestore

struct Post: Identifiable, Codable {
    let id: String
    var postType: String // either "restaurant" or "atHome"
    let mediaType: String //either "video" or "image"
    let mediaUrls: [String]
    let caption: String
    var likes: Int
    var commentCount: Int
    var shareCount: Int
    var thumbnailUrl: String
    var timestamp: Timestamp?
    var user: PostUser
    var restaurant: PostRestaurant? = nil
    var recipe: PostRecipe? = nil
    var cuisine: String?
    var price: String?
    var didLike = false
    var didSave = false
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.postType = try container.decode(String.self, forKey: .postType)
        self.mediaType = try container.decode(String.self, forKey: .mediaType)
        self.mediaUrls = try container.decode([String].self, forKey: .mediaUrls)
        self.caption = try container.decode(String.self, forKey: .caption)
        self.likes = try container.decode(Int.self, forKey: .likes)
        self.commentCount = try container.decode(Int.self, forKey: .commentCount)
        self.shareCount = try container.decode(Int.self, forKey: .shareCount)
        self.thumbnailUrl = try container.decode(String.self, forKey: .thumbnailUrl)
        self.timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .timestamp)
        self.user = try container.decode(PostUser.self, forKey: .user)
        self.restaurant = try container.decodeIfPresent(PostRestaurant.self, forKey: .restaurant)
        self.recipe = try container.decodeIfPresent(PostRecipe.self, forKey: .recipe)
        self.cuisine = try container.decodeIfPresent(String.self, forKey: .cuisine)
        self.price = try container.decodeIfPresent(String.self, forKey: .price)
        self.didLike = try container.decodeIfPresent(Bool.self, forKey: .didLike) ?? false
        self.didSave = try container.decodeIfPresent(Bool.self, forKey: .didSave) ?? false
    }
    
    init(
        id: String,
        postType: String,
        mediaType: String,
        mediaUrls: [String],
        caption: String,
        likes: Int,
        commentCount: Int,
        shareCount: Int,
        thumbnailUrl: String,
        timestamp: Timestamp? = nil,
        user: PostUser,
        restaurant: PostRestaurant? = nil,
        recipe: PostRecipe? = nil,
        cuisine: String? = nil,
        price: String? = nil,
        didLike: Bool = false,
        didSave: Bool = false
    ) 
    {
        self.id = id
        self.postType = postType
        self.mediaType = mediaType
        self.mediaUrls = mediaUrls
        self.caption = caption
        self.likes = likes
        self.commentCount = commentCount
        self.shareCount = shareCount
        self.thumbnailUrl = thumbnailUrl
        self.timestamp = timestamp
        self.user = user
        self.restaurant = restaurant
        self.recipe = recipe
        self.cuisine = cuisine
        self.price = price
        self.didLike = didLike
        self.didSave = didSave
    }
}

extension Post: Hashable { }

extension Post: Equatable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PostRestaurant: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let geoPoint: GeoPoint?
    let geoHash: String?
    let address: String?
    let city: String?
    let state: String?
    var profileImageUrl: String?
    
}

struct PostUser: Codable, Hashable, Identifiable {
    let id: String
    let fullName: String
    let profileImageUrl: String?
}

struct PostRecipe: Codable, Hashable {
    var name: String
    var cookingTime: Int?
    var dietary: [String]?
    var instructions: [Instruction]?
    var ingredients: [Ingredient]?
}

struct Instruction: Codable, Hashable {
    var title: String
    var description: String
}

struct Ingredient: Codable, Hashable {
    var quantity: String
    var item: String
}


