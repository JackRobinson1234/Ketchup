//
//  PostListViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
@MainActor
class PostListViewModel: ObservableObject {
    private let postService: PostService
    private let userService: UserService
    @Published var posts = [Post]()
    init(postService: PostService, userService: UserService) {
        self.postService = postService
        self.userService = userService
        Task { await fetchPosts() }
    }
    
    func fetchPosts() async {
        do {
            if posts.isEmpty {
                posts = try await postService.fetchPosts()
                posts.shuffle()
            }
        } catch {
            print("DEBUG: Failed to fetch posts \(error.localizedDescription)")
        }
    }
}
    
    
    
    
    
    /*@Published var posts = [Post]()
   
    init() {
        Task {
            try await fetchRandomPosts(count: 20)
        }
    }
    @MainActor
    func fetchRandomPosts(count: Int) async throws {
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
        } catch {
            // Handle error if fetching documents fails
            throw error
        }
    }
    func fetchPosts() {
        Task{
            try await fetchRandomPosts(count: 25)
        }
    }
}
*/
