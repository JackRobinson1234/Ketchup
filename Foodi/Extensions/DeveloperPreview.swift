//
//  DeveloperPreview.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//


import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI

struct DeveloperPreview {
    static var user = User(
        id: NSUUID().uuidString,
        username: "lewis.hamilton",
        email: "lewis@gmail.com",
        fullname: "Lewis Hamilton",
        bio: "Formula 1 Driver | Mercedes AMG",
        profileImageUrl: "lewis-hamilton"
    )
    
    static var restaurants: [Restaurant] = [
        .init(
            id: NSUUID().uuidString,
            cuisine: "Italian",
            price: "$$",
            name: "Amir B's Pizzeria",
            geoPoint: GeoPoint(latitude: 37.86697712078698, longitude: -122.25134254232876),
            address: "2425 Piedmont Ave",
            city: "Berkeley",
            state: "CA",
            imageURLs: ["listing-1","listing-2", "listing-3","listing-4"]
        ),
        .init(
            id: NSUUID().uuidString,
            cuisine: "American",
            price: "$$$$",
            name: "Will Bond's Steakhouse",
            geoPoint: GeoPoint(latitude: 37.869308983815685, longitude: -122.25350152899239),
            address: "2722 Bancroft Ave",
            city: "Berkeley",
            state: "CA",
            imageURLs: ["listing-2","listing-1", "listing-3","listing-4"]
        ),
        .init(
            id: NSUUID().uuidString,
            cuisine: "Chinese",
            price: "$",
            name: "Greenbaum's Money Pit",
            geoPoint: GeoPoint(latitude: 37.868883834260735, longitude: -122.25118022568488),
            address: "2311 Piedmont Ave",
            city: "Berkeley",
            state: "CA",
            imageURLs: ["listing-3","listing-2", "listing-1","listing-4"]
        )
        ]
    
    static let videoUrls =  [
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4"
    ]
    
    static var users: [User] = [
        .init(id: NSUUID().uuidString, username: "lewis.hamilton", email: "lewis@gmail.com", fullname: "Lewis Hamilton", bio: " jasdf "),
        .init(id: NSUUID().uuidString, username: "max.verstappen", email: "max@gmail.com", fullname: "Max Verstappen"),
        .init(id: NSUUID().uuidString, username: "fernando.alonso", email: "fernando@gmail.com", fullname: "Fernado Alonso"),
        .init(id: NSUUID().uuidString, username: "charles.leclerc", email: "charles@gmail.com", fullname: "Charles Leclerc"),
    ]
    
    static var posts: [Post] = [
        .init(
                id: "1",
                postType: "restaurant",
                mediaType: "video",
                mediaUrls: ["https://example.com/video.mp4"],
                caption: "Check out this delicious dish!",
                likes: 100,
                commentCount: 20,
                shareCount: 10,
                thumbnailUrl: "https://example.com/thumbnail.jpg",
                timestamp: Timestamp(date: Date()),
                user: PostUser(
                    id: "user1",
                    fullName: "John Doe",
                    profileImageUrl: "https://example.com/profile.jpg"
                ),
                restaurant: PostRestaurant(
                    id: "restaurant1",
                    name: "Example Restaurant",
                    geoPoint: nil,
                    geoHash: "",
                    address: "123 Main St",
                    city: "Cityville",
                    state: "Stateville",
                    profileImageUrl: "https://example.com/restaurant.jpg"
                ),
                cuisine: "Italian",
                price: "$$$"
            
        )
    ]
    
    static var comment = Comment(
        id: NSUUID().uuidString,
        postOwnerUid: "test",
        commentText: "This is a test comment for preview purposes. Making it extra long to test to see what it will look like if there is a longer caption or anything like that. hajskdfjnaklsdfn",
        postId: "",
        timestamp: Timestamp(),
        commentOwnerUid: "",
        user: user
    )
    
    static var comments: [Comment] = [
        .init(
            id: NSUUID().uuidString,
            postOwnerUid: "test",
            commentText: "This is a test comment for preview purposes",
            postId: "",
            timestamp: Timestamp(),
            commentOwnerUid: "",
            user: user
        ),
        .init(
            id: NSUUID().uuidString,
            postOwnerUid: "test",
            commentText: "This is another test comment so we have some mock data to work with",
            postId: "",
            timestamp: Timestamp(),
            commentOwnerUid: "",
            user: users[1]
        ),
        .init(
            id: NSUUID().uuidString,
            postOwnerUid: "test",
            commentText: "Final test comment to use in preview ",
            postId: "",
            timestamp: Timestamp(),
            commentOwnerUid: "",
            user: users[2]
        ),
    ]
    /*
    static var notifications: [Notification] = [
        .init(id: NSUUID().uuidString, postId: "", timestamp: Timestamp(), type: .comment, uid: "lewis-hamilton",  user: user),
        .init(id: NSUUID().uuidString, postId: "", timestamp: Timestamp(), type: .like, uid: "max-verstappen",  user: users[3]),
        .init(id: NSUUID().uuidString, postId: "", timestamp: Timestamp(), type: .comment, uid: "lewis-hamilton",  user: user),
        .init(id: NSUUID().uuidString, postId: "", timestamp: Timestamp(), type: .comment, uid: "fernando-alonso", user: users[2]),
        .init(id: NSUUID().uuidString, timestamp: Timestamp(), type: .follow, uid: "lewis-hamilton", user: users[1]),
        .init(id: NSUUID().uuidString, postId: "", timestamp: Timestamp(), type: .comment, uid: "lewis-hamilton", user: user),
    ]
      */
}
