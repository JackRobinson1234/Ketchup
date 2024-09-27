
//
//  UploadService.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/23/24.
//

import Firebase
import SwiftUI
import FirebaseFirestoreInternal
class UploadService {
    static let shared = UploadService() // Singleton instance
    private init() {}
    @Published var newestPost: Post? = nil

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
            thumbnailImage: UIImage?,
            progressHandler: @escaping (Double) -> Void
        ) async throws -> Post {
            let user = try await UserService.shared.fetchCurrentUser()
            let ref = FirestoreConstants.PostsCollection.document()
            
            var thumbnailUrl = ""
            var currentProgress = 0.0
            let totalProgressSteps = 2.0 // Assuming two main steps: uploading thumbnail and uploading post data
            
            // Step 1: Upload Thumbnail Image
            if let thumbnailImage = thumbnailImage {
                // Use the provided thumbnail image
                thumbnailUrl = try await ImageUploader.uploadImage(image: thumbnailImage, type: .post, progressHandler: { progress in
                    let overallProgress = (progress / totalProgressSteps)
                    progressHandler(overallProgress)
                }) ?? ""
                currentProgress += 1.0 / totalProgressSteps
            } else if let firstItem = mixedMediaItems?.first {
                thumbnailUrl = firstItem.url
                if firstItem.type == .video {
                    thumbnailUrl = try await updateThumbnailUrl(fromVideoUrl: thumbnailUrl, progressHandler: { progress in
                        let overallProgress = (progress / totalProgressSteps)
                        progressHandler(overallProgress)
                    })
                    currentProgress += 1.0 / totalProgressSteps
                }
            } else {
                // No thumbnail to upload
                currentProgress += 1.0 / totalProgressSteps
            }
            
            // Step 2: Upload Post Data to Firestore
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
                user: PostUser(
                    id: user.id,
                    fullname: user.fullname,
                    profileImageUrl: user.profileImageUrl,
                    privateMode: user.privateMode,
                    username: user.username
                ),
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
            
            // Update progress after uploading post data
            currentProgress += 1.0 / totalProgressSteps
            progressHandler(currentProgress)
            
            newestPost = post
            return post
        }
        
        func updateThumbnailUrl(fromVideoUrl videoUrl: String, progressHandler: @escaping (Double) -> Void) async throws -> String {
            guard let image = MediaHelpers.generateThumbnail(path: videoUrl) else {
                throw UploadError.thumbnailGenerationFailed
            }
            guard let thumbnailUrl = try await ImageUploader.uploadImage(image: image, type: .post, progressHandler: progressHandler) else {
                throw UploadError.imageUploadFailed
            }
            return thumbnailUrl
        }
    func createPostRestaurant(from restaurant: Restaurant) -> PostRestaurant {
        return PostRestaurant(
            id: restaurant.id,
            name: restaurant.name,
            geoPoint: restaurant.geoPoint,
            geoHash: restaurant.geoHash,
            truncatedGeohash: restaurant.geoHash.flatMap { String($0.prefix(4)) },
            truncatedGeohash6: restaurant.geoHash.flatMap { String($0.prefix(6)) },
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
    static func uploadImage(image: UIImage, type: UploadType, progressHandler: @escaping (Double) -> Void) async throws -> String? {
            guard let imageData = image.jpegData(compressionQuality: 0.5) else { return nil }
            let ref = type.filePath
            
            return try await withCheckedThrowingContinuation { continuation in
                let uploadTask = ref.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        ref.downloadURL { url, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else if let url = url {
                                continuation.resume(returning: url.absoluteString)
                            }
                        }
                    }
                }
                
                uploadTask.observe(.progress) { snapshot in
                    let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
                    progressHandler(percentComplete)
                }
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
    static func uploadVideoToStorage(withUrl url: URL, progressHandler: @escaping (Double) -> Void) async throws -> String? {
            let filename = NSUUID().uuidString
            let ref = Storage.storage().reference(withPath: "/post_videos/").child(filename)
            let metadata = StorageMetadata()
            metadata.contentType = "video/quicktime"
            
            let data = try Data(contentsOf: url)
            
            return try await withCheckedThrowingContinuation { continuation in
                let uploadTask = ref.putData(data, metadata: metadata) { metadata, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        ref.downloadURL { url, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else if let url = url {
                                continuation.resume(returning: url.absoluteString)
                            }
                        }
                    }
                }
                
                uploadTask.observe(.progress) { snapshot in
                    let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
                    progressHandler(percentComplete)
                }
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
