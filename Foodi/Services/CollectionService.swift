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
    private var collections = [Collection]()
    func fetchCollections(user: String) async throws -> [Collection] {
        //print("DEBUG: Ran fetchUserPost")
        self.collections = try await FirestoreConstants
            .CollectionsCollection
            .whereField("uid", isEqualTo: user)
            .order(by: "timestamp", descending: true)
            .getDocuments(as: Collection.self)
        return collections
    }
    
    func addItemToCollection(item: CollectionItem, collectionId: String) {
        let collectionRef = FirestoreConstants.CollectionsCollection.document(collectionId)
        
        guard let itemData = try? Firestore.Encoder().encode(item) else {
            print("not encoding collection right")
            return }
        collectionRef.updateData([
            "items": FieldValue.arrayUnion([itemData])
        ]) { error in
            if let error = error {
                print("Error appending item to Firestore collection: \(error.localizedDescription)")
            } else {
                print("Item appended successfully to Firestore collection")
            }
        }
    }
    func uploadCollection(uid: String, title: String, description: String?, username: String, uiImage: UIImage?) async throws {
        let ref = FirestoreConstants.CollectionsCollection.document()
        do {
            var imageUrl: String? = nil
            if let uiImage = uiImage {
                do {
                    imageUrl = try await ImageUploader.uploadImage(image: uiImage, type: .profile)
                } catch {
                    print("Error uploading image: \(error)")
                    // Handle the error, such as showing an alert to the user
                    return
                }
            }
            let collection = Collection(id: ref.documentID, name: title, timestamp: Timestamp(), description: description, username: username, uid: uid, coverImageUrl: imageUrl)
            print(collection)
            guard let collectionData = try? Firestore.Encoder().encode(collection) else {
                print("not encoding collection right")
                return }
            try await ref.setData(collectionData)
        } catch {
            print("DEBUG: Failed to upload Collection with error \(error.localizedDescription)")
            throw error
        }
    }
}
