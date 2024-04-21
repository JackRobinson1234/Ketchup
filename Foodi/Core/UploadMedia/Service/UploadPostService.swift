//
//  UploadPostService.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import Firebase

struct UploadPostService {
    private var userService = UserService()
    func uploadRestaurantPost(caption: String, videoUrlString: String, restaurant: Restaurant)async throws {
        let user = try await userService.fetchCurrentUser()
        let ref = FirestoreConstants.PostsCollection.document()
        
        do {
            guard let url = URL(string: videoUrlString) else { return }
            guard let videoUrl = try await VideoUploader.uploadVideoToStorage(withUrl: url) else { return }
                        
            let post = Post(
                id: ref.documentID,
                videoUrl: videoUrl,
                caption: caption,
                likes: 0,
                commentCount: 0,
                saveCount: 0,
                shareCount: 0,
                views: 0,
                thumbnailUrl: "",
                timestamp: Timestamp(),
                user: PostUser(id: user.id, fullName: user.fullname, profileImageUrl: user.profileImageUrl),
                restaurant: PostRestaurant(id: restaurant.id,
                                           name: restaurant.name,
                                           geoPoint: restaurant.geoPoint,
                                           geoHash: "filler",
                                           address: restaurant.address,
                                           city: restaurant.city,
                                           state: restaurant.state,
                                           profileImageUrl: restaurant.profileImageUrl)
            )
            print(post)

            guard let postData = try? Firestore.Encoder().encode(post) else { 
                print("not encoding post right")
                return }
            async let _ = try updateThumbnailUrl(fromVideoUrl: videoUrl, postId: ref.documentID)
            try await ref.setData(postData)
        } catch {
            print("DEBUG: Failed to upload image with error \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateThumbnailUrl(fromVideoUrl videoUrl: String, postId: String) async throws {
        do {
            guard let image = MediaHelpers.generateThumbnail(path: videoUrl) else { return }
            guard let thumbnailUrl = try await ImageUploader.uploadImage(image: image, type: .post) else { return }
            try await FirestoreConstants.PostsCollection.document(postId).updateData([
                "thumbnailUrl": thumbnailUrl
            ])
        } catch {
            throw error
        }
    }
    
    func uploadRecipePost(caption: String, videoUrlString: String, recipe: postRecipe) async throws {
        let user = try await userService.fetchCurrentUser()
        let ref = FirestoreConstants.PostsCollection.document()
        
        do {
            guard let url = URL(string: videoUrlString) else { return }
            guard let videoUrl = try await VideoUploader.uploadVideoToStorage(withUrl: url) else { return }
                        
            let post = Post(
                id: ref.documentID,
                videoUrl: videoUrl,
                caption: caption,
                likes: 0,
                commentCount: 0,
                saveCount: 0,
                shareCount: 0,
                views: 0,
                thumbnailUrl: "",
                timestamp: Timestamp(),
                user: postUser(id: user.id, fullname: user.fullname, profileImageUrl: user.profileImageUrl),
                recipe: recipe
            )
            print(post)

            guard let postData = try? Firestore.Encoder().encode(post) else {
                print("not encoding post right")
                return }
            async let _ = try updateThumbnailUrl(fromVideoUrl: videoUrl, postId: ref.documentID)
            try await ref.setData(postData)
        } catch {
            print("DEBUG: Failed to upload image with error \(error.localizedDescription)")
            throw error
        }
    }

func uploadBrandPost(caption: String, videoUrlString: String, brand: postBrand) async throws {
    let user = try await userService.fetchCurrentUser()
    let ref = FirestoreConstants.PostsCollection.document()
    
    do {
        guard let url = URL(string: videoUrlString) else { return }
        guard let videoUrl = try await VideoUploader.uploadVideoToStorage(withUrl: url) else { return }
                    
        let post = Post(
            id: ref.documentID,
            videoUrl: videoUrl,
            caption: caption,
            likes: 0,
            commentCount: 0,
            saveCount: 0,
            shareCount: 0,
            views: 0,
            thumbnailUrl: "",
            timestamp: Timestamp(),
            user: postUser(id: user.id, fullname: user.fullname, profileImageUrl: user.profileImageUrl),
            brand: brand
        )
        print(post)

        guard let postData = try? Firestore.Encoder().encode(post) else {
            print("not encoding post right")
            return }
        async let _ = try updateThumbnailUrl(fromVideoUrl: videoUrl, postId: ref.documentID)
        try await ref.setData(postData)
    } catch {
        print("DEBUG: Failed to upload image with error \(error.localizedDescription)")
        throw error
    }
}
}
