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
    @Published var recipeTitle = ""
    @Published var ingredients: [Ingredient] = []
    @Published var recipeCuisine: String = ""
    @Published var dietaryRestrictions: [String] = []
    @Published var cookingTime: Int = 0
    @Published var recipeServings: Int = 0
    @Published var recipeDifficulty: RecipeDifficulty = .easy
    @Published var instructions: [Instruction] = []
    @Published var restaurant: Restaurant?
    @Published var postType: PostType? = .dining
    @Published var navigateToUpload = false
    @Published var fromInAppCamera = true
    @Published var restaurantRequest: RestaurantRequest?
    private var uploadService = UploadService()
    @Published var recommend: Bool?
    @ObservedObject var feedViewModel: FeedViewModel
    @Published var serviceRating: Bool?
    @Published var atmosphereRating: Bool?
    @Published var valueRating: Bool?
    @Published var foodRating: Bool?
    
    
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
        recipeTitle = ""
        ingredients = []
        recipeCuisine = ""
        dietaryRestrictions = []
        cookingTime = 0
        recipeServings = 0
        instructions = []
        restaurant = nil
        postType = .dining
        navigateToUpload = false
        fromInAppCamera = true
        recommend = nil
    }
    
    func addEmptyIngredient() {
        ingredients.append(Ingredient(quantity: "", item: ""))
    }
    
    func addEmptyRestriction() {
        dietaryRestrictions.append("")
    }
    
    func addEmptyInstruction() {
        instructions.append(Instruction(title: "", description: ""))
    }
    
    func hasRecipeDetailsChanged() -> Bool {
        return !(ingredients.isEmpty &&
                 dietaryRestrictions.isEmpty &&
                 cookingTime == 0 &&
                 recipeServings == 0 &&
                 instructions.isEmpty)
    }
    func createPostRestaurant(from restaurant: Restaurant) -> PostRestaurant {
        return PostRestaurant(
            id: restaurant.id,
            name: restaurant.name,
            geoPoint: restaurant.geoPoint,
            geoHash: restaurant.geoHash,
            address: restaurant.address,
            city: restaurant.city,
            state: restaurant.state,
            profileImageUrl: restaurant.profileImageUrl,
            cuisine: restaurant.cuisine,
            price: restaurant.price
        )
    }
    func uploadPost() async {
        isLoading = true
        var postRestaurant: PostRestaurant? = nil
        var recipe: PostRecipe? = nil
        
        if hasRecipeDetailsChanged() {
            recipe = PostRecipe(
                cookingTime: cookingTime,
                dietary: dietaryRestrictions,
                instructions: instructions,
                ingredients: ingredients,
                servings: recipeServings
            )
        }
        
        if let restaurant = restaurant {
            postRestaurant = createPostRestaurant(from: restaurant)
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
        var cookingTitle: String? = recipeTitle
        if recipeTitle.isEmpty {
            cookingTitle = nil
        }
        var post: Post? = nil
        do {
            if let postType = postType {
                if mediaType == "video" {
                    guard let videoURL = videoURL else {
                        throw UploadError.invalidMediaData
                    }
                    
                    post = try await uploadService.uploadPost(
                        videoURL: videoURL,
                        images: nil,
                        mediaType: mediaType,
                        caption: caption,
                        postType: postType,
                        postRestaurant: postRestaurant,
                        recipe: recipe,
                        fromInAppCamera: fromInAppCamera,
                        cookingTitle: cookingTitle,
                        recommendation: recommend,
                        serviceRating: serviceRating,
                        atmosphereRating: atmosphereRating,
                        valueRating: valueRating,
                        foodRating: foodRating
                    )
                } else if mediaType == "photo" {
                    guard let images = images else {
                        throw UploadError.invalidMediaData
                    }
                    post = try await uploadService.uploadPost(
                        videoURL: nil,
                        images: images,
                        mediaType: mediaType,
                        caption: caption,
                        postType: postType,
                        postRestaurant: postRestaurant,
                        recipe: recipe,
                        fromInAppCamera: fromInAppCamera,
                        cookingTitle: cookingTitle,
                        recommendation: recommend,
                        serviceRating: serviceRating,
                        atmosphereRating: atmosphereRating,
                        valueRating: valueRating,
                        foodRating: foodRating
                    )
                } else {
                    throw UploadError.invalidMediaType
                }
                uploadSuccess = true
            }
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
