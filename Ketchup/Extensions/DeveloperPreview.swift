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
           
                id: "123",
                
                price: "$$$",
                name: "Amir B's Pizzeria",
                geoPoint: GeoPoint(latitude: 37.86697712078698, longitude: -122.25134254232876),
                geoHash: "9q8yy8jx4bxy",
                address: "2425 Piedmont Ave",
                city: "Berkeley",
                state: "CA",
                imageURLs: ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
                profileImageUrl: "https://example.com/profileImage.jpg",
                bio: "Authentic Italian pizzeria serving wood-fired pizzas and traditional Italian dishes.",
                _geoloc: geoLoc(lat: 37.86697712078698, lng: -122.25134254232876),
                stats: RestaurantStats(postCount: 150, collectionCount: 10),
                additionalInfo: AdditionalInfo(
                    accessibility: [AccessibilityItem(name: "Wheelchair Accessible", value: true)],
                    amenities: [AmenityItem(name: "Free WiFi", value: true)],
                    atmosphere: [AtmosphereItem(name: "Cozy", value: true)],
                    children: [ChildrenItem(name: "High Chairs", value: true)],
                    crowd: [CrowdItem(name: "Family", value: true)],
                    diningOptions: [DiningOptionItem(name: "Takeout", value: true)],
                    highlights: [HighlightItem(name: "Live Music", value: true)],
                    offerings: [OfferingItem(name: "Vegetarian Options", value: true)],
                    payments: [PaymentItem(name: "Credit Cards", value: true)],
                    planning: [PlanningItem(name: "Reservations", value: true)],
                    popularFor: [PopularForItem(name: "Lunch", value: true)],
                    serviceOptions: [ServiceOptionItem(name: "Outdoor Seating", value: true)]
                ),
                categories: ["Italian", "Pizza"],
                cid: 12345,
                containsMenuImage: true,
                countryCode: "US",
                googleFoodUrl: "https://google.com/restaurant123",
                locatedIn: "Food Court",
                menuUrl: "https://example.com/menu",
                neighborhood: "Downtown",
                openingHours: [
                    OpeningHour(day: "Monday", hours: "11:00 AM - 10:00 PM"),
                    OpeningHour(day: "Tuesday", hours: "11:00 AM - 10:00 PM"),
                    OpeningHour(day: "Wednesday", hours: "11:00 AM - 10:00 PM"),
                    OpeningHour(day: "Thursday", hours: "11:00 AM - 10:00 PM"),
                    OpeningHour(day: "Friday", hours: "11:00 AM - 11:00 PM"),
                    OpeningHour(day: "Saturday", hours: "11:00 AM - 11:00 PM"),
                    OpeningHour(day: "Sunday", hours: "12:00 PM - 9:00 PM")
                ],
                orderBy: [
                    OrderBy(name: "GrubHub", orderUrl: "https://grubhub.com/order123", url: "https://grubhub.com")
                ],
                parentPlaceUrl: "https://example.com/parentPlace",
                peopleAlsoSearch: [
                    PeopleAlsoSearch(category: "Restaurant", reviewsCount: 100, title: "Nearby Italian Restaurant", totalScore: 4.5)
                ],
                permanentlyClosed: false,
                phone: "+1-123-456-7890",
                plusCode: "849VCWC8+R9",
               
                reviewsTags: [
                    ReviewTag(count: 50, title: "Great Pizza"),
                    ReviewTag(count: 30, title: "Friendly Staff")
                ],
                scrapedAt: "2024-07-05T12:00:00Z",
                street: "Piedmont Ave",
                subCategories: ["Pizzeria", "Family Style"],
                temporarilyClosed: false,
                url: "https://example.com",
                website: "https://example.com/restaurant123"
            
        ),
        .init(
            id: NSUUID().uuidString,
            
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
                mediaType: .photo,
                mediaUrls: ["https://picsum.photos/400/500", "https://picsum.photos/300/200", "https://picsum.photos/500/700"],
                caption: "Check out this delicious dish!",
                likes: 141,
                commentCount: 20,
                repostCount: 10,
                thumbnailUrl: "https://picsum.photos/400/500",
                timestamp: Timestamp(),
                user: PostUser(
                    id: "user1",
                    fullname: "John Doe",
                    profileImageUrl: "https://picsum.photos/400/500",
                    privateMode: false,
                    username: "johndoe123"
                ),
                restaurant: PostRestaurant(
                    id: "restaurant1",
                    name: "Martha's",
                    geoPoint: nil,
                    geoHash: "",
                    address: "123 Main St",
                    city: "Cityville",
                    state: "Stateville",
                    profileImageUrl: "https://picsum.photos/400/500",
                    cuisine: "Italian",
                    price: "$$"
                ),
                didLike: false,
                didSave: false,
                fromInAppCamera: false,
                repost: false,
                didRepost: false,
                overallRating: 1,
                serviceRating: 2,
                atmosphereRating: 3,
                valueRating: 4,
                foodRating: 5
               
            )
        ]
    
    static var comment = Comment(
        id: NSUUID().uuidString,
        postOwnerUid: "test",
        commentText: "This is a test comment for preview purposes. Making it extra long to test to see what it will look like if there is a longer caption or anything like that. hajskdfjnaklsdfn",
        postId: "",
        timestamp: Timestamp(),
        commentOwnerUid: "",
        user: user,
        mentionedUsers: []
    )
    
    static var comments: [Comment] = [
        .init(
            id: NSUUID().uuidString,
            postOwnerUid: "test",
            commentText: "This is a test comment for preview purposes",
            postId: "",
            timestamp: Timestamp(),
            commentOwnerUid: "",
            user: user,
            mentionedUsers: []
        ),
        .init(
            id: NSUUID().uuidString,
            postOwnerUid: "test",
            commentText: "This is another test comment so we have some mock data to work with",
            postId: "",
            timestamp: Timestamp(),
            commentOwnerUid: "",
            user: users[1],
            mentionedUsers: []
        ),
        .init(
            id: NSUUID().uuidString,
            postOwnerUid: "test",
            commentText: "Final test comment to use in preview ",
            postId: "",
            timestamp: Timestamp(),
            commentOwnerUid: "",
            user: users[2],
            mentionedUsers: []
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
               
                privateMode: false
                )
        ]
    static var items: [CollectionItem] = [
            .init(
                collectionId: "af",
                id: "QOxHzulwskv9pSS3vsSH",
                name: "Pasta Carbonara",
                image: "https://picsum.photos/200/300",
                postUserFullname: "Will Bond"
                ,privateMode: false,
                notes: "asfdasflhljhljbljhbkjbjlhblbljhblhjbbjhbhjlbhjlbkhjbhjghvhvkhgvkjhgvkghvjkbljbjlhbjhbd"
            ),
            .init(
                collectionId: "af",
                id: "-1QvxFtMgOLpSbO-oAtUgA",
                name: "Bella Italia",
                image: "https://picsum.photos/250/350",
                city: "Hermosa Beach",
                state: "CA",
                geoPoint: GeoPoint(latitude: 37.86697712078698, longitude: -122.25134254232876)
                ,privateMode: false,
                notes: ""
            )
        ]
    static let activity1 = Activity(id: "1", username: "user1", postId: "123", timestamp: Timestamp(date: Date()), type: .newPost, uid: "uid1", image: "https://picsum.photos/200/300", restaurantId: nil, collectionId: nil, name: "yum")

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
}
