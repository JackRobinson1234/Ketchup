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
//        caption = ""
//        mediaPreview = nil
//        error = nil
//        selectedItem = nil
//        selectedMediaForUpload = nil
//        recipeTitle = ""
//        ingredients = [Ingredient(quantity: "", item: "")]
//        instructions = [Instruction(title: "", description: "")]
//        recipeCuisine = ""
//        dietaryRestrictions = [""]
        print("DEBUG: ayo")
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
        
        isLoading = true
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
                                                   postRecipe: postRecipe)
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
                                                   postRecipe: postRecipe)
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

    
    
    func loadMediafromPhotosPicker(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        isLoading = true

        do {
            if let movie = try await item.loadTransferable(type: Movie.self) {
                //set media here
                print("loaded video")
            } else if let photo = try await item.loadTransferable(type: Photo.self) {
                //set media here
                print("loaded image")
            } else {
                print("DEBUG: Unsupported media type")
            }
        } catch {
            print("DEBUG: Failed with error \(error.localizedDescription)")
        }
    }
}
