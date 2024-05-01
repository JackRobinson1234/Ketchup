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
    func updatePrivateMode(newValue: Bool) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let userRef = FirestoreConstants.UserCollection.document(currentUid)
        try await userRef.updateData(["privateMode": newValue])
    }
    
}

// MARK: - Following

extension UserService {
    func follow(uid: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        async let _ = try FirestoreConstants
            .UserFollowingCollection(uid: currentUid)
            .document(uid)
            .setData([:])
        
        async let _ = try FirestoreConstants
            .UserCollection
            .document(currentUid)
            .updateData(["stats.following" : FieldValue.increment(Int64(1))])
        
        async let _ = try FirestoreConstants
            .UserFollowerCollection(uid: uid)
            .document(currentUid)
            .setData([:])
        
        async let _ = try FirestoreConstants
            .UserCollection
            .document(uid)
            .updateData(["stats.followers" : FieldValue.increment(Int64(1))])
        
    }
    
    func unfollow(uid: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        async let _ = try FirestoreConstants
            .UserCollection
            .document(currentUid)
            .updateData(["stats.following" : FieldValue.increment(Int64(-1))])

        async let _ = try FirestoreConstants
            .UserFollowingCollection(uid: currentUid)
            .document(uid)
            .delete()

        async let _ = try FirestoreConstants
            .UserFollowerCollection(uid: uid)
            .document(currentUid)
            .delete()
        
        async let _ = try FirestoreConstants
            .UserCollection
            .document(uid)
            .updateData(["stats.followers" : FieldValue.increment(Int64(-1))])
        
    }

    
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


