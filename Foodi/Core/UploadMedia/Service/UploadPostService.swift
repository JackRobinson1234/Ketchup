//
//  UploadPostService.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import Firebase

struct UploadPostService {
    func uploadPost(caption: String, videoUrlString: String, restaurantId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = FirestoreConstants.PostsCollection.document()
        
        do {
            guard let url = URL(string: videoUrlString) else { return }
            guard let videoUrl = try await VideoUploader.uploadVideoToStorage(withUrl: url) else { return }
                        
            let post = Post(
                id: ref.documentID,
                videoUrl: videoUrl,
                ownerUid: uid,
                caption: caption,
                likes: 0,
                commentCount: 0,
                saveCount: 0,
                shareCount: 0,
                views: 0,
                thumbnailUrl: "",
                timestamp: Timestamp(),
                restaurant: postRestaurant(id: NSUUID().uuidString,
                                           cuisine: "Chinese",
                                           price: "$",
                                           name: "Greenbaum's Money Pit",
                                           geoPoint: GeoPoint(latitude: 37.868883834260735, longitude: -122.25118022568488),
                                           address: "2311 Piedmont Ave",
                                           city: "Berkeley",
                                           state: "CA")
            )

            guard let postData = try? Firestore.Encoder().encode(post) else { return }
            try await ref.setData(postData)
            async let _ = try updateThumbnailUrl(fromVideoUrl: videoUrl, postId: ref.documentID)
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
}
