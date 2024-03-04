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
    
    @Published var recipeDescription = ""
    @Published var recipeTitle = ""
    @Published var ingredients: [String] = [""]
    @Published var recipeCuisine = ""
    @Published var dietaryRestrictions: [String] = [""]
    
    @Published var instructions: [instructions] = [Foodi.instructions(title: "", description: "")]
    
    private let restaurant: Restaurant?
    private let service: UploadPostService
    
    var isLastIngredientEmpty: Bool {
            return ingredients.last?.isEmpty == true
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
        ingredients = [""]
        instructions = [Foodi.instructions(title: "", description: "")]
        recipeDescription = ""
        recipeCuisine = ""
        dietaryRestrictions = [""]

        
        
    }
    func addEmptyIngredient() {
            ingredients.append("")
        }
    
    func addEmptyInstruction() {
        instructions.append(Foodi.instructions(title: "", description: ""))
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
