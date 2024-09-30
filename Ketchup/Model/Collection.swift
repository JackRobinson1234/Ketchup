//
//  Collection.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import Foundation
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore

struct Collection: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var uid: String
    var username: String
    var fullname: String
    var timestamp: Timestamp?
    var description: String?
    var coverImageUrl: String?
    var restaurantCount: Int
    var privateMode: Bool
    var profileImageUrl: String?
    var tempImageUrls: [String]?
    var likes: Int
    var didLike: Bool = false
    var collaborators: [String] // List of user IDs who are collaborators
    var pendingInvitations: [String] // List of user IDs who have been invited but not yet accepted

    enum CodingKeys: String, CodingKey {
        case id, name, uid, username, fullname, timestamp, description, coverImageUrl, restaurantCount, privateMode, profileImageUrl, tempImageUrls, likes, collaborators, pendingInvitations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .timestamp)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.username = try container.decode(String.self, forKey: .username)
        self.fullname = try container.decode(String.self, forKey: .fullname)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.coverImageUrl = try container.decodeIfPresent(String.self, forKey: .coverImageUrl)
        self.restaurantCount = try container.decode(Int.self, forKey: .restaurantCount)
        self.privateMode = try container.decode(Bool.self, forKey: .privateMode)
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.tempImageUrls = try container.decodeIfPresent([String].self, forKey: .tempImageUrls)
        self.likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        self.collaborators = try container.decodeIfPresent([String].self, forKey: .collaborators) ?? []
        self.pendingInvitations = try container.decodeIfPresent([String].self, forKey: .pendingInvitations) ?? []
    }

    init(id: String, name: String, timestamp: Timestamp? = nil, description: String? = nil, username: String, fullname: String, uid: String, coverImageUrl: String? = nil, restaurantCount: Int,  privateMode: Bool, profileImageUrl: String? = nil, tempImageUrls: [String]? = nil, likes: Int = 0, collaborators: [String] = [], pendingInvitations: [String] = []) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.description = description
        self.username = username
        self.fullname = fullname
        self.uid = uid
        self.coverImageUrl = coverImageUrl
        self.restaurantCount = restaurantCount
        self.privateMode = privateMode
        self.profileImageUrl = profileImageUrl
        self.tempImageUrls = tempImageUrls
        self.likes = likes
        self.collaborators = collaborators
        self.pendingInvitations = pendingInvitations
    }

    mutating func updatetempImageUrls(with item: CollectionItem) {
        if tempImageUrls == nil {
            tempImageUrls = []
        }
        if tempImageUrls!.count < 4, let image = item.image {
            tempImageUrls!.append(image)
        }
    }

    mutating func removeCoverImageUrl(for item: CollectionItem) {
        guard var urls = tempImageUrls else { return }
        if let image = item.image, let index = urls.firstIndex(of: image) {
            urls.remove(at: index)
            tempImageUrls = urls.isEmpty ? nil : urls
        }
    }

    mutating func addCollaborator(userId: String) {
        if !collaborators.contains(userId) {
            collaborators.append(userId)
        }
    }

    mutating func removeCollaborator(userId: String) {
        if let index = collaborators.firstIndex(of: userId) {
            collaborators.remove(at: index)
        }
    }

    mutating func inviteUser(userId: String) {
        if !pendingInvitations.contains(userId) {
            pendingInvitations.append(userId)
        }
    }

    mutating func acceptInvitation(userId: String) {
        if let index = pendingInvitations.firstIndex(of: userId) {
            pendingInvitations.remove(at: index)
            addCollaborator(userId: userId)
        }
    }

    mutating func rejectInvitation(userId: String) {
        if let index = pendingInvitations.firstIndex(of: userId) {
            pendingInvitations.remove(at: index)
        }
    }
}

struct CollectionItem: Codable, Hashable, Identifiable {
    var collectionId: String
    var id: String
    var name: String
    var image: String?
    // atHome post type specific
    var postUserFullname: String?
    var postUserId: String?
    // restaurant post type specific
    var city: String?
    var state: String?
    var geoPoint: GeoPoint?
    var privateMode: Bool
    var notes: String?
    
    // New properties
    var addedByUid: String? // User ID of who added the item
    var addedByUsername: String? // Username of who added the item

    enum CodingKeys: String, CodingKey {
        case collectionId, id, name, image, postUserFullname, postUserId, city, state, geoPoint, privateMode, notes, addedByUid, addedByUsername
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.collectionId = try container.decode(String.self, forKey: .collectionId)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.image = try container.decodeIfPresent(String.self, forKey: .image)
        self.postUserFullname = try container.decodeIfPresent(String.self, forKey: .postUserFullname)
        self.postUserId = try container.decodeIfPresent(String.self, forKey: .postUserId)
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
        self.state = try container.decodeIfPresent(String.self, forKey: .state)
        self.geoPoint = try container.decodeIfPresent(GeoPoint.self, forKey: .geoPoint)
        self.privateMode = try container.decode(Bool.self, forKey: .privateMode)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.addedByUid = try container.decodeIfPresent(String.self, forKey: .addedByUid)
        self.addedByUsername = try container.decodeIfPresent(String.self, forKey: .addedByUsername)
    }

    init(collectionId: String, id: String, name: String, image: String? = nil, postUserFullname: String? = nil, postUserId: String? = nil, city: String? = nil, state: String? = nil, geoPoint: GeoPoint? = nil, privateMode: Bool, notes: String? = nil, addedByUid: String? = nil, addedByUsername: String? = nil) {
        self.collectionId = collectionId
        self.id = id
        self.name = name
        self.image = image
        self.postUserFullname = postUserFullname
        self.postUserId = postUserId
        self.city = city
        self.state = state
        self.geoPoint = geoPoint
        self.privateMode = privateMode
        self.notes = notes
        self.addedByUid = addedByUid
        self.addedByUsername = addedByUsername
    }
}
struct CollectionInvite: Identifiable, Codable {
    @DocumentID var id: String? // Firestore will auto-generate this ID if not set
    var collectionId: String
    var collectionName: String
    var collectionCoverImageUrl: String? // Cover image of the collection
    var inviterUid: String
    var inviterUsername: String
    var inviterProfileImageUrl: String? // Profile image of the inviter
    var status: InviteStatus
    var timestamp: Timestamp
    var tempImageUrls: [String]? // Temporary image URLs for the collection

    enum CodingKeys: String, CodingKey {
        case id
        case collectionId
        case collectionName
        case collectionCoverImageUrl
        case inviterUid
        case inviterUsername
        case inviterProfileImageUrl
        case status
        case timestamp
        case tempImageUrls
    }
    
    init(id: String? = nil, collectionId: String, collectionName: String, collectionCoverImageUrl: String? = nil, inviterUid: String, inviterUsername: String, inviterProfileImageUrl: String? = nil, status: InviteStatus, timestamp: Timestamp, tempImageUrls: [String]? = nil) {
        self.id = id
        self.collectionId = collectionId
        self.collectionName = collectionName
        self.collectionCoverImageUrl = collectionCoverImageUrl
        self.inviterUid = inviterUid
        self.inviterUsername = inviterUsername
        self.inviterProfileImageUrl = inviterProfileImageUrl
        self.status = status
        self.timestamp = timestamp
        self.tempImageUrls = tempImageUrls
    }
}

