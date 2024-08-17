//
//  User.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import FirebaseAuth
import FirebaseFirestoreInternal
import Firebase
struct User: Codable, Identifiable, Hashable {
    let id: String
    var username: String
    var fullname: String
    var phoneNumber: String?
    var profileImageUrl: String?
    var isFollowed = false
    var stats: UserStats
    var favorites: [FavoriteRestaurant]
    var privateMode: Bool
    var notificationAlert: Int = 0
    var location: Location?
    var birthday: Date?
    
    // New properties with default values
    var hasCompletedSetup: Bool = false
    var createdAt: Date?
    var lastActive: Date?

    var isCurrentUser: Bool {
        return id == Auth.auth().currentUser?.uid
    }
    
    enum CodingKeys: String, CodingKey {
        case id, username, fullname, phoneNumber, profileImageUrl, isFollowed, stats, favorites, privateMode, notificationAlert, location, birthday, hasCompletedSetup, createdAt, lastActive
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.username = try container.decode(String.self, forKey: .username)
        self.fullname = try container.decode(String.self, forKey: .fullname)
        self.phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.isFollowed = try container.decodeIfPresent(Bool.self, forKey: .isFollowed) ?? false
        self.stats = try container.decodeIfPresent(UserStats.self, forKey: .stats) ?? UserStats(following: 0, followers: 0, posts: 0, collections: 0)
        self.favorites = try container.decode([FavoriteRestaurant].self, forKey: .favorites)
        self.privateMode = try container.decode(Bool.self, forKey: .privateMode)
        self.notificationAlert = try container.decodeIfPresent(Int.self, forKey: .notificationAlert) ?? 0
        self.location = try container.decodeIfPresent(Location.self, forKey: .location)
        
        // Decode new birthday property
        if let birthdayTimestamp = try container.decodeIfPresent(Timestamp.self, forKey: .birthday) {
            self.birthday = birthdayTimestamp.dateValue()
        } else {
            self.birthday = nil
        }

        // Decode new hasCompletedSetup property, defaulting to false if not present
        self.hasCompletedSetup = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedSetup) ?? false

        // Decode new createdAt property
        if let createdAtTimestamp = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt) {
            self.createdAt = createdAtTimestamp.dateValue()
        } else {
            self.createdAt = nil
        }

        // Decode new lastActive property
        if let lastActiveTimestamp = try container.decodeIfPresent(Timestamp.self, forKey: .lastActive) {
            self.lastActive = lastActiveTimestamp.dateValue()
        } else {
            self.lastActive = nil
        }
    }
    
    init(id: String, username: String, fullname: String, phoneNumber: String? = nil, profileImageUrl: String? = nil, privateMode: Bool, notificationAlert: Int = 0, location: Location? = nil, birthday: Date? = nil, hasCompletedSetup: Bool = false, createdAt: Date? = nil, lastActive: Date? = nil) {
        self.id = id
        self.username = username
        self.fullname = fullname
        self.phoneNumber = phoneNumber
        self.profileImageUrl = profileImageUrl
        self.isFollowed = false
        self.stats = .init(following: 0, followers: 0, posts: 0, collections: 0)
        self.favorites = [
            FavoriteRestaurant(name: "", id: NSUUID().uuidString, restaurantProfileImageUrl: ""),
            FavoriteRestaurant(name: "", id: NSUUID().uuidString, restaurantProfileImageUrl: ""),
            FavoriteRestaurant(name: "", id: NSUUID().uuidString, restaurantProfileImageUrl: ""),
            FavoriteRestaurant(name: "", id: NSUUID().uuidString, restaurantProfileImageUrl: "")
        ]
        self.privateMode = privateMode
        self.notificationAlert = notificationAlert
        self.location = location
        self.birthday = birthday
        self.hasCompletedSetup = hasCompletedSetup
        self.createdAt = createdAt
        self.lastActive = lastActive
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(fullname, forKey: .fullname)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(isFollowed, forKey: .isFollowed)
        try container.encode(stats, forKey: .stats)
        try container.encode(favorites, forKey: .favorites)
        try container.encode(privateMode, forKey: .privateMode)
        try container.encode(notificationAlert, forKey: .notificationAlert)
        try container.encodeIfPresent(location, forKey: .location)
        
        // Encode new birthday property
        if let birthday = birthday {
            try container.encode(Timestamp(date: birthday), forKey: .birthday)
        }

        // Encode new hasCompletedSetup property
        try container.encode(hasCompletedSetup, forKey: .hasCompletedSetup)

        // Encode new createdAt property
        if let createdAt = createdAt {
            try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        }

        // Encode new lastActive property
        if let lastActive = lastActive {
            try container.encode(Timestamp(date: lastActive), forKey: .lastActive)
        }
    }
}

// Other structs remain unchanged
struct UserStats: Codable, Hashable {
    var following: Int
    var followers: Int
    var posts: Int
    var collections: Int
}

struct FavoriteRestaurant: Codable, Hashable, Identifiable {
    var name: String
    let id: String
    var restaurantProfileImageUrl: String?
}

struct Location: Codable, Hashable {
    var city: String?
    var state: String?
    var geoPoint: GeoPoint?
    var _geoLoc: geoLoc?
}
