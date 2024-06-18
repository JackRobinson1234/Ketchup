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
        fullname: "Lewis Hamilton",
        profileImageUrl: "lewis-hamilton"
        , privateMode: false
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
            imageURLs: nil,
            profileImageUrl: "https://picsum.photos/400/500",
            stats: RestaurantStats(postCount: 0, collectionCount: 0)
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
            imageURLs: ["listing-2","listing-1", "listing-3","listing-4"],
            stats: RestaurantStats(postCount: 0, collectionCount: 0)
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
            imageURLs: ["listing-3","listing-2", "listing-1","listing-4"],
            stats: RestaurantStats(postCount: 0, collectionCount: 0)
        )
        ]
    
    static let videoUrls =  [
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4"
    ]
    
    static var users: [User] = [
        .init(id: NSUUID().uuidString, username: "lewis.hamilton",  fullname: "Lewis Hamilton", privateMode: false),
        .init(id: NSUUID().uuidString, username: "max.verstappen",  fullname: "Max Verstappen", privateMode: false),
        .init(id: NSUUID().uuidString, username: "fernando.alonso", fullname: "Fernado Alonso", privateMode: false),
        .init(id: NSUUID().uuidString, username: "charles.leclerc", fullname: "Charles Leclerc", privateMode: false),
    ]
    
    static var posts: [Post] = [
        .init(
                id: "1",
                postType: .dining,
                mediaType: "video",
                mediaUrls: ["https://example.com/video.mp4"],
                caption: "Check out this delicious dish!",
                likes: 141,
                commentCount: 20,
                repostCount: 10,
                thumbnailUrl: "https://picsum.photos/400/500",
                timestamp: Timestamp(date: Date()),
                user: PostUser(
                    id: "user1",
                    fullname: "John Doe",
                    profileImageUrl: "https://example.com/profile.jpg"
                    ,privateMode: false,
                    username: "Test"
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
                price: "$$$",
                fromInAppCamera: false,
                recommendation: false
            
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
        )]
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
    static var collections: [Collection] = [
            .init(
                id: NSUUID().uuidString,
                name: "Italian Cuisine",
                timestamp: Timestamp(),
                description: "A collection of delicious Italian dishes",
                username: "wilbond",
                fullname: "Jack Rob",
                uid: "",
                restaurantCount: 0,
                atHomeCount: 0,
                privateMode: false
                )
        ]
    static var items: [CollectionItem] = [
            .init(
                collectionId: "af",
                id: "QOxHzulwskv9pSS3vsSH",
                postType: .cooking,
                name: "Pasta Carbonara",
                image: "https://picsum.photos/200/300",
                postUserFullname: "Will Bond"
                ,privateMode: false,
                notes: "asfdasflhljhljbljhbkjbjlhblbljhblhjbbjhbhjlbhjlbkhjbhjghvhvkhgvkjhgvkghvjkbljbjlhbjhbd"
            ),
            .init(
                collectionId: "af",
                id: "-1QvxFtMgOLpSbO-oAtUgA",
                postType: .dining,
                name: "Bella Italia",
                image: "https://picsum.photos/250/350",
                city: "Hermosa Beach",
                state: "CA",
                geoPoint: GeoPoint(latitude: 37.86697712078698, longitude: -122.25134254232876)
                ,privateMode: false,
                notes: ""
            )
        ]
    static let activity1 = Activity(id: "1", username: "user1", postId: "123", timestamp: Timestamp(date: Date()), type: .newPost, uid: "uid1", image: "https://picsum.photos/200/300", restaurantId: nil, collectionId: nil, name: "yum", postType: .cooking)

        static let activity2 = Activity(id: "2", username: "user2", postId: nil, timestamp: Timestamp(date: Date()), type: .newCollection, uid: "uid2", image: nil, restaurantId: nil, collectionId: "456", name: "My Collection")

        static let activity3 = Activity(id: "3", username: "user3", postId: nil, timestamp: Timestamp(date: Date()), type: .newCollectionItem, uid: "uid3",  image: "https://picsum.photos/200/300", restaurantId: nil, collectionId: "789", name: "Item Name")
    static let reviewUser = ReviewUser(
           id: "user1",
           fullname: "John Doe",
           profileImageUrl: "https://picsum.photos/200/300",
           privateMode: false,
           username: "john.doe"
       )
       
       static let restaurant = ReviewRestaurant(
           id: "restaurant1",
           name: "Example Restaurant",
           geoPoint: nil,
           geoHash: "",
           address: "123 Main St",
           city: "Cityville",
           state: "Stateville",
           profileImageUrl: "https://picsum.photos/400/500"
       )
       
       static var reviews: [Review] = [
           .init(
               id: "1",
               description: "This place has the best pizza in town!",
               likes: 100,
               timestamp: Timestamp(date: Date()),
               user: reviewUser,
               restaurant: restaurant,
               didLike: true,
               recommendation: true,
               favoriteItems: ["Pizza", "Pasta"]
           ),
           .init(
               id: "2",
               description: "Their burgers are amazing!",
               likes: 50,
               timestamp: Timestamp(date: Date()),
               user: reviewUser,
               restaurant: restaurant,
               didLike: false,
               recommendation: false,
               favoriteItems: ["Burgers", "Fries"]
           )
       ]
    static var samplePostRecipe: PostRecipe = PostRecipe(
        
            cookingTime: 30,
            dietary: ["Gluten-Free", "Vegetarian"],
            instructions: [
                .init(title: "Boil Water", description: "Bring a large pot of salted water to a boil. Add spaghetti and cook until al dente."),
                .init(title: "Whisk Eggs", description: "In a large bowl, whisk together eggs and Parmesan until combined."),
                .init(title: "Cook Pancetta", description: "In a large skillet over medium heat, cook pancetta until crispy. Remove from heat and set aside."),
                .init(title: "Drain Pasta", description: "Drain pasta and reserve 1 cup of pasta water."),
                .init(title: "Combine Pasta", description: "Quickly add pasta to egg mixture and toss to combine, adding reserved pasta water a little at a time until creamy."),
                .init(title: "Add Pancetta", description: "Add pancetta and mix well. Season with salt and pepper to taste. Serve immediately with extra Parmesan.")
            ],
            ingredients: [
                .init(quantity: "12 oz", item: "spaghetti"),
                .init(quantity: "3", item: "large eggs"),
                .init(quantity: "1 cup", item: "grated Parmesan cheese"),
                .init(quantity: "4 oz", item: "pancetta, diced"),
                .init(quantity: "to taste", item: "Salt and freshly ground black pepper")
            ],
            difficulty: .easy,
            servings: 4
            
        )
}
