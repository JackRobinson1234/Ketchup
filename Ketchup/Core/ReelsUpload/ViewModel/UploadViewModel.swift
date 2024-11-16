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
import Combine
import Foundation
@MainActor
class UploadViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var caption = ""
    @Published var uploadSuccess: Bool = false
    @Published var uploadFailure: Bool = false
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
    @Published var uploadProgress: Double = 0.0
    @Published var goodFor: [String] = []
    @Published var navigateToMediaCategorySelection = false
// Add this line
    var mentionableUsers: [User] = []  // Assuming you have this data available
    var currentPoints: Int {
            var points = 2 // Automatically get 2 points for uploading.

            if !caption.isEmpty {
                points += 2
            }

            if mixedMediaItems.contains(where: { $0.description != nil || $0.descriptionCategory != nil }) {
                points += 2
            }

            if !taggedUsers.isEmpty {
                points += 2
            }

            if !goodFor.isEmpty {
                points += 2
            }

            return points
        }

        // Maximum possible points
        let maxPoints: Int = 10

        // Determine the next step to achieve full points
        var nextStep: String? {
            if currentPoints == maxPoints {
                return nil // All steps completed.
            }
            if caption.isEmpty {
                return "Add a caption to get more points."
            } else if !mixedMediaItems.contains(where: { $0.description != nil || $0.descriptionCategory != nil }) {
                return "Tag your media to get more points."
            } else if taggedUsers.isEmpty {
                return "Tag a user to get more points."
            } else if goodFor.isEmpty {
                return "Add 'What is this place good for?' to get more points."
            } else {
                return nil
            }
        }
    init(feedViewModel: FeedViewModel, currentUserFeedViewModel: FeedViewModel) {
           self.feedViewModel = feedViewModel
           self.currentUserFeedViewModel = currentUserFeedViewModel

           // Observe changes in mixedMediaItems
           $mixedMediaItems
               .flatMap { items in
                   Publishers.MergeMany(items.map { $0.objectWillChange })
               }
               .receive(on: RunLoop.main)
               .sink { [weak self] _ in
                   self?.objectWillChange.send()
               }
               .store(in: &cancellables)
       }
    private var cancellables = Set<AnyCancellable>()

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
    
    func uploadPost() async throws-> Post?{
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
            isLoading = false
            reset()
            return post
            
        } catch {
            handleUploadFailure(error: error)
            isLoading = false
            reset()
            return nil
        }
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
                    username: user.username,
                    statusNameImage: user.statusImageName
                ))
            } else if let fetchedUser = try? await UserService.shared.fetchUser(byUsername: username) {
                mentionedUsers.append(PostUser(
                    id: fetchedUser.id,
                    fullname: fetchedUser.fullname,
                    profileImageUrl: fetchedUser.profileImageUrl,
                    privateMode: fetchedUser.privateMode,
                    username: fetchedUser.username,
                    statusNameImage: fetchedUser.statusImageName
                ))
            } else {
                mentionedUsers.append(PostUser(
                    id: "invalid",
                    fullname: "invalid",
                    profileImageUrl: nil,
                    privateMode: false,
                    username: username,
                    statusNameImage: "BEGINNER1"
                ))
            }
        }
        
        return mentionedUsers
    }
    
    private func uploadMixedMediaItems() async throws -> [MixedMediaItem]? {
        guard !mixedMediaItems.isEmpty else { return nil }

        var uploadedItems: [MixedMediaItem] = []
        let totalItems = Double(mixedMediaItems.count)

        for (index, item) in mixedMediaItems.enumerated() {
            let baseProgress = Double(index) / totalItems

            switch item.type {
            case .photo:
                if let image = item.localMedia as? UIImage {
                    let imageUrl = try await ImageUploader.uploadImage(image: image, type: .post) { [baseProgress, totalItems] progress in
                        DispatchQueue.main.async {
                            let itemProgress = progress / totalItems
                            self.uploadProgress = baseProgress + itemProgress
                        }
                    }
                    if let imageUrl = imageUrl {
                        let mixedItem = MixedMediaItem(
                            url: imageUrl,
                            type: .photo,
                            description: item.description,
                            descriptionCategory: item.descriptionCategory
                        )
                        uploadedItems.append(mixedItem)
                    }
                }
            case .video:
                if let videoURL = item.localMedia as? URL {
                    let videoUrl = try await VideoUploader.uploadVideoToStorage(withUrl: videoURL) { [baseProgress, totalItems] progress in
                        DispatchQueue.main.async {
                            let itemProgress = progress / totalItems
                            self.uploadProgress = baseProgress + itemProgress
                        }
                    }
                    if let videoUrl = videoUrl {
                        let mixedItem = MixedMediaItem(
                            url: videoUrl,
                            type: .video,
                            description: item.description,
                            descriptionCategory: item.descriptionCategory
                        )
                        uploadedItems.append(mixedItem)
                    }
                }
            default:
                break
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
        
        // Calculate average rating
        let ratings = [
            isServiceNA ? nil : serviceRating,
            isAtmosphereNA ? nil : atmosphereRating,
            isValueNA ? nil : valueRating,
            isFoodNA ? nil : foodRating
        ].compactMap { $0 }
        
        let averageRating: Double?
        if !ratings.isEmpty {
            let sum = ratings.reduce(0, +)
            averageRating = (sum / Double(ratings.count)).rounded(to: 1)
        } else {
            averageRating = nil
        }
        
        return try await UploadService.shared.uploadPost(
            mixedMediaItems: mixedMediaItems,
            mediaType: .mixed,
            caption: caption,
            postRestaurant: postRestaurant,
            fromInAppCamera: fromInAppCamera,
            overallRating: averageRating, // Use calculated average rating
            serviceRating: isServiceNA ? nil : serviceRating,
            atmosphereRating: isAtmosphereNA ? nil : atmosphereRating,
            valueRating: isValueNA ? nil : valueRating,
            foodRating: isFoodNA ? nil : foodRating,
            taggedUsers: taggedUsers,
            captionMentions: mentionedUsers,
            goodFor: self.goodFor.isEmpty ? nil : self.goodFor, // Add this line
            thumbnailImage: thumbnailImage,
            progressHandler: { progress in
                DispatchQueue.main.async {
                    //self.uploadProgress = progress
                }
            }
        )
    }

    private func handleUploadSuccess(post: Post) {
        uploadSuccess = true
        feedViewModel.showPostAlert = true
        feedViewModel.selectedMainTab = .feed
        feedViewModel.posts.insert(post, at: 0)
        
        if !fromRestaurantProfile{
            currentUserFeedViewModel.posts.insert(post, at: 0)
        }
        if let currentUser = AuthService.shared.userSession {
            let postDate = Date() // Or use the server timestamp if available
            updateWeeklyStreak(for: currentUser, withPostDate: postDate)
        }
        showSuccessMessage = true
    }
    private func updateWeeklyStreak(for user: User, withPostDate postDate: Date) {
        let calendar = Calendar.current
        
        // Calculate the start of the week for the current post
        let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: postDate))!
        
        var newStreak = user.weeklyStreak
        
        if let lastPostDate = user.mostRecentPost {
            // Calculate the start of the week for the last post
            let lastPostWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastPostDate))!
            
            if currentWeekStart > lastPostWeekStart {
                // This is the first post of the new week
                newStreak += 1
            }
        } else {
            // This is the user's first post ever
            newStreak = 1
        }
        
        // Update user locally
        var updatedUser = user
        updatedUser.stats.posts += 1
        updatedUser.weeklyStreak = newStreak
        updatedUser.mostRecentPost = postDate
        
        // Update AuthService.shared.userSession
        AuthService.shared.userSession = updatedUser
        
        // Update user in Firestore
        let userRef = Firestore.firestore().collection("users").document(user.id)
        userRef.updateData([
            "weeklyStreak": newStreak,
            "mostRecentPost": Timestamp(date: postDate)
        ]) { error in
            if let error = error {
                //print("Error updating user streak: \(error.localizedDescription)")
            } else {
                //print("Successfully updated user streak. New streak: \(newStreak)")
            }
        }
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
                ////print("Error fetching following users: \(error)")
            }
        }
    }
    
}
class MixedMediaItemHolder: Identifiable, ObservableObject {
    let id = UUID()
    var localMedia: Any  // UIImage for photos, URL for videos
    var type: MediaType
    var url: String?  // This will be set after uploading to Firebase
    @Published var description: String?
    @Published var descriptionCategory: DescriptionCategory?

    init(localMedia: Any, type: MediaType) {
        self.localMedia = localMedia
        self.type = type
    }
}
