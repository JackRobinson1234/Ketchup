
//
//  UploadService.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/23/24.
//

import Firebase
import SwiftUI
import FirebaseFirestoreInternal

struct UploadService {
    static let shared = UploadService() // Singleton instance
    private init() {}
    
    func uploadPost(
            mixedMediaItems: [MixedMediaItem]?,
            mediaType: MediaType,
            caption: String,
            postRestaurant: PostRestaurant,
            fromInAppCamera: Bool,
            overallRating: Double?,
            serviceRating: Double?,
            atmosphereRating: Double?,
            valueRating: Double?,
            foodRating: Double?,
            taggedUsers: [PostUser],
            captionMentions: [PostUser],
            thumbnailImage: UIImage?
        ) async throws -> Post {
            let user = try await UserService.shared.fetchCurrentUser()
            let ref = FirestoreConstants.PostsCollection.document()
            
            var thumbnailUrl = ""
            if let thumbnailImage = thumbnailImage {
                // Use the provided thumbnail image
                thumbnailUrl = try await ImageUploader.uploadImage(image: thumbnailImage, type: .post) ?? ""
            } else if let firstItem = mixedMediaItems?.first {
                thumbnailUrl = firstItem.url
                if firstItem.type == .video {
                    thumbnailUrl = try await updateThumbnailUrl(fromVideoUrl: thumbnailUrl)
                }
            }

            let post = Post(
                id: ref.documentID,
                mediaType: mediaType,
                mediaUrls: mixedMediaItems?.compactMap { $0.url } ?? [],
                mixedMediaUrls: mixedMediaItems ?? [],
                caption: caption,
                likes: 0,
                commentCount: 0,
                bookmarkCount: 0,
                repostCount: 0,
                thumbnailUrl: thumbnailUrl,
                timestamp: Timestamp(),
                user: PostUser(id: user.id, fullname: user.fullname, profileImageUrl: user.profileImageUrl, privateMode: user.privateMode, username: user.username),
                restaurant: postRestaurant,
                didLike: false,
                didBookmark: false,
                fromInAppCamera: fromInAppCamera,
                repost: false,
                didRepost: false,
                overallRating: overallRating,
                serviceRating: serviceRating,
                atmosphereRating: atmosphereRating,
                valueRating: valueRating,
                foodRating: foodRating,
                taggedUsers: taggedUsers,
                captionMentions: captionMentions
            )

            guard let postData = try? Firestore.Encoder().encode(post) else {
                throw UploadError.encodingFailed
            }

            try await ref.setData(postData)
            //print("Post created successfully")
            return post
        }
    
    func updateThumbnailUrl(fromVideoUrl videoUrl: String) async throws -> String{
        guard let image = MediaHelpers.generateThumbnail(path: videoUrl) else {
            throw UploadError.thumbnailGenerationFailed
        }
        guard let thumbnailUrl = try await ImageUploader.uploadImage(image: image, type: .post) else {
            throw UploadError.imageUploadFailed
        }
//        try await FirestoreConstants.PostsCollection.document(postId).updateData([
//            "thumbnailUrl": thumbnailUrl
//        ])
        return thumbnailUrl
    }
    func createPostRestaurant(from restaurant: Restaurant) -> PostRestaurant {
        return PostRestaurant(
            id: restaurant.id,
            name: restaurant.name,
            geoPoint: restaurant.geoPoint,
            geoHash: restaurant.geoHash,
            truncatedGeoHash: restaurant.geoHash.flatMap { String($0.prefix(4)) },
            address: restaurant.address,
            city: restaurant.city,
            state: restaurant.state,
            profileImageUrl: restaurant.profileImageUrl,
            cuisine: restaurant.categoryName,
            price: restaurant.price
        )
    }
}

enum UploadType {
    case profile
    case post
    case collection
    var filePath: StorageReference {
        let filename = NSUUID().uuidString
        switch self {
        case .profile:
            return Storage.storage().reference(withPath: "/profile_images/\(filename)")
        case .post:
            return Storage.storage().reference(withPath: "/post_images/\(filename)")
        case .collection:
            return Storage.storage().reference(withPath: "/collection_images/\(filename)")
        }
    }
}
//MARK: ImageUploader
struct ImageUploader {
    //MARK: uploadImage
    
    /// Uploads an image to firebase storage
    /// - Parameters:
    ///   - image: UIIMage to be uploaded
    ///   - type: File type that is to be uploaded (ex. "MP4")
    /// - Returns: Success: Download URL string, Failure: throws and returns nil
    static func uploadImage(image: UIImage, type: UploadType) async throws -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return nil }
        let ref = type.filePath
        
        do {
            let _ = try await ref.putDataAsync(imageData)
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            //print("DEBUG: Failed to upload image \(error.localizedDescription)")
            return nil
        }
    }
    //MARK: deleteImage
    /// Deletes an image from firestore
    /// - Parameter urlString: download url of where the image can be found on firebase
    static func deleteImage(fromUrl urlString: String) async throws {
            guard let url = URL(string: urlString) else {
                throw StorageError.invalidUrl
            }
            let ref = Storage.storage().reference(forURL: url.absoluteString)
            
            do {
                try await ref.delete()
            } catch {
                throw StorageError.deleteError(error.localizedDescription)
            }
        }
}

//MARK: VideoUploader
struct VideoUploader {
    //MARK: uploadVideoToStorage
    /// Uploads a video to storeage
    /// - Parameter url: url reference of the video to be uploaded to firebase
    /// - Returns: download url from firebase as a String
    static func uploadVideoToStorage(withUrl url: URL) async throws -> String? {
        let filename = NSUUID().uuidString
        let ref = Storage.storage().reference(withPath: "/post_videos/").child(filename)
        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        
        do {
            let data = try Data(contentsOf: url)
            let _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            //print("DEBUG: Failed to upload video with error: \(error.localizedDescription)")
            throw error
        }
    }
    //MARK: deleteVideo
    /// deletes a video from Firebase
    /// - Parameter urlString: string URL of the video that is to be deleted
    static func deleteVideo(fromUrl urlString: String) async throws {
            guard let url = URL(string: urlString) else {
                throw StorageError.invalidUrl
            }
            let ref = Storage.storage().reference(forURL: url.absoluteString)
            
            do {
                try await ref.delete()
            } catch {
                throw StorageError.deleteError(error.localizedDescription)
            }
        }
}
enum StorageError: Error {
    case invalidUrl
    case deleteError(String)
}
