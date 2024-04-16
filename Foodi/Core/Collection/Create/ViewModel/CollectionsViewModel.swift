//
//  ProfileCollectionsViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import Foundation
class CollectionsViewModel: ObservableObject {
    @Published var collections = [Collection]()
    @Published var selectedCollection: Collection?
    
    private let collectionService: CollectionService = CollectionService()
    
    func fetchCollections(user: String) async {
        do {
            self.collections = try await collectionService.fetchCollections(user: user)
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
    }
    
    func addItemToCollection(item: CollectionItem) {
        // Make sure the collection's items array is not nil
        if let selectedCollection {
            if var collectionItems = selectedCollection.items {
                // Append the new item to the items array
                collectionItems.append(item)
                
                // Update the collection's items array
                if let index = collections.firstIndex(where: { $0.id == selectedCollection.id }) {
                    collections[index].items = collectionItems
                    
                    // Optionally, you can update the Firestore collection here
                    updateCollectionInFirestore(collection: collections[index])
                }
            } else {
                // If the items array is nil, create a new array with the item
                let newItems = [item]
                if let index = collections.firstIndex(where: { $0.id == selectedCollection.id }) {
                    collections[index].items = newItems
                    
                    // Optionally, you can update the Firestore collection here
                    updateCollectionInFirestore(collection: collections[index])
                }
            }
        } else {
            print("error with selectedCollection")
        }
    }
        
        // Function to update the collection in Firestore (example implementation)
        private func updateCollectionInFirestore(collection: Collection) {
            // Update the collection in Firestore using your Firestore service or API
            // Example:
            // collectionService.updateCollection(collection)
        }
    }
