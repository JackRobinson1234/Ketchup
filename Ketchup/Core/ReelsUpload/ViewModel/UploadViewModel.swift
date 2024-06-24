//
//  UploadViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//

import SwiftUI
import Firebase
import PhotosUI

@MainActor
class UploadViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var caption = ""
    @Published var uploadSuccess: Bool = false
    @Published var uploadFailure: Bool = false
    // MEDIA TO BE UPLOADED
    @Published var videoURL: URL?
    @Published var images: [UIImage]?
    @Published var mediaType: String = "none"
    @Published var restaurant: Restaurant?
    
    @Published var navigateToUpload = false
    @Published var fromInAppCamera = true
    @Published var restaurantRequest: RestaurantRequest?
    @ObservedObject var feedViewModel: FeedViewModel
    @Published var overallRating: Int = 3
    @Published var serviceRating: Int = 3
    @Published var atmosphereRating: Int = 3
    @Published var valueRating: Int = 3
    @Published var foodRating: Int = 3
    @Published var favoriteMenuItems: [String] = []
    
    init(feedViewModel: FeedViewModel) {
        self.feedViewModel = feedViewModel
    }
    
    func reset() {
        isLoading = false
        error = nil
        caption = ""
        uploadSuccess = false
        uploadFailure = false
        videoURL = nil
        images = []
        mediaType = "none"
        restaurant = nil
        navigateToUpload = false
        fromInAppCamera = true
        overallRating = 3
        serviceRating = 3
        atmosphereRating = 3
        valueRating = 3
        foodRating = 3
        favoriteMenuItems = []
    }
    
    func uploadPost() async {
        isLoading = true
        var postRestaurant: PostRestaurant? = nil
        
        if let restaurant = restaurant {
            postRestaurant = UploadService.shared.createPostRestaurant(from: restaurant)
        } else if let restaurant = restaurantRequest {
            postRestaurant = PostRestaurant(
                id: "construction" + NSUUID().uuidString,
                name: restaurant.name,
                geoPoint: nil,
                geoHash: nil,
                address: nil,
                city: restaurant.city.isEmpty ? nil : restaurant.city,
                state: restaurant.state.isEmpty ? nil : restaurant.state,
                profileImageUrl: nil
                
            )
            do {
                try await RestaurantService.shared.requestRestaurant(requestRestaurant: restaurant)
            } catch {
                print("error uploading restaurant request")
            }
        }
        
        error = nil
        
        var post: Post? = nil
        do {
            if mediaType == "video" {
                guard let videoURL = videoURL else {
                    throw UploadError.invalidMediaData
                }
                
                post = try await UploadService.shared.uploadPost(
                    videoURL: videoURL,
                    images: nil,
                    mediaType: mediaType,
                    caption: caption,
                    postRestaurant: postRestaurant,
                    fromInAppCamera: fromInAppCamera,
                    overallRating: overallRating,
                    serviceRating: serviceRating,
                    atmosphereRating: atmosphereRating,
                    valueRating: valueRating,
                    foodRating: foodRating,
                    favoriteItems: favoriteMenuItems
                )
            } else if mediaType == "photo" {
                guard let images = images else {
                    throw UploadError.invalidMediaData
                }
                post = try await UploadService.shared.uploadPost(
                    videoURL: nil,
                    images: images,
                    mediaType: mediaType,
                    caption: caption,
                    postRestaurant: postRestaurant,
                    fromInAppCamera: fromInAppCamera,
                    overallRating: overallRating,
                    serviceRating: serviceRating,
                    atmosphereRating: atmosphereRating,
                    valueRating: valueRating,
                    foodRating: foodRating,
                    favoriteItems: favoriteMenuItems
                )
            } else {
                throw UploadError.invalidMediaType
            }
            uploadSuccess = true
            
        } catch {
            self.error = error
            uploadFailure = true
        }
        if let post {
            feedViewModel.feedViewOption = .grid
            feedViewModel.showPostAlert = true
            feedViewModel.posts.insert(post, at: 0)
        }
        isLoading = false
    }
}
