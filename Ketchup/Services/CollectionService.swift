//
//  CollectionService.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import Foundation
import Firebase
import MapKit
import GeoFire
import FirebaseFirestoreInternal
import SwiftUI

class CollectionService {
    static let shared = CollectionService() // Singleton instance
    private init() {}
    //MARK: fetchCollections
    /// fetches a list of collections for a user
    /// - Parameter user: user you want the collections for
    /// - Returns: array of collections
    func fetchCollections(user: String) async throws -> [Collection] {
        ////print("DEBUG: Ran fetchUserPost")
        let collections = try await FirestoreConstants
            .CollectionsCollection
            .whereField("uid", isEqualTo: user)
            .order(by: "timestamp", descending: true)
            .getDocuments(as: Collection.self)
        return collections
    }
    func fetchCollectionsWhereUserIsCollaborator(user: String) async throws -> [Collection] {
           let collections = try await FirestoreConstants
               .CollectionsCollection
               .whereField("collaborators", arrayContains: user)
               .order(by: "timestamp", descending: true)
               .getDocuments(as: Collection.self)
           return collections
       }
    func fetchCollection(withId id: String) async throws -> Collection {
        let collectionRef = FirestoreConstants.CollectionsCollection.document(id)
        let collection = try await collectionRef.getDocument(as: Collection.self)
        return collection
    }
    //MARK: fetchItems
    /// fetches items for a given collection
    /// - Parameter collection: collection you want the items for
    /// - Returns: array of collection items from that collection
    func fetchItems(collection: Collection) async throws -> [CollectionItem]{
        let collectionRef = FirestoreConstants.CollectionsCollection.document(collection.id)
        let itemsQuery = collectionRef.collection("items")
        
        do {
            let items = try await itemsQuery.getDocuments(as: CollectionItem.self)
            return items
        } catch {
            throw error
        }
    }
    
    //MARK: addItemToCollection
    /// Adds item to the collection Id that is already attached
    /// - Parameter collectionItem: item to be added to the item.collectionID colecton
    // ... existing code ...
    
    func addItemToCollection(collectionItem: CollectionItem) async throws {
        let collectionRef = FirestoreConstants.CollectionsCollection.document(collectionItem.collectionId)
        let subCollectionRef = collectionRef.collection("items")
        
        guard let itemData = try? Firestore.Encoder().encode(collectionItem) else {
            //print("not encoding collection item right")
            return
        }
        
        let query = subCollectionRef.whereField("id", isEqualTo: collectionItem.id)
        let querySnapshot = try await query.getDocuments()
        
        if querySnapshot.documents.isEmpty {
            try await collectionRef.updateData(["restaurantCount": FieldValue.increment(Int64(1))])
            
            // Update tempImageUrls
            var collection = try await collectionRef.getDocument(as: Collection.self)
            collection.updatetempImageUrls(with: collectionItem)
            if let urls = collection.tempImageUrls {
                try await collectionRef.updateData(["tempImageUrls": urls])
            }
        }
        
        try await subCollectionRef.document(collectionItem.id).setData(itemData)
    }
    
    // MARK: removeItemFromCollection
    /// - Parameter collectionItem: item to be deleted
    func removeItemFromCollection(collectionItem: CollectionItem) async throws {
        let collectionRef = FirestoreConstants.CollectionsCollection.document(collectionItem.collectionId)
        let subCollectionRef = collectionRef.collection("items").document(collectionItem.id)
        
        // Delete the item document from the subcollection
        try await subCollectionRef.delete()
        try await collectionRef.updateData(["restaurantCount": FieldValue.increment(Int64(-1))])
        
        // Update tempImageUrls
        var collection = try await collectionRef.getDocument(as: Collection.self)
        collection.removeCoverImageUrl(for: collectionItem)
        if let urls = collection.tempImageUrls {
            try await collectionRef.updateData(["tempImageUrls": urls])
        } else {
            try await collectionRef.updateData(["tempImageUrls": FieldValue.delete()])
        }
    }
    //MARK: uploadCollection
    /// Uploads a new Collection to firebase
    /// - Parameters:
    ///   - uid: userID String
    ///   - title: name of the collection
    ///   - description: description for the collection
    ///   - username: user's username
    ///   - uiImage: Cover image for the collection
    /// - Returns: Created Collection
    func uploadCollection(uid: String, title: String, description: String?, username: String, uiImage: UIImage?, profileImageUrl: String?, fullname: String) async throws -> Collection? {
        let ref = FirestoreConstants.CollectionsCollection.document()
        do {
            var imageUrl: String? = nil
            if let uiImage = uiImage {
                do {
                    imageUrl = try await ImageUploader.uploadImage(image: uiImage, type: .collection,
                                                                   progressHandler: { progress in
                                                                       DispatchQueue.main.async {
                                                                          // self.uploadProgress = progress
                                                                       }
                                                                   })
                } catch {
                    //print("Error uploading image: \(error)")
                    // Handle the error, such as showing an alert to the user
                    return nil
                }
            }
            let collection = Collection(id: ref.documentID, name: title, timestamp: Timestamp(), description: description, username: username, fullname: fullname, uid: uid, coverImageUrl: imageUrl, restaurantCount: 0, privateMode: false, profileImageUrl: profileImageUrl)
            //print(collection)
            guard let collectionData = try? Firestore.Encoder().encode(collection) else {
                //print("not encoding collection right")
                return nil}
            try await ref.setData(collectionData)
            return collection
        } catch {
            //print("DEBUG: Failed to upload Collection with error \(error.localizedDescription)")
            throw error
        }
    }
    //MARK: deleteCollection
    /// deletes a collection from firebase and corresponding items subcollection
    /// - Parameter selectedCollection: collection to be deleted
    func deleteCollection(selectedCollection: Collection) async throws {
        try await FirestoreConstants.CollectionsCollection.document(selectedCollection.id).delete()
        //print("Collection deleted successfully.")
    }
    
    
    func fetchRestaurantCollections(restaurantId: String) async throws -> [Collection] {
        var fetchedCollections: [Collection] = []
        let collectionIds = try await FirestoreConstants.RestaurantCollection.document(restaurantId).collection("collections").getDocuments()
        //print(collectionIds)
        for collectionId in collectionIds.documents {
            //print(collectionId)
            let collectionRef = FirestoreConstants.CollectionsCollection.document(collectionId.documentID)
            let collection = try await collectionRef.getDocument(as: Collection.self)
            fetchedCollections.append(collection)
            
        }
        //print("fetchedCollections", fetchedCollections)
        return fetchedCollections
    }
    func fetchPaginatedCollections(lastDocument: QueryDocumentSnapshot?, limit: Int) async throws -> (collections: [Collection], lastDocument: QueryDocumentSnapshot?) {
        var query = FirestoreConstants.CollectionsCollection
            .whereField("restaurantCount", isGreaterThan: 0)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        let snapshot = try await query.getDocuments()
        let collections = try snapshot.documents.compactMap { try $0.data(as: Collection.self) }
        return (collections, snapshot.documents.last)
    }
    func likeCollection(_ collection: Collection) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        async let _ = try FirestoreConstants.CollectionsCollection.document(collection.id).collection("collection-likes").document(uid).setData([:])
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-collection-likes").document(collection.id).setData([:])
    }
    
    func unlikeCollection(_ collection: Collection) async throws {
        guard collection.likes > 0 else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        async let _ = try FirestoreConstants.CollectionsCollection.document(collection.id).collection("collection-likes").document(uid).delete()
        async let _ = try FirestoreConstants.UserCollection.document(uid).collection("user-collection-likes").document(collection.id).delete()
        
        
    }
    
    func checkIfUserLikedCollection(_ collection: Collection) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        let snapshot = try await FirestoreConstants.UserCollection.document(uid).collection("user-collection-likes").document(collection.id).getDocument()
        return snapshot.exists
    }
    
    func fetchUserLikedCollections(userId: String) async throws -> [Collection] {
        let querySnapshot = try await FirestoreConstants
            .UserCollection
            .document(userId)
            .collection("user-collection-likes")
            .getDocuments()
        let collectionIds = querySnapshot.documents.map { $0.documentID }
        var likedCollections: [Collection] = []
        for collectionId in collectionIds {
            do {
                let collection = try await self.fetchCollection(withId: collectionId)
                likedCollections.append(collection)
            } catch {
                //print("Error fetching collection with id \(collectionId): \(error.localizedDescription)")
            }
        }
        return likedCollections
    }
    func inviteUserToCollection(
        collectionId: String,
        collectionName: String,
        collectionCoverImageUrl: String?,
        inviterUid: String,
        inviterUsername: String,
        inviterProfileImageUrl: String?,
        tempImageUrls: [String]?,
        inviteeUid: String
    ) async throws {
        let collectionRef = FirestoreConstants.CollectionsCollection.document(collectionId)
        
        // Step 1: Update the pendingInvitations in the collection
        try await collectionRef.updateData([
            "pendingInvitations": FieldValue.arrayUnion([inviteeUid])
        ])
        
        // Step 2: Create the invite document in the user's subcollection
        let invite = CollectionInvite(
            id: collectionId,
            collectionId: collectionId,
            collectionName: collectionName,
            collectionCoverImageUrl: collectionCoverImageUrl,
            inviterUid: inviterUid,
            inviterUsername: inviterUsername,
            inviterProfileImageUrl: inviterProfileImageUrl,
            status: .pending,
            timestamp: Timestamp(),
            tempImageUrls: tempImageUrls
        )
        
        let inviteRef = FirestoreConstants.UserCollection.document(inviteeUid).collection("collection-invites").document(collectionId)
        try await inviteRef.setData(from: invite)
    }
    func fetchCollaborationInvites() async throws -> [CollectionInvite] {
            guard let userId = Auth.auth().currentUser?.uid else { return [] }
            let invitesRef = FirestoreConstants.UserCollection.document(userId).collection("collection-invites")
            let invites = try await invitesRef.getDocuments(as: CollectionInvite.self)
            return invites
        }

       
       // Reject an invite to collaborate on a collection
       
    func acceptInvite(collectionId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let collectionRef = FirestoreConstants.CollectionsCollection.document(collectionId)
        let userRef = FirestoreConstants.UserCollection.document(userId)
        
        // Start a Firestore transaction to ensure atomic updates
        try await Firestore.firestore().runTransaction { transaction, errorPointer in
            // Update collaborators in the collection document
            transaction.updateData([
                "collaborators": FieldValue.arrayUnion([userId]),
                "pendingInvitations": FieldValue.arrayRemove([userId])
            ], forDocument: collectionRef)
            
            // Increment the user's collection stat by 1
            transaction.updateData([
                "stats.collections": FieldValue.increment(Int64(1))
            ], forDocument: userRef)
            
            
           return nil
        }
        
        // Remove invite from user's invites
        let inviteRef = FirestoreConstants.UserCollection.document(userId).collection("collection-invites").document(collectionId)
        try await inviteRef.delete()
        await MainActor.run {
            AuthService.shared.userSession?.inviteCount -= 1
            AuthService.shared.userSession?.stats.collections += 1
        }
    }
    
    func rejectInvite(collectionId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let collectionRef = FirestoreConstants.CollectionsCollection.document(collectionId)
        
        // Remove user from pendingInvitations in the collection document
        try await collectionRef.updateData([
            "pendingInvitations": FieldValue.arrayRemove([userId])
        ])
        
        // Remove invite from user's invites
        let inviteRef = FirestoreConstants.UserCollection.document(userId).collection("collection-invites").document(collectionId)
        try await inviteRef.delete()
        await MainActor.run {
            AuthService.shared.userSession?.inviteCount -= 1
        }
    }
    func removeSelfAsCollaborator(collectionId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let collectionRef = FirestoreConstants.CollectionsCollection.document(collectionId)
        let userRef = FirestoreConstants.UserCollection.document(userId)

        // Start a Firestore transaction to ensure atomic updates
        try await Firestore.firestore().runTransaction { (transaction, errorPointer) -> Any? in
            do {
                // Get the current collection data
                let collectionSnapshot = try transaction.getDocument(collectionRef)
                guard var collectionData = collectionSnapshot.data(),
                      var collaborators = collectionData["collaborators"] as? [String] else {
                    throw NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch collection data"])
                }

                // Check if the user is actually a collaborator
                guard collaborators.contains(userId) else {
                    throw NSError(domain: "CollaborationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not a collaborator of this collection"])
                }

                // Remove the user from the collaborators list
                collaborators.removeAll { $0 == userId }

                // Update the collection document
                transaction.updateData([
                    "collaborators": collaborators
                ], forDocument: collectionRef)

                // Decrement the user's collection stat by 1
                transaction.updateData([
                    "stats.collections": FieldValue.increment(Int64(-1))
                ], forDocument: userRef)

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        // Update local user object
        await MainActor.run {
            if var currentUser = AuthService.shared.userSession {
                currentUser.stats.collections -= 1
                AuthService.shared.userSession = currentUser
            }
        }

        //print("Successfully removed self as collaborator from collection: \(collectionId)")
    }
}
