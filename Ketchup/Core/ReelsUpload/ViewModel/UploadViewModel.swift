//
//  UploadViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//

import SwiftUI
import Firebase
import PhotosUI
import YPImagePicker

@MainActor
class UploadViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var caption = ""
    @Published var uploadSuccess: Bool = false
    @Published var uploadFailure: Bool = false
    // MEDIA TO BE UPLOADED
    @Published var videoURL: URL?
    @Published var images: [UIImage]?
    @Published var mediaType: MediaType = .video
    @Published var restaurant: Restaurant?
    @Published var navigateToUpload = false
    @Published var fromInAppCamera = true
    @Published var restaurantRequest: RestaurantRequest?
    @ObservedObject var feedViewModel: FeedViewModel
    @ObservedObject var currentUserFeedViewModel: FeedViewModel
    @Published var overallRating: Double = 5.0
    @Published var serviceRating: Double = 5.0
    @Published var atmosphereRating: Double = 5.0
    @Published var valueRating: Double = 5.0
    @Published var foodRating: Double = 5.0
    @Published var taggedUsers: [PostUser] = []
    @Published var taggedUserPreviews: [User] = []
    @Published var filteredMentionedUsers: [User] = []
    @Published var isMentioning: Bool = false
    @Published var isServiceNA: Bool = false
    @Published var isAtmosphereNA: Bool = false
    @Published var isValueNA: Bool = false
    @Published var isFoodNA: Bool = false
    @Published var isOverallNA: Bool = false
    @Published var MixedImages: [UIImage]?
    @Published var mixedMediaItems: [MixedMediaItemHolder] = []
    @Published var thumbnailImage: UIImage?
    @Published var dismissAll: Bool = false
    @Published var fromRestaurantProfile = false
    @Published var showSuccessMessage = false
    var mentionableUsers: [User] = []  // Assuming you have this data available
    
    init(feedViewModel: FeedViewModel,  currentUserFeedViewModel: FeedViewModel) {
        self.feedViewModel = feedViewModel
        self.currentUserFeedViewModel = currentUserFeedViewModel
    }
    func addMixedMediaItem(_ item: YPMediaItem) {
        switch item {
        case .photo(let photo):
            mixedMediaItems.append(MixedMediaItemHolder(localMedia: photo.image, type: .photo))
        case .video(let video):
            mixedMediaItems.append(MixedMediaItemHolder(localMedia: video.url, type: .video))
        }
    }
    func reset() {
        isLoading = false
        error = nil
        caption = ""
        uploadSuccess = false
        uploadFailure = false
        videoURL = nil
        images = []
        mediaType = .video
        restaurant = nil
        navigateToUpload = false
        fromInAppCamera = true
        overallRating = 5.0
        serviceRating = 5.0
        atmosphereRating = 5.0
        valueRating = 5.0
        foodRating = 5.0
        taggedUsers = []
        filteredMentionedUsers = []
        isMentioning = false
        mixedMediaItems = []
        thumbnailImage = nil
        
    }
    
    func uploadPost() async {
        isLoading = true
        
        do {
            let postRestaurant = try await createPostRestaurant()
            let mentionedUsers = try await extractMentionedUsers(from: caption)
            let uploadedMixedMediaItems = try await uploadMixedMediaItems()
            
            let post = try await uploadPostToService(
                mixedMediaItems: uploadedMixedMediaItems,
                postRestaurant: postRestaurant,
                mentionedUsers: mentionedUsers
            )
            
            handleUploadSuccess(post: post)
        } catch {
            handleUploadFailure(error: error)
        }
        
        isLoading = false
        reset()
    }

    private func createPostRestaurant() async throws -> PostRestaurant? {
        if let restaurant = restaurant {
            return UploadService.shared.createPostRestaurant(from: restaurant)
        } else if let restaurant = restaurantRequest {
            let postRestaurant = PostRestaurant(
                id: "construction" + NSUUID().uuidString,
                name: restaurant.name,
                geoPoint: nil,
                geoHash: nil,
                address: nil,
                city: restaurant.city.isEmpty ? nil : restaurant.city,
                state: restaurant.state.isEmpty ? nil : restaurant.state,
                profileImageUrl: nil
            )
            try await RestaurantService.shared.requestRestaurant(requestRestaurant: restaurant)
            return postRestaurant
        }
        return nil
    }

    private func extractMentionedUsers(from caption: String) async throws -> [PostUser] {
        var mentionedUsers: [PostUser] = []
        let words = caption.split(separator: " ")
        
        for word in words where word.hasPrefix("@") {
            let username = String(word.dropFirst())
            if let user = mentionableUsers.first(where: { $0.username == username }) {
                mentionedUsers.append(PostUser(
                    id: user.id,
                    fullname: user.fullname,
                    profileImageUrl: user.profileImageUrl,
                    privateMode: user.privateMode,
                    username: user.username
                ))
            } else if let fetchedUser = try? await UserService.shared.fetchUser(byUsername: username) {
                mentionedUsers.append(PostUser(
                    id: fetchedUser.id,
                    fullname: fetchedUser.fullname,
                    profileImageUrl: fetchedUser.profileImageUrl,
                    privateMode: fetchedUser.privateMode,
                    username: fetchedUser.username
                ))
            } else {
                mentionedUsers.append(PostUser(
                    id: "invalid",
                    fullname: "invalid",
                    profileImageUrl: nil,
                    privateMode: false,
                    username: username
                ))
            }
        }
        
        return mentionedUsers
    }

    private func uploadMixedMediaItems() async throws -> [MixedMediaItem]? {
        guard !mixedMediaItems.isEmpty else { return nil }
        
        var uploadedItems: [MixedMediaItem] = []
        for item in mixedMediaItems {
            switch item.type {
            case .photo:
                if let image = item.localMedia as? UIImage,
                   let imageUrl = try await ImageUploader.uploadImage(image: image, type: .post) {
                    uploadedItems.append(MixedMediaItem(url: imageUrl, type: .photo))
                }
            case .video:
                if let videoURL = item.localMedia as? URL,
                   let videoUrl = try await VideoUploader.uploadVideoToStorage(withUrl: videoURL) {
                    uploadedItems.append(MixedMediaItem(url: videoUrl, type: .video))
                }
            default:
                break  // Handle other cases if necessary
            }
        }
        
        return uploadedItems
    }

    private func uploadPostToService(
        mixedMediaItems: [MixedMediaItem]?,
        postRestaurant: PostRestaurant?,
        mentionedUsers: [PostUser]
    ) async throws -> Post {
        guard let postRestaurant else {
            throw UploadError.invalidMediaType
        }
        
        return try await UploadService.shared.uploadPost(
            mixedMediaItems: mixedMediaItems,
            mediaType: .mixed,
            caption: caption,
            postRestaurant: postRestaurant,
            fromInAppCamera: fromInAppCamera,
            overallRating: overallRating,
            serviceRating: isServiceNA ? nil : serviceRating,
            atmosphereRating: isAtmosphereNA ? nil : atmosphereRating,
            valueRating: isValueNA ? nil : valueRating,
            foodRating: isFoodNA ? nil : foodRating,
            taggedUsers: taggedUsers,
            captionMentions: mentionedUsers,
            thumbnailImage: thumbnailImage
        )
    }

    private func handleUploadSuccess(post: Post) {
        uploadSuccess = true
        feedViewModel.showPostAlert = true
        feedViewModel.posts.insert(post, at: 0)
        if !fromRestaurantProfile{
            currentUserFeedViewModel.posts.insert(post, at: 0)
        }
        showSuccessMessage = true
    }

    private func handleUploadFailure(error: Error) {
        self.error = error
        uploadFailure = true
    }

    
    
    func checkForMentioning() {
        let words = caption.split(separator: " ")
        
        if caption.last == " " {
            isMentioning = false
            filteredMentionedUsers = []
            return
        }
        
        guard let lastWord = words.last, lastWord.hasPrefix("@") else {
            isMentioning = false
            filteredMentionedUsers = []
            return
        }

        let searchQuery = String(lastWord.dropFirst()).lowercased()
        if searchQuery.isEmpty {
            filteredMentionedUsers = mentionableUsers
        } else {
            filteredMentionedUsers = mentionableUsers.filter { $0.username.lowercased().contains(searchQuery) }
        }

        isMentioning = true
    }
    func checkForAlgoliaTagging() -> String{
        let words = caption.split(separator: " ")
        
        if caption.last == " " {
            isMentioning = false
            filteredMentionedUsers = []
            return ""
        }
        
        guard let lastWord = words.last, lastWord.hasPrefix("@") else {
            isMentioning = false
            filteredMentionedUsers = []
            return ""
        }

        let searchQuery = String(lastWord.dropFirst()).lowercased()
        if searchQuery.isEmpty {
            filteredMentionedUsers = mentionableUsers
        } else {
            filteredMentionedUsers = mentionableUsers.filter { $0.username.lowercased().contains(searchQuery) }
        }

        isMentioning = true
        return searchQuery
    }
    
    func addMention(user: User) {
        // Add the mention to the caption and reset mentioning state
        guard let lastWordRange = caption.range(of: "@\(caption.split(separator: " ").last ?? "")") else { return }
        caption.replaceSubrange(lastWordRange, with: "@\(user.username)")
        isMentioning = false
        filteredMentionedUsers = []
    }
    
    func fetchFollowingUsers() {
        Task {
            do {
                let users = try await UserService.shared.fetchFollowingUsers()
                DispatchQueue.main.async {
                    self.mentionableUsers = users
                }
            } catch {
                //print("Error fetching following users: \(error)")
            }
        }
    }
}
struct MixedMediaItemHolder: Identifiable {
    let id = UUID()
    var localMedia: Any  // UIImage for photos, URL for videos
    var type: MediaType
    var url: String?  // This will be set after uploading to Firebase
}
