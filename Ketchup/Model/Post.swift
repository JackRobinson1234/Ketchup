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
    let mediaType: String // either "video" or "image"
    var mediaUrls: [String]
    let caption: String
    var likes: Int
    var commentCount: Int
    var repostCount: Int
    var thumbnailUrl: String
    var timestamp: Timestamp?
    var user: PostUser
    var restaurant: PostRestaurant? = nil
    var didLike: Bool
    var didSave: Bool
    var fromInAppCamera: Bool
    var repost: Bool
    var didRepost: Bool
    var overallRating: Int?
    var serviceRating: Int?
    var atmosphereRating: Int?
    var valueRating: Int?
    var foodRating: Int?
    var favoriteItems: [String]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
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
        self.didLike = try container.decodeIfPresent(Bool.self, forKey: .didLike) ?? false
        self.didSave = try container.decodeIfPresent(Bool.self, forKey: .didSave) ?? false
        self.fromInAppCamera = try container.decode(Bool.self, forKey: .fromInAppCamera)
        self.repost = try container.decodeIfPresent(Bool.self, forKey: .repost) ?? false
        self.didRepost = try container.decodeIfPresent(Bool.self, forKey: .didRepost) ?? false
        self.overallRating = try container.decodeIfPresent(Int.self, forKey: .overallRating)
        self.serviceRating = try container.decodeIfPresent(Int.self, forKey: .serviceRating)
        self.atmosphereRating = try container.decodeIfPresent(Int.self, forKey: .atmosphereRating)
        self.valueRating = try container.decodeIfPresent(Int.self, forKey: .valueRating)
        self.foodRating = try container.decodeIfPresent(Int.self, forKey: .foodRating)
        self.favoriteItems = try container.decodeIfPresent([String].self, forKey: .favoriteItems)
    }

    init(
        id: String,
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
        didLike: Bool = false,
        didSave: Bool = false,
        fromInAppCamera: Bool,
        repost: Bool = false,
        didRepost: Bool = false,
        overallRating: Int? = nil,
        serviceRating: Int? = nil,
        atmosphereRating: Int? = nil,
        valueRating: Int? = nil,
        foodRating: Int? = nil,
        favoriteItems: [String]? = nil
    ) {
        self.id = id
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
        self.didLike = didLike
        self.didSave = didSave
        self.fromInAppCamera = fromInAppCamera
        self.repost = repost
        self.didRepost = didRepost
        self.overallRating = overallRating
        self.serviceRating = serviceRating
        self.atmosphereRating = atmosphereRating
        self.valueRating = valueRating
        self.foodRating = foodRating
        self.favoriteItems = favoriteItems
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
    var cuisine: String?
    var price: String?
}

struct PostUser: Codable, Hashable, Identifiable {
    let id: String
    let fullname: String
    var profileImageUrl: String? = nil
    var privateMode: Bool
    var username: String
}




