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
    
    private var originalPost: Post
    private var db: Firestore
    
    init(post: Post) {
        self.originalPost = post
        self.db = Firestore.firestore()
    }
    
    func updatePost(newCaption: String, foodRating: Double, atmosphereRating: Double, valueRating: Double, serviceRating: Double, overallRating: Double) async -> Post? {
        await setLoading(true)
        
        let postData: [String: Any] = [
            "caption": newCaption,
            "foodRating": foodRating,
            "atmosphereRating": atmosphereRating,
            "valueRating": valueRating,
            "serviceRating": serviceRating,
            "overallRating": overallRating
        ]
        
        do {
            try await db.collection("posts").document(originalPost.id).updateData(postData)
            
            // Create an updated post
            var updatedPost = originalPost
            updatedPost.caption = newCaption
            updatedPost.foodRating = foodRating
            updatedPost.atmosphereRating = atmosphereRating
            updatedPost.valueRating = valueRating
            updatedPost.serviceRating = serviceRating
            updatedPost.overallRating = overallRating
            
            await setLoading(false)
            
            return updatedPost
        } catch {
            print("Error updating post: \(error.localizedDescription)")
            await setLoading(false)
            return nil
        }
    }
    
    @MainActor
    private func setLoading(_ value: Bool) {
        isLoading = value
    }
}
