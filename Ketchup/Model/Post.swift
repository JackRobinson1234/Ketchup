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
import MapKit

struct Post: Identifiable, Codable {
    let id: String
    let mediaType: MediaType
    var mediaUrls: [String]
    var mixedMediaUrls: [MixedMediaItem]?
    var caption: String
    var likes: Int
    var commentCount: Int
    var repostCount: Int
    var bookmarkCount: Int
    var thumbnailUrl: String
    var timestamp: Timestamp?
    var user: PostUser
    var restaurant: PostRestaurant
    var didLike: Bool
    var didBookmark: Bool
    var fromInAppCamera: Bool
    var repost: Bool
    var didRepost: Bool
    var overallRating: Double?
    var serviceRating: Double?
    var atmosphereRating: Double?
    var valueRating: Double?
    var foodRating: Double?
    var taggedUsers: [PostUser]
    var captionMentions: [PostUser]
    var isReported: Bool // Property for reported status
    var goodFor: [String]? // New optional array of strings
    var coordinates: CLLocationCoordinate2D? {
        if let point = self.restaurant.geoPoint {
            return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        } else {
            return nil
        }
    }
    

    // Decoding initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        self.mediaUrls = try container.decodeIfPresent([String].self, forKey: .mediaUrls) ?? []
        self.mixedMediaUrls = try container.decodeIfPresent([MixedMediaItem].self, forKey: .mixedMediaUrls)
        self.caption = try container.decode(String.self, forKey: .caption)
        self.likes = try container.decode(Int.self, forKey: .likes)
        self.commentCount = try container.decode(Int.self, forKey: .commentCount)
        self.repostCount = try container.decode(Int.self, forKey: .repostCount)
        self.bookmarkCount = try container.decodeIfPresent(Int.self, forKey: .bookmarkCount) ?? 0
        self.thumbnailUrl = try container.decode(String.self, forKey: .thumbnailUrl)
        self.timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .timestamp)
        self.user = try container.decode(PostUser.self, forKey: .user)
        self.restaurant = try container.decode(PostRestaurant.self, forKey: .restaurant)
        self.didLike = try container.decodeIfPresent(Bool.self, forKey: .didLike) ?? false
        self.didBookmark = try container.decodeIfPresent(Bool.self, forKey: .didBookmark) ?? false
        self.fromInAppCamera = try container.decode(Bool.self, forKey: .fromInAppCamera)
        self.repost = try container.decodeIfPresent(Bool.self, forKey: .repost) ?? false
        self.didRepost = try container.decodeIfPresent(Bool.self, forKey: .didRepost) ?? false
        self.overallRating = try container.decodeIfPresent(Double.self, forKey: .overallRating)
        self.serviceRating = try container.decodeIfPresent(Double.self, forKey: .serviceRating)
        self.atmosphereRating = try container.decodeIfPresent(Double.self, forKey: .atmosphereRating)
        self.valueRating = try container.decodeIfPresent(Double.self, forKey: .valueRating)
        self.foodRating = try container.decodeIfPresent(Double.self, forKey: .foodRating)
        self.taggedUsers = try container.decodeIfPresent([PostUser].self, forKey: .taggedUsers) ?? []
        self.captionMentions = try container.decodeIfPresent([PostUser].self, forKey: .captionMentions) ?? []
        self.isReported = try container.decodeIfPresent(Bool.self, forKey: .isReported) ?? false
        self.goodFor = try container.decodeIfPresent([String].self, forKey: .goodFor) // Decode new property
    }

    // New initializer with goodFor array
    init(
        id: String,
        mediaType: MediaType,
        mediaUrls: [String] = [],
        mixedMediaUrls: [MixedMediaItem]? = nil,
        caption: String,
        likes: Int,
        commentCount: Int,
        bookmarkCount: Int,
        repostCount: Int,
        thumbnailUrl: String,
        timestamp: Timestamp?,
        user: PostUser,
        restaurant: PostRestaurant,
        didLike: Bool = false,
        didBookmark: Bool = false,
        fromInAppCamera: Bool,
        repost: Bool = false,
        didRepost: Bool = false,
        overallRating: Double? = nil,
        serviceRating: Double? = nil,
        atmosphereRating: Double? = nil,
        valueRating: Double? = nil,
        foodRating: Double? = nil,
        taggedUsers: [PostUser] = [],
        captionMentions: [PostUser] = [],
        isReported: Bool = false,
        goodFor: [String]? = nil // New parameter with default value
    ) {
        self.id = id
        self.mediaType = mediaType
        self.mediaUrls = mediaUrls
        self.mixedMediaUrls = mixedMediaUrls
        self.caption = caption
        self.likes = likes
        self.commentCount = commentCount
        self.bookmarkCount = bookmarkCount
        self.repostCount = repostCount
        self.thumbnailUrl = thumbnailUrl
        self.timestamp = timestamp
        self.user = user
        self.restaurant = restaurant
        self.didLike = didLike
        self.didBookmark = didBookmark
        self.fromInAppCamera = fromInAppCamera
        self.repost = repost
        self.didRepost = didRepost
        self.overallRating = overallRating
        self.serviceRating = serviceRating
        self.atmosphereRating = atmosphereRating
        self.valueRating = valueRating
        self.foodRating = foodRating
        self.taggedUsers = taggedUsers
        self.captionMentions = captionMentions
        self.isReported = isReported
        self.goodFor = goodFor // Set new property
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
    var truncatedGeohash: String?
    var truncatedGeohash5: String?
    var truncatedGeohash6: String?
    var address: String?
    var city: String?
    var state: String?
    var profileImageUrl: String?
    var cuisine: String?
    var price: String?
    var macroCategory: String?
}

struct PostUser: Codable, Hashable, Identifiable {
    let id: String
    let fullname: String
    var profileImageUrl: String? = nil
    var privateMode: Bool
    var username: String
    var statusNameImage: String? = "BEGINNER2"
}

enum MediaType: Int, Codable {
    case video
    case photo
    case written
    case mixed
    var text: String {
        switch self {
        case .video: return "Video"
        case .photo: return "Photo"
        case .written: return "Written"
        case .mixed: return "Mixed"
        }
    }
}

struct MixedMediaItem: Codable, Hashable, Identifiable {
    let id: String
    var url: String
    var type: MediaType
    var description: String?
    var descriptionCategory: DescriptionCategory?

    init(id: String = NSUUID().uuidString, url: String, type: MediaType, description: String? = nil, descriptionCategory: DescriptionCategory? = nil) {
        self.id = id
        self.url = url
        self.type = type
        self.description = description
        self.descriptionCategory = descriptionCategory
    }
}

extension Post: Commentable {
    var ownerUid: String? {
        return user.id
    }
    
    var commentsCollectionPath: String {
        return "posts/\(id)/post-comments"
    }
}


protocol Commentable {
    var id: String { get }
    var ownerUid: String? { get }
    var commentCount: Int { get set }
    var commentsCollectionPath: String { get }
}
enum DescriptionCategory: String, Codable, Hashable, CaseIterable {
    case food
    case menu
    case atmosphere
    case other
}
