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
    let caption: String
    var likes: Int
    var commentCount: Int
    var repostCount: Int
    var thumbnailUrl: String
    var timestamp: Timestamp?
    var user: PostUser
    var restaurant: PostRestaurant
    var didLike: Bool
    var didSave: Bool
    var fromInAppCamera: Bool
    var repost: Bool
    var didRepost: Bool
    var overallRating: Int
    var serviceRating: Int
    var atmosphereRating: Int
    var valueRating: Int
    var foodRating: Int
    var coordinates: CLLocationCoordinate2D? {
        if let point = self.restaurant.geoPoint {
            return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)}
        else{
            return nil
        }
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        self.mediaUrls = try container.decode([String].self, forKey: .mediaUrls)
        self.caption = try container.decode(String.self, forKey: .caption)
        self.likes = try container.decode(Int.self, forKey: .likes)
        self.commentCount = try container.decode(Int.self, forKey: .commentCount)
        self.repostCount = try container.decode(Int.self, forKey: .repostCount)
        self.thumbnailUrl = try container.decode(String.self, forKey: .thumbnailUrl)
        self.timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .timestamp)
        self.user = try container.decode(PostUser.self, forKey: .user)
        self.restaurant = try container.decode(PostRestaurant.self, forKey: .restaurant)
        self.didLike = try container.decodeIfPresent(Bool.self, forKey: .didLike) ?? false
        self.didSave = try container.decodeIfPresent(Bool.self, forKey: .didSave) ?? false
        self.fromInAppCamera = try container.decode(Bool.self, forKey: .fromInAppCamera)
        self.repost = try container.decodeIfPresent(Bool.self, forKey: .repost) ?? false
        self.didRepost = try container.decodeIfPresent(Bool.self, forKey: .didRepost) ?? false
        self.overallRating = try container.decode(Int.self, forKey: .overallRating)
        self.serviceRating = try container.decode(Int.self, forKey: .serviceRating)
        self.atmosphereRating = try container.decode(Int.self, forKey: .atmosphereRating)
        self.valueRating = try container.decode(Int.self, forKey: .valueRating)
        self.foodRating = try container.decode(Int.self, forKey: .foodRating)
        
    }

    init(
        id: String,
        mediaType: MediaType,
        mediaUrls: [String],
        caption: String,
        likes: Int,
        commentCount: Int,
        repostCount: Int,
        thumbnailUrl: String,
        timestamp: Timestamp?,
        user: PostUser,
        restaurant: PostRestaurant,
        didLike: Bool = false,
        didSave: Bool = false,
        fromInAppCamera: Bool,
        repost: Bool = false,
        didRepost: Bool = false,
        overallRating: Int,
        serviceRating: Int,
        atmosphereRating: Int,
        valueRating: Int,
        foodRating: Int
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



//enum Rating: Int, Codable {
//    case zero
//    case one
//    case two
//    case three
//    case four
//    case five
//    
////    var image: Image {
////        switch self {
////        case .zero return
////        case .one: return SwiftUI.Image("Smile1")
////        case .two: return SwiftUI.Image("Smile2")
////        case .three: return SwiftUI.Image("Smile3")
////        case .four: return SwiftUI.Image("Smile4")
////        case .five: return SwiftUI.Image("Smile5")
////        }
////    }
////    static func image(forValue value: Int) -> Image {
////            guard let rating = Int(rawValue: value) else {
////                return Image("") // return a default image if needed
////            }
////            return rating.image
////        }
//}


enum MediaType: Int, Codable {
    case video
    case photo
    case written
    var text: String {
        switch self {
        case .video: return "Video"
        case .photo: return "Photo"
        case .written: return "Written"
            
        }
    }
}
