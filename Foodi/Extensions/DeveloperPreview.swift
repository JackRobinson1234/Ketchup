//
//  DeveloperPreview.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//


import Foundation
import Firebase

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
            latitude: 37.86697712078698,
            longitude:  -122.25134254232876,
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
            latitude: 37.869308983815685,
            longitude:  -122.25350152899239,
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
            latitude: 37.868883834260735,
            longitude:  -122.25118022568488,
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
        .init(id: NSUUID().uuidString, username: "lewis.hamilton", email: "lewis@gmail.com", fullname: "Lewis Hamilton"),
        .init(id: NSUUID().uuidString, username: "max.verstappen", email: "max@gmail.com", fullname: "Max Verstappen"),
        .init(id: NSUUID().uuidString, username: "fernando.alonso", email: "fernando@gmail.com", fullname: "Fernado Alonso"),
        .init(id: NSUUID().uuidString, username: "charles.leclerc", email: "charles@gmail.com", fullname: "Charles Leclerc"),
    ]
    
    static var posts: [Post] = [
        .init(
            id: NSUUID().uuidString,
            videoUrl: videoUrls[0],
            ownerUid: "lewis.hamilton",
            caption: "This is some test caption for this post",
            likes: 200,
            commentCount: 57,
            saveCount: 23,
            shareCount: 9,
            views: 567,
            thumbnailUrl: "lewis-hamilton",
            timestamp: Timestamp(),
            user: users[0],
            restaurant: restaurants[0],
            restaurantId: restaurants[0].id
            
        ),
        .init(
            id: NSUUID().uuidString,
            videoUrl: videoUrls[1],
            ownerUid: "lewis.hamilton",
            caption: "This is some test caption for this post",
            likes: 500,
            commentCount: 62,
            saveCount: 23,
            shareCount: 98,
            views: 841,
            thumbnailUrl: "max-verstappen",
            timestamp: Timestamp(),
            user: users[1],
            restaurant: restaurants[1],
            restaurantId: restaurants[0].id
        ),
        .init(
            id: NSUUID().uuidString,
            videoUrl: videoUrls[2],
            ownerUid: "lewis.hamilton",
            caption: "This is some test caption for this post",
            likes: 197,
            commentCount: 23,
            saveCount: 51,
            shareCount: 98,
            views: 937,
            thumbnailUrl: "fernando-alonso",
            timestamp: Timestamp(),
            user: users[2],
            restaurant: restaurants[2],
            restaurantId: restaurants[0].id
        ),
    ]
    
    static var comment = Comment(
        id: NSUUID().uuidString,
        postOwnerUid: "test",
        commentText: "This is a test comment for preview purposes",
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
    
    static var notifications: [Notification] = [
        .init(id: NSUUID().uuidString, postId: "", timestamp: Timestamp(), type: .comment, uid: "lewis-hamilton", post: posts[0], user: user),
        .init(id: NSUUID().uuidString, postId: "", timestamp: Timestamp(), type: .like, uid: "max-verstappen", post: posts[2], user: users[3]),
        .init(id: NSUUID().uuidString, postId: "", timestamp: Timestamp(), type: .comment, uid: "lewis-hamilton", post: posts[1], user: user),
        .init(id: NSUUID().uuidString, postId: "", timestamp: Timestamp(), type: .comment, uid: "fernando-alonso", post: posts[0], user: users[2]),
        .init(id: NSUUID().uuidString, timestamp: Timestamp(), type: .follow, uid: "lewis-hamilton", user: users[1]),
        .init(id: NSUUID().uuidString, postId: "", timestamp: Timestamp(), type: .comment, uid: "lewis-hamilton", post: posts[1], user: user),
    ]
            
}
