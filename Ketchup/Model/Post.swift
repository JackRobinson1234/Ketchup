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
    var postType: PostType
    let mediaType: String // either "video" or "image"
    let mediaUrls: [String]
    let caption: String
    var likes: Int
    var commentCount: Int
    var repostCount: Int
    var thumbnailUrl: String
    var timestamp: Timestamp?
    var user: PostUser
    var restaurant: PostRestaurant? = nil
    var recipe: PostRecipe? = nil
    var cuisine: String?
    var price: String?
    var didLike: Bool
    var didSave: Bool
    var fromInAppCamera: Bool
    var repost: Bool
    var didRepost: Bool
    var cookingTitle: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.postType = try container.decode(PostType.self, forKey: .postType)
        self.mediaType = try container.decode(String.self, forKey: .mediaType)
        self.mediaUrls = try container.decode([String].self, forKey: .mediaUrls)
        self.caption = try container.decode(String.self, forKey: .caption)
        self.likes = try container.decode(Int.self, forKey: .likes)
        self.commentCount = try container.decode(Int.self, forKey: .commentCount)
        self.repostCount = try container.decode(Int.self, forKey: .repostCount)
        self.thumbnailUrl = try container.decode(String.self, forKey: .thumbnailUrl)
        self.timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .timestamp)
        self.user = try container.decode(PostUser.self, forKey: .user)
        self.restaurant = try container.decodeIfPresent(PostRestaurant.self, forKey: .restaurant)
        self.recipe = try container.decodeIfPresent(PostRecipe.self, forKey: .recipe)
        self.cuisine = try container.decodeIfPresent(String.self, forKey: .cuisine)
        self.price = try container.decodeIfPresent(String.self, forKey: .price)
        self.didLike = try container.decodeIfPresent(Bool.self, forKey: .didLike) ?? false
        self.didSave = try container.decodeIfPresent(Bool.self, forKey: .didSave) ?? false
        self.fromInAppCamera = try container.decode(Bool.self, forKey: .fromInAppCamera)
        self.repost = try container.decodeIfPresent(Bool.self, forKey: .repost) ?? false
        self.didRepost = try container.decodeIfPresent(Bool.self, forKey: .didRepost) ?? false
        self.cookingTitle = try container.decodeIfPresent(String.self, forKey: .cookingTitle)
    
    }
    
    init(
        id: String,
        postType: PostType,
        mediaType: String,
        mediaUrls: [String],
        caption: String,
        likes: Int,
        commentCount: Int,
        repostCount: Int,
        thumbnailUrl: String,
        timestamp: Timestamp?,
        user: PostUser,
        restaurant: PostRestaurant? = nil,
        recipe: PostRecipe? = nil,
        cuisine: String? = nil,
        price: String? = nil,
        didLike: Bool = false,
        didSave: Bool = false,
        fromInAppCamera: Bool,
        repost: Bool = false,
        didRepost: Bool = false,
        cookingTitle: String? = nil
    ) {
        self.id = id
        self.postType = postType
        self.mediaType = mediaType
        self.mediaUrls = mediaUrls
        self.caption = caption
        self.likes = likes
        self.commentCount = commentCount
        self.repostCount = repostCount
        self.thumbnailUrl = thumbnailUrl
        self.timestamp = timestamp
        self.user = user
        self.restaurant = restaurant
        self.recipe = recipe
        self.cuisine = cuisine
        self.price = price
        self.didLike = didLike
        self.didSave = didSave
        self.fromInAppCamera = fromInAppCamera
        self.repost = repost
        self.didRepost = didRepost
        self.cookingTitle = cookingTitle
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
    var name: String
    var geoPoint: GeoPoint?
    var geoHash: String?
    var address: String?
    var city: String?
    var state: String?
    var profileImageUrl: String?
}

struct PostUser: Codable, Hashable, Identifiable {
    let id: String
    let fullname: String
    var profileImageUrl: String? = nil
    var privateMode: Bool
    var username: String
}

struct PostRecipe: Codable, Hashable {
    var cookingTime: Int?
    var dietary: [String]?
    var instructions: [Instruction]?
    var ingredients: [Ingredient]?
    var difficulty: RecipeDifficulty?
    var servings: Int?
}

struct Instruction: Codable, Hashable {
    var title: String
    var description: String
}

struct Ingredient: Codable, Hashable {
    var quantity: String
    var item: String
}

enum PostType: Int, Codable {
    case dining
    case cooking
    var postTypeTitle: String {
        switch self {
        case .dining: return "Dining"
        case .cooking: return "Cooking"
       
        }
    }
}

enum RecipeDifficulty: Int, Codable {
    case easy
    case medium
    case hard
    var text: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
            
        }
    }
}



