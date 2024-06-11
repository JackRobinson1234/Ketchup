//
//  RecipeService.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/10/24.
//

import Foundation
class RecipeService {
    static let shared = RecipeService() // Singleton instance
    private init() {}
    
    //MARK: fetchRestaurant
    /// Fetches a single restaurant given an ID
    /// - Parameter id: String of an ID for a restaurant
    /// - Returns: RestaurantObject
    func fetchRecipe (withId id: String) async throws -> Recipe {
        print("DEBUG: Ran fetchRestaurant()")
        return try await FirestoreConstants.RecipesCollection.document(id).getDocument(as: Recipe.self)
    }
}
