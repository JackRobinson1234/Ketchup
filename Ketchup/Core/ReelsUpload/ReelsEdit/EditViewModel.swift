//
//  EditViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/10/24.
//

import Foundation
import FirebaseFirestoreInternal

class ReelsEditViewModel: ObservableObject {
    @Published private(set) var isLoading: Bool = false
    @Published var isFoodNA: Bool
    @Published var isAtmosphereNA: Bool
    @Published var isValueNA: Bool
    @Published var isServiceNA: Bool
    private var originalPost: Post
    private var db: Firestore
    
    init(post: Post) {
        self.originalPost = post
        self.db = Firestore.firestore()
        self.isFoodNA = post.foodRating == nil
        self.isAtmosphereNA = post.atmosphereRating == nil
        self.isValueNA = post.valueRating == nil
        self.isServiceNA = post.serviceRating == nil
    }
    
    func updatePost(newCaption: String, foodRating: Double, atmosphereRating: Double, valueRating: Double, serviceRating: Double) async -> Post? {
        await setLoading(true)
        
        var postData: [String: Any] = [
            "caption": newCaption
        ]
        
        if !isFoodNA { postData["foodRating"] = foodRating }
        if !isAtmosphereNA { postData["atmosphereRating"] = atmosphereRating }
        if !isValueNA { postData["valueRating"] = valueRating }
        if !isServiceNA { postData["serviceRating"] = serviceRating }
        
        let overallRating = calculateOverallRating(food: isFoodNA ? nil : foodRating,
                                                   atmosphere: isAtmosphereNA ? nil : atmosphereRating,
                                                   value: isValueNA ? nil : valueRating,
                                                   service: isServiceNA ? nil : serviceRating)
        postData["overallRating"] = overallRating
        
        do {
            try await db.collection("posts").document(originalPost.id).updateData(postData)
            
            // Create an updated post
            var updatedPost = originalPost
            updatedPost.caption = newCaption
            updatedPost.foodRating = isFoodNA ? nil : foodRating
            updatedPost.atmosphereRating = isAtmosphereNA ? nil : atmosphereRating
            updatedPost.valueRating = isValueNA ? nil : valueRating
            updatedPost.serviceRating = isServiceNA ? nil : serviceRating
            updatedPost.overallRating = overallRating
            
            await setLoading(false)
            
            return updatedPost
        } catch {
            print("Error updating post: \(error.localizedDescription)")
            await setLoading(false)
            return nil
        }
    }
    
    private func calculateOverallRating(food: Double?, atmosphere: Double?, value: Double?, service: Double?) -> Double {
        let ratings = [food, atmosphere, value, service].compactMap { $0 }
        return ratings.isEmpty ? 0 : ratings.reduce(0, +) / Double(ratings.count)
    }
    
    @MainActor
    private func setLoading(_ value: Bool) {
        isLoading = value
    }
}
