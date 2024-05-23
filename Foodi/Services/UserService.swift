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
        print("DEBUG: Ran fetchUser()")
        return try await FirestoreConstants.UserCollection.document(uid).getDocument(as: User.self)
    }
    //MARK: fetchFollowingUsers
    /// fetches a list of all the users that the current user is following
    /// - Returns: list of users that the current user is following
    func fetchFollowingUsers() async throws -> [User] {
        print("DEBUG: fetching following users")
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Initialize an empty array to hold following users
        var followingUsers = [User]()
        
        // Fetch the following documents from Firestore
        let querySnapshot = try await Firestore.firestore()
            .collection("following")
            .document(currentUser.uid)
            .collection("user-following")
            .getDocuments()
        
        // Iterate through the documents and fetch user details for each following user
        for document in querySnapshot.documents {
            let followingUID = document.documentID
            
            // Fetch user details for the following user
            let user = try await fetchUser(withUid: followingUID)
            
            // Add the user to the array
            followingUsers.append(user)
        }
        
        return followingUsers
    }
    //MARK: fetchFollowingUsers(pageSize)
    ///  fetches the users that a user follows for a certain page size
    /// - Parameters:
    ///   - pageSize: number of users to be fetched
    ///   - startAfterUser: document snapshot of the last user fetched for pagination
    /// - Returns: list of users that the user is following
    func fetchFollowingUsers(pageSize: Int, startAfterUser: DocumentSnapshot? = nil) async throws -> ([User], DocumentSnapshot?) {
        print("DEBUG: Fetching following users")
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        var query = Firestore.firestore()
            .collection("following")
            .document(currentUser.uid)
            .collection("user-following")
            .order(by: FieldPath.documentID())
            .limit(to: pageSize)

        if let startAfterUser = startAfterUser {
                query = query.start(afterDocument: startAfterUser)
            }
        let querySnapshot = try await query.getDocuments()

        var followingUsers = [User]()
        var lastSnapshot: DocumentSnapshot? = nil

        for document in querySnapshot.documents {
            let followingUID = document.documentID
            let user = try await fetchUser(withUid: followingUID)
            followingUsers.append(user)
            lastSnapshot = document
        }

        return (followingUsers, lastSnapshot)
    }
    
    func updatePrivateMode(newValue: Bool) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let userRef = FirestoreConstants.UserCollection.document(currentUid)
        try await userRef.updateData(["privateMode": newValue])
    }
    
    func clearNotificationAlert() async throws {
           guard let currentUid = Auth.auth().currentUser?.uid else { throw UserError.unauthenticated }
           let userRef = FirestoreConstants.UserCollection.document(currentUid)
           try await userRef.updateData(["notificationAlert": false])
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
}


