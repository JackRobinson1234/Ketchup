//
//  User.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import FirebaseAuth

struct User: Identifiable, Codable {
    let id: String
    var username: String
    var fullname: String
    var profileImageUrl: String?
    var isFollowed = false
    var stats: UserStats
    var isCurrentUser: Bool {
        return id == Auth.auth().currentUser?.uid
    }
    var favorites: [FavoriteRestaurant]
    var privateMode: Bool
    var notificationAlert: Bool = false
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.username = try container.decode(String.self, forKey: .username)
        self.fullname = try container.decode(String.self, forKey: .fullname)
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.isFollowed = try container.decodeIfPresent(Bool.self, forKey: .isFollowed) ?? false
        self.stats = try container.decodeIfPresent(UserStats.self, forKey: .stats) ?? UserStats(following: 0, followers: 0, posts: 0, collections: 0)
        self.favorites = try container.decode([FavoriteRestaurant].self, forKey: .favorites)
        self.privateMode = try container.decode(Bool.self, forKey: .privateMode)
        self.notificationAlert = try container.decodeIfPresent(Bool.self, forKey: .notificationAlert) ?? false
    }
    
    init(id: String, username: String, fullname: String, profileImageUrl: String? = nil, privateMode: Bool, notificationAlert: Bool = false) {
        self.id = id
        self.username = username
        self.fullname = fullname
        self.profileImageUrl = profileImageUrl
        self.isFollowed = false
        self.stats = .init(following: 0, followers: 0, posts: 0, collections: 0)
        self.favorites = [
            FavoriteRestaurant(name: "", id: NSUUID().uuidString, restaurantProfileImageUrl: ""),   FavoriteRestaurant(name: "", id: NSUUID().uuidString, restaurantProfileImageUrl: ""),   FavoriteRestaurant(name: "", id: NSUUID().uuidString, restaurantProfileImageUrl: ""),   FavoriteRestaurant(name: "", id: NSUUID().uuidString, restaurantProfileImageUrl: "")
            ]
        self.privateMode = privateMode
        self.notificationAlert = notificationAlert
    }
}

extension User: Hashable { }

struct UserStats: Codable, Hashable {
    var following: Int
    var followers: Int
    var posts: Int
    var collections: Int
}

struct Favorites: Codable, Hashable {
    var Restaurant: [FavoriteRestaurant]?
}

struct FavoriteRestaurant: Codable, Hashable, Identifiable {
    var name: String
    let id: String
    var restaurantProfileImageUrl: String?
}

