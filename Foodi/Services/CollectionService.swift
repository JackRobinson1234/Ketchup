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
        //print("DEBUG: Ran fetchUserPost")
        let collections = try await FirestoreConstants
            .CollectionsCollection
            .whereField("uid", isEqualTo: user)
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
    func addItemToCollection(collectionItem: CollectionItem) async throws{
        let collectionRef = FirestoreConstants.CollectionsCollection.document(collectionItem.collectionId)
        let subCollectionRef = collectionRef.collection("items")
        guard let itemData = try? Firestore.Encoder().encode(collectionItem) else {
            print("not encoding collection right")
            return
        }
        let query = subCollectionRef.whereField("id", isEqualTo: collectionItem.id)
        let querySnapshot = try await query.getDocuments()
        if collectionItem.postType == "restaurant", querySnapshot.documents.isEmpty {
            try await collectionRef.updateData(["restaurantCount": FieldValue.increment(Int64(1))])
        } else if collectionItem.postType == "atHome", querySnapshot.documents.isEmpty {
            try await collectionRef.updateData(["atHomeCount": FieldValue.increment(Int64(1))])
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
        if collectionItem.postType == "restaurant" {
            try await collectionRef.updateData(["restaurantCount": FieldValue.increment(Int64(-1))])
        } else if collectionItem.postType == "atHome" {
            try await collectionRef.updateData(["atHomeCount": FieldValue.increment(Int64(-1))])
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
    func uploadCollection(uid: String, title: String, description: String?, username: String, uiImage: UIImage?, profileImageUrl: String?) async throws -> Collection? {
        let ref = FirestoreConstants.CollectionsCollection.document()
        do {
            var imageUrl: String? = nil
            if let uiImage = uiImage {
                do {
                    imageUrl = try await ImageUploader.uploadImage(image: uiImage, type: .profile)
                } catch {
                    print("Error uploading image: \(error)")
                    // Handle the error, such as showing an alert to the user
                    return nil
                }
            }
            let collection = Collection(id: ref.documentID, name: title, timestamp: Timestamp(), description: description, username: username, uid: uid, coverImageUrl: imageUrl, restaurantCount: 0, atHomeCount: 0, privateMode: false, profileImageUrl: profileImageUrl)
            print(collection)
            guard let collectionData = try? Firestore.Encoder().encode(collection) else {
                print("not encoding collection right")
                return nil}
            try await ref.setData(collectionData)
            return collection
        } catch {
            print("DEBUG: Failed to upload Collection with error \(error.localizedDescription)")
            throw error
        }
    }
    //MARK: deleteCollection
    /// deletes a collection from firebase and corresponding items subcollection
    /// - Parameter selectedCollection: collection to be deleted
    func deleteCollection(selectedCollection: Collection) async throws {
        try await deleteItemsSubcollection(from: selectedCollection)
        try await FirestoreConstants.CollectionsCollection.document(selectedCollection.id).delete()
        
        // Optionally, delete the collection's cover image from storage
        if let imageUrl = selectedCollection.coverImageUrl {
            try await ImageUploader.deleteImage(fromUrl: imageUrl)
        }
        
        print("Collection deleted successfully.")
    }
    //MARK: deleteItemsSubcollection
    /// Deletes all the items from a collection
    /// - Parameter collection: collection to delete the items from
    func deleteItemsSubcollection(from collection: Collection) async throws {
        let collectionRef = FirestoreConstants.CollectionsCollection.document(collection.id)
        let itemsSubcollectionRef = collectionRef.collection("items")
        
        do {
            let batch = Firestore.firestore().batch()
            
            // Get all documents in the items subcollection
            let querySnapshot = try await itemsSubcollectionRef.getDocuments()
            for document in querySnapshot.documents {
                batch.deleteDocument(document.reference)
            }
            // Commit the batch operation
            try await batch.commit()
            print("Items subcollection deleted successfully.")
        } catch {
            print("Failed to delete items subcollection with error: \(error.localizedDescription)")
            throw error
        }
    }
}
//    //MARK: deleteAllUserCollections
//    func deleteAllUserCollections(forUser user: User) async throws {
//        // Fetch all collections for the user
//        let collections = try await FirestoreConstants.CollectionsCollection
//            .whereField("uid", isEqualTo: user.id)
//            .getDocuments(as: Collection.self)
//
//        for collection in collections {
//            try await deleteCollection(selectedCollection: collection)
//            
//            
//            print("Collection '\(collection.name)' deleted successfully.")
//        }
//
//        print("All collections for user \(user.username) deleted successfully.")
//    }
//}
