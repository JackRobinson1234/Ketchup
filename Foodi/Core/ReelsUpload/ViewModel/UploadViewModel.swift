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
    @Published var ingredients: [Ingredient] = [Ingredient(quantity: "", item: "")]
    @Published var recipeCuisine = ""
    @Published var dietaryRestrictions: [String] = [""]
    @Published var recipeHours: Int = 0
    @Published var recipeMinutes: Int = 0
    
    @Published var recipeServings: Int = 0
    
    @Published var instructions: [Instruction] = [Instruction(title: "", description: "")]
    
    @Published var restaurant: Restaurant?
    
    @Published var postType = "Select Post Type"
    
    @Published var savedRecipe = false
    
    @Published var navigateToUpload = false
    
    @Published var fromInAppCamera = true
    
    
    private var uploadService = UploadService()
    
    
    var isLastIngredientEmpty: Bool {
        return ingredients.last?.item.isEmpty == true
    }
    
    var isLastRestrictionEmpty: Bool {
        return dietaryRestrictions.last?.isEmpty == true
    }
    
    var isLastInstructionEmpty: Bool {
        return instructions.last?.description.isEmpty == true
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
        ingredients = [Ingredient(quantity: "", item: "")]
        recipeCuisine = ""
        dietaryRestrictions = [""]
        recipeHours = 0
        recipeMinutes = 0
        recipeServings = 0
        instructions = [Instruction(title: "", description: "")]
        restaurant = nil
        postType = "Select Post Type"
        savedRecipe = false
        navigateToUpload = false
        fromInAppCamera = true
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
    
    func uploadPost() async {
        isLoading = true
        var postRestaurant: PostRestaurant? = nil
        var postRecipe: PostRecipe? = nil
        
        if savedRecipe {
            postRecipe = PostRecipe(name: recipeTitle,
                                    //TODO: Convert this to minutes
                                    cookingTime: (recipeMinutes + recipeHours * 60),
                                    dietary: dietaryRestrictions,
                                    instructions: instructions,
                                    ingredients: ingredients)
        }
        
        if let restaurant = restaurant {
            postRestaurant = PostRestaurant(
                id: restaurant.id,
                name: restaurant.name,
                geoPoint: restaurant.geoPoint,
                geoHash: restaurant.geoHash,
                address: restaurant.address,
                city: restaurant.city,
                state: restaurant.state,
                profileImageUrl: restaurant.profileImageUrl
            )
        }
        error = nil
        do {
            if mediaType == "video" {
                guard let videoURL = videoURL else {
                    throw UploadError.invalidMediaData
                }
                try await uploadService.uploadPost(videoURL: videoURL,
                                                   images: nil,
                                                   mediaType: mediaType,
                                                   caption: caption,
                                                   postType: postType,
                                                   postRestaurant: postRestaurant,
                                                   postRecipe: postRecipe,
                                                   fromInAppCamera: fromInAppCamera
                )
            } else if mediaType == "photo" {
                guard let images = images else {
                    throw UploadError.invalidMediaData
                }
                try await uploadService.uploadPost(videoURL: nil,
                                                   images: images,
                                                   mediaType: mediaType,
                                                   caption: caption,
                                                   postType: postType,
                                                   postRestaurant: postRestaurant,
                                                   postRecipe: postRecipe,
                                                   fromInAppCamera: fromInAppCamera
                )
            } else {
                throw UploadError.invalidMediaType
            }
            uploadSuccess = true
        } catch {
            self.error = error
            uploadFailure = true
        }
        isLoading = false
    }
}
