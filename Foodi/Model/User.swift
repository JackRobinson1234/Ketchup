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
    let email: String
    var fullname: String
    var bio: String?
    var profileImageUrl: String?
    var isFollowed = false
    var stats: UserStats
    var isCurrentUser: Bool {
        return id == Auth.auth().currentUser?.uid
    }
    var favorites: [favoriteRestaurants]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.username = try container.decode(String.self, forKey: .username)
        self.email = try container.decode(String.self, forKey: .email)
        self.fullname = try container.decode(String.self, forKey: .fullname)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.isFollowed = try container.decodeIfPresent(Bool.self, forKey: .isFollowed) ?? false
        self.stats = try container.decodeIfPresent(UserStats.self, forKey: .stats) ?? UserStats(following: 0, followers: 0, likes: 0)
        self.favorites = try container.decodeIfPresent([favoriteRestaurants].self, forKey: .favorites)
    }
    
    init(id: String, username: String, email: String, fullname: String, bio: String? = nil, profileImageUrl: String? = nil, favorites: [favoriteRestaurants]? = []) {
        self.id = id
        self.username = username
        self.email = email
        self.fullname = fullname
        self.bio = bio
        self.profileImageUrl = profileImageUrl
        self.isFollowed = false
        self.stats = .init(following: 0, followers: 0, likes: 0)
        self.favorites = favorites
    }
}

extension User: Hashable { }

struct UserStats: Codable, Hashable {
    var following: Int
    var followers: Int
    var likes: Int
}

struct favorites: Codable, Hashable {
    var Restaurant: [favoriteRestaurants]?
}

struct favoriteRestaurants: Codable, Hashable, Identifiable {
    var name: String
    let id: String
    var restaurantProfileImageUrl: String?
}

