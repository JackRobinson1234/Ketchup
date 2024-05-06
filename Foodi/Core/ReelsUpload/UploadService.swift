
//
//  UploadService.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/23/24.
//

import Firebase
import SwiftUI

struct UploadService {
    
    func uploadPost(videoURL: URL?, picData: [Data]?, mediaType: String, caption: String, postType: String, postRestaurant: PostRestaurant?, postRecipe: PostRecipe?) async throws {
        let user = try await UserService.shared.fetchCurrentUser()  // Fetch user data
        let ref = FirestoreConstants.PostsCollection.document()  // Create a new document reference

        var mediaUrls = [String]()

        // Determine the media URL based on type
        if mediaType == "video", let videoURL = videoURL {
            guard let videoUrl = try await VideoUploader.uploadVideoToStorage(withUrl: videoURL) else {
                throw UploadError.videoUploadFailed
            }
            mediaUrls.append(videoUrl)
        } else if mediaType == "photo", let picData = picData {
            for imageData in picData {
                guard let image = UIImage(data: imageData) else {
                    print("Unable to convert Data to UIImage")
                    continue  // Optionally, you can handle this more strictly by throwing an error
                }
                if let imageUrl = try await ImageUploader.uploadImage(image: image, type: .post) {
                    mediaUrls.append(imageUrl)
                } else {
                    print("Failed to upload one of the images")
                    // Optionally, you can also throw an error here to stop the process if any image fails to upload.
                }
            }
        } else {
            throw UploadError.invalidMediaData
        }

        // Create the post object
        let post = Post(
            id: ref.documentID,
            postType: postType,
            mediaType: mediaType,
            mediaUrls: mediaUrls,
            caption: caption,
            likes: 0,
            commentCount: 0,
            shareCount: 0,
            thumbnailUrl: "",
            timestamp: Timestamp(),
            user: PostUser(id: user.id, fullName: user.fullname, profileImageUrl: user.profileImageUrl, privateMode: user.privateMode, username: user.username),
            restaurant: postRestaurant,
            recipe: postRecipe
        )
        
        // Encode the post data
        guard let postData = try? Firestore.Encoder().encode(post) else {
            print("Encoding failed for post data")
            throw UploadError.encodingFailed
        }
        
        // Set the post data in Firestore
        try await ref.setData(postData)
        print("Post created successfully")

        // Update the thumbnail after the post is created if it's a video
        if mediaType == "video", let videoUrl = mediaUrls.first {
            try await updateThumbnailUrl(fromVideoUrl: videoUrl, postId: ref.documentID)
        }
    }
    
    func updateThumbnailUrl(fromVideoUrl videoUrl: String, postId: String) async throws {
        guard let image = MediaHelpers.generateThumbnail(path: videoUrl) else {
            throw UploadError.thumbnailGenerationFailed
        }
        guard let thumbnailUrl = try await ImageUploader.uploadImage(image: image, type: .post) else {
            throw UploadError.imageUploadFailed
        }
        try await FirestoreConstants.PostsCollection.document(postId).updateData([
            "thumbnailUrl": thumbnailUrl
        ])
    }
}
