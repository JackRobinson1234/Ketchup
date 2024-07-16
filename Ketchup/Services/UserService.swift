//
//  UserService.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import FirebaseAuth
import Firebase
import FirebaseFirestore
import SwiftUI

enum UserError: Error {
    case unauthenticated
}

class UserService {
    static let shared = UserService() // Singleton instance
    private init() {}
    
    //MARK: fetchCurrentUser
    /// fetches the current user
    /// - Returns: user object of the current user
    func fetchCurrentUser() async throws -> User {
        guard let uid = Auth.auth().currentUser?.uid else { throw UserError.unauthenticated }
        let user = try await FirestoreConstants.UserCollection.document(uid).getDocument(as: User.self)
        print("DEBUG1: running fetched currentuser: \(user.fullname)")
        return user
    }
    
    func fetchUser(withUid uid: String) async throws -> User {
        return try await FirestoreConstants.UserCollection.document(uid).getDocument(as: User.self)
    }
    //MARK: fetchFollowingUsers
    /// fetches a list of all the users that the current user is following
    /// - Returns: list of users that the current user is following
    ///
    func fetchFollowingUsers() async throws -> [User] {
        print("DEBUG: fetching following users")
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Fetch the following documents from Firestore
        let querySnapshot = try await Firestore.firestore()
            .collection("following")
            .document(currentUser.uid)
            .collection("user-following")
            .getDocuments()
        
        // Use async/await with TaskGroup for concurrent fetching
        return try await withThrowingTaskGroup(of: User.self) { group in
            var followingUsers = [User]()
            
            for document in querySnapshot.documents {
                group.addTask {
                    return try await self.fetchUser(withUid: document.documentID)
                }
            }
            
            for try await user in group {
                followingUsers.append(user)
            }
            
            return followingUsers
        }
    }
    func fetchFollowingUserIds() async throws -> [String] {
        print("DEBUG: fetching following users")
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let querySnapshot = try await Firestore.firestore()
            .collection("following")
            .document(currentUser.uid)
            .collection("user-following")
            .getDocuments()
        
        // Extract and return the document IDs directly
        return querySnapshot.documents.map { $0.documentID }
    }
    
    
    func updatePrivateMode(newValue: Bool) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let userRef = FirestoreConstants.UserCollection.document(currentUid)
        try await userRef.updateData(["privateMode": newValue])
    }
    
    func clearNotificationAlert() async throws {
           guard let currentUid = Auth.auth().currentUser?.uid else { throw UserError.unauthenticated }
           let userRef = FirestoreConstants.UserCollection.document(currentUid)
           try await userRef.updateData(["notificationAlert": 0])
       }
    
    func fetchUser(byUsername username: String) async throws -> User? {
            // Implement your method to fetch user by username
            let usersCollection = Firestore.firestore().collection("users")
            let querySnapshot = try await usersCollection.whereField("username", isEqualTo: username).getDocuments()
            guard let document = querySnapshot.documents.first else {
                return nil
            }
            return try document.data(as: User.self)
        }
    
}

// MARK: - Following
/// Adds the user from the respective following and follower collections. CLOUD FUNCTIONS UPDATE THE COUNT
/// - Parameter uid: userId to be created
extension UserService {
    func follow(uid: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        async let _ = try FirestoreConstants
            .UserFollowingCollection(uid: currentUid)
            .document(uid)
            .setData([:])
        
        
        async let _ = try FirestoreConstants
            .UserFollowerCollection(uid: uid)
            .document(currentUid)
            .setData([:])
        
        }
    //MARK: unfollow
    /// Removes the user from the respective following and follower collections. CLOUD FUNCTIONS UPDATE THE COUNT
    /// - Parameter uid: userId to be deleted
    func unfollow(uid: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        

        async let _ = try FirestoreConstants
            .UserFollowingCollection(uid: currentUid)
            .document(uid)
            .delete()

        async let _ = try FirestoreConstants
            .UserFollowerCollection(uid: uid)
            .document(currentUid)
            .delete()
        
    }

    //MARK: checkIfUserIsFollowed
    /// checks if a user is followed by the current user
    /// - Parameter uid: user to check if they are followed
    /// - Returns: boolean of if the user currently follows them or not
    func checkIfUserIsFollowed(uid: String) async -> Bool {
        guard let currentUid = Auth.auth().currentUser?.uid else { return false }
        print("DEBUG: Ran checkIfUsersIsFollowed()")
        guard let snapshot = try? await FirestoreConstants
            .UserFollowingCollection(uid: currentUid)
            .document(uid)
            .getDocument() else { return false }
        
        return snapshot.exists
    }
    func fetchCurrentUserBookmarks() async throws -> [Bookmark] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        do {
            let snapshot = try await FirestoreConstants.UserCollection
                .document(uid)
                .collection("user-bookmarks")
                .getDocuments(as: Bookmark.self)
            
            return snapshot
        } catch {
            print("Error fetching user bookmarks: \(error.localizedDescription)")
            throw error
        }
    }
    func fetchUserBookmarks(uid: String) async throws -> [Bookmark] {
        do {
            let snapshot = try await FirestoreConstants.UserCollection
                .document(uid)
                .collection("user-bookmarks")
                .order(by: "timestamp", descending: true)
                .getDocuments(as: Bookmark.self)
            return snapshot
        } catch {
            print("Error fetching user bookmarks: \(error.localizedDescription)")
            throw error
        }
    }
}


