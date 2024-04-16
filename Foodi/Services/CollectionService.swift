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
class CollectionService {
    private var collections = [Collection]()
    func fetchCollections(user: String) async throws -> [Collection] {
        //print("DEBUG: Ran fetchUserPost")
        self.collections = try await FirestoreConstants
            .CollectionsCollection
            .whereField("uid", isEqualTo: user)
            .getDocuments(as: Collection.self)
        return collections
    }
    
    private func updateCollectionInFirestore(item: CollectionItem, collectionId: String) {
        let db = Firestore.firestore()
        let collectionRef = FirestoreConstants
            .CollectionsCollection.document(collectionId)
        
        // Use FieldValue.arrayUnion to append the new item to the existing items array in Firestore
        collectionRef.updateData([
            "items": FieldValue.arrayUnion([item])
        ]) { error in
            if let error = error {
                print("Error appending item to Firestore collection: \(error.localizedDescription)")
            } else {
                print("Item appended successfully to Firestore collection")
            }
        }
    }
}
