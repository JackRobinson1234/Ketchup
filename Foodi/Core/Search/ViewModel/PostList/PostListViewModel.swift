//
//  PostListViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
class PostListViewModel: ObservableObject {
    @Published var posts = [Post]()
    
    func fetchRandomPosts(count: Int) async throws -> [Post] {
        let postsCollection = FirestoreConstants.PostsCollection
        
        // Fetch 20 random posts
        let query = postsCollection
            .order(by: "timestamp") // Replace "someFieldForSorting" with the actual field you want to use for sorting
            .limit(to: count)
        
        do {
            let querySnapshot = try await query.getDocuments()
            
            // Convert query snapshot to an array of Post objects
            self.posts = querySnapshot.documents.compactMap { document -> Post? in
                do {
                    return try document.data(as: Post.self)
                } catch {
                    // Handle error if conversion fails
                    print("Error converting document to Post: \(error)")
                    return nil
                }
            }
            
            return posts
        } catch {
            // Handle error if fetching documents fails
            throw error
        }
    }
}
