//
//  UploadPostViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Firebase
import PhotosUI

@MainActor
class UploadPostViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var mediaPreview: Movie?
    @Published var caption = ""
    @Published var selectedMediaForUpload: Movie?
    @Published var selectedItem: PhotosPickerItem? {
        didSet { Task { await loadVideo(fromItem: selectedItem) } }
    }
    @Published var uploadSuccess: Bool = false
    @Published var uploadFailure: Bool = false
    

    @Published var recipeTitle = ""
    @Published var ingredients: [ingredient] = [ingredient(quantity: "", item: "")]
    @Published var recipeCuisine = ""
    @Published var dietaryRestrictions: [String] = [""]
    @Published var recipeHours: Int = 0
    @Published var recipeMinutes: Int = 0
    
    @Published var instructions: [instruction] = [instruction(title: "", description: "")]
    
    private let restaurant: Restaurant?
    private let service: UploadPostService
    
    var isLastIngredientEmpty: Bool {
        return ingredients.last?.item.isEmpty == true
        }
    
    var isLastRestrictionEmpty: Bool {
            return dietaryRestrictions.last?.isEmpty == true
        }
    
    var isLastInstructionEmpty: Bool {
        return instructions.last?.title.isEmpty == true
        }
    
    init(service: UploadPostService, restaurant: Restaurant?) {
        self.service = service
        self.restaurant = restaurant
    }
    //MARK: Upload restaurants
    func uploadRestaurantPost() async throws {
        guard !caption.isEmpty else { return }
        guard let videoUrlString = mediaPreview?.url.absoluteString else { return }
        isLoading = true
        if let restaurant {
            do {
                print("running upload post")
                try await service.uploadRestaurantPost(caption: caption, videoUrlString: videoUrlString, restaurant: restaurant)
                isLoading = false
                uploadSuccess = true
            } catch {
                self.error = error
                isLoading = false
                uploadFailure = true
            }
        }
    }
    
    func uploadRecipePost() async throws {
        guard !caption.isEmpty else { return }
        guard !recipeTitle.isEmpty else { return }
        guard let videoUrlString = mediaPreview?.url.absoluteString else { return }
        isLoading = true
        
        let filteredIngredients = ingredients.filter { !$0.item.isEmpty }
        let filteredDietaryRestrictions = dietaryRestrictions.filter { !$0.isEmpty }
        let filteredInstructions = instructions.filter { !$0.title.isEmpty || !$0.description.isEmpty }
        let time = recipeHours * 60 + recipeMinutes
        let nonEmptyIngredients = filteredIngredients.isEmpty ? nil : filteredIngredients
        let nonEmptyDietaryRestrictions = filteredDietaryRestrictions.isEmpty ? nil : filteredDietaryRestrictions
        let nonEmptyInstructions = filteredInstructions.isEmpty ? nil : filteredInstructions
        let nonEmptyCuisine = recipeCuisine.isEmpty ? nil : recipeCuisine
        var recipe = postRecipe(
            name: recipeTitle,
            cuisine: nonEmptyCuisine,
            dietary: nonEmptyDietaryRestrictions,
            instructions: nonEmptyInstructions,
            ingredients: nonEmptyIngredients
        )

        if time > 0 {
            recipe.time = time
        }
            do {
                print("running upload recipe post")
                print(recipe)
                try await service.uploadRecipePost(caption: caption, videoUrlString: videoUrlString, recipe: recipe)
                isLoading = false
                uploadSuccess = true
            } catch {
                self.error = error
                isLoading = false
                uploadFailure = true
            }
        }
    
    
    func setMediaItemForUpload() {
        selectedMediaForUpload = mediaPreview
    }
    
    
    func reset() {
        caption = ""
        mediaPreview = nil
        error = nil
        selectedItem = nil
        selectedMediaForUpload = nil
        recipeTitle = ""
        ingredients = [ingredient(quantity: "", item: "")]
        instructions = [instruction(title: "", description: "")]
        
        recipeCuisine = ""
        dietaryRestrictions = [""]

        
        
    }
    func addEmptyIngredient() {
            ingredients.append(ingredient(quantity: "", item: ""))
        }
    
    func addEmptyRestriction() {
            dietaryRestrictions.append("")
        }
    
    func addEmptyInstruction() {
        instructions.append(instruction(title: "", description: ""))
        }
    
    func loadVideo(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        isLoading = true
        
        do {
            guard let movie = try await item.loadTransferable(type: Movie.self) else { return }
            self.mediaPreview = movie
            isLoading = false
        } catch {
            print("DEBUG: Failed with error \(error.localizedDescription)")
        }
    }
}
