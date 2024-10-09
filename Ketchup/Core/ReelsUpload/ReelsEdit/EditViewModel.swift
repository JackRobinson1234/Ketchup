//
//  EditViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/10/24.
//

import Foundation
import FirebaseFirestoreInternal
import SwiftUI
class ReelsEditViewModel: ObservableObject {
    @Published private(set) var isLoading: Bool = false
    @Published var isFoodNA: Bool
    @Published var isAtmosphereNA: Bool
    @Published var isValueNA: Bool
    @Published var isServiceNA: Bool
    @Published var caption: String
    @Published var taggedUsers: [PostUser]
    @Published var filteredMentionedUsers: [User] = []
    @Published var isMentioning: Bool = false
    
    private var originalPost: Post
    private var db: Firestore
    private var mentionableUsers: [User] = []
    
    init(post: Post) {
        
        self.originalPost = post
        self.db = Firestore.firestore()
        self.isFoodNA = post.foodRating == nil
        self.isAtmosphereNA = post.atmosphereRating == nil
        self.isValueNA = post.valueRating == nil
        self.isServiceNA = post.serviceRating == nil
        self.caption = post.caption
        self.taggedUsers = post.taggedUsers
        fetchFollowingUsers()
    }
    
    func updatePost(newCaption: String, foodRating: Double, atmosphereRating: Double, valueRating: Double, serviceRating: Double) async -> Post? {
        await setLoading(true)
        
        var postData: [String: Any] = [
            "caption": newCaption,
            "taggedUsers": taggedUsers.map { $0.asDictionary() }
        ]
        
        if !isFoodNA { postData["foodRating"] = foodRating }
        if !isAtmosphereNA { postData["atmosphereRating"] = atmosphereRating }
        if !isValueNA { postData["valueRating"] = valueRating }
        if !isServiceNA { postData["serviceRating"] = serviceRating }
        
        let overallRating = calculateOverallRating(food: isFoodNA ? nil : foodRating,
                                                   atmosphere: isAtmosphereNA ? nil : atmosphereRating,
                                                   value: isValueNA ? nil : valueRating,
                                                   service: isServiceNA ? nil : serviceRating)
        postData["overallRating"] = overallRating
        
        do {
            let mentionedUsers = try await extractMentionedUsers(from: newCaption)
            postData["captionMentions"] = mentionedUsers.map { $0.asDictionary() }
            try await db.collection("posts").document(originalPost.id).updateData(postData)
            
            // Create an updated post
            var updatedPost = originalPost
            updatedPost.caption = newCaption
            updatedPost.foodRating = isFoodNA ? nil : foodRating
            updatedPost.atmosphereRating = isAtmosphereNA ? nil : atmosphereRating
            updatedPost.valueRating = isValueNA ? nil : valueRating
            updatedPost.serviceRating = isServiceNA ? nil : serviceRating
            updatedPost.overallRating = overallRating
            updatedPost.taggedUsers = taggedUsers
            updatedPost.captionMentions = mentionedUsers
            
            await setLoading(false)
            
            return updatedPost
        } catch {
            ////print("Error updating post: \(error.localizedDescription)")
            await setLoading(false)
            return nil
        }
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
    private func calculateOverallRating(food: Double?, atmosphere: Double?, value: Double?, service: Double?) -> Double {
        let ratings = [food, atmosphere, value, service].compactMap { $0 }
        return ratings.isEmpty ? 0 : ratings.reduce(0, +) / Double(ratings.count)
    }
    
    @MainActor
    private func setLoading(_ value: Bool) {
        isLoading = value
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
    
    func checkForAlgoliaTagging(in caption: String) -> String {
        let words = caption.split(separator: " ")
        
        guard let lastWord = words.last, lastWord.hasPrefix("@") else {
            return ""
        }
        
        return String(lastWord.dropFirst()).lowercased()
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
extension PostUser {
    func asDictionary() -> [String: Any] {
        return [
            "id": id,
            "fullname": fullname,
            "profileImageUrl": profileImageUrl as Any,
            "privateMode": privateMode,
            "username": username
        ]
    }
}
