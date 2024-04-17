//
//  ProfileCollectionsViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import Foundation
import SwiftUI
import PhotosUI
@MainActor
class CollectionsViewModel: ObservableObject {
    @Published var collections = [Collection]()
    @Published var selectedCollection: Collection?
    
    private let collectionService: CollectionService = CollectionService()
    @Published var user: User
    @Published var uploadComplete = false
    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(fromItem: selectedImage) } }
    }
    @Published var coverImage: Image?
    @Published var isLoading: Bool = false
    @Published var updateItems = false
    private var uiImage: UIImage?
    var title = ""
    var description = ""
                
    init(user: User) {
        self.user = user
    }
    func fetchCollections(user: String) async {
        do {
            self.collections = try await collectionService.fetchCollections(user: user)
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
    }
    
    func addItemToCollection(item: CollectionItem) {
        // Make sure the collection's items array is not nil
        if var selectedCollection {
            if var collectionItems = selectedCollection.items {
                // Append the new item to the items array
                collectionItems.append(item)
                self.selectedCollection?.items = collectionItems
                
                // Update the collection's items array
                if let index = collections.firstIndex(where: { $0.id == selectedCollection.id }) {
                    collections[index].items = collectionItems

                    
                    // Optionally, you can update the Firestore collection here
                    collectionService.addItemToCollection(item: item, collectionId: selectedCollection.id)
                    print("view model count", selectedCollection.items!.count)
                    updateItems.toggle()
                    print(updateItems)
                    
                }
            } else {
                // If the items array is nil, create a new array with the item
                let newItems = [item]
                if let index = collections.firstIndex(where: { $0.id == selectedCollection.id }) {
                    collections[index].items = newItems
                    self.selectedCollection?.items = newItems
                    
                    // Optionally, you can update the Firestore collection here
                    collectionService.addItemToCollection(item: item, collectionId: selectedCollection.id)
                    print("view model count", selectedCollection.items!.count)
                    updateItems.toggle()
                    print(updateItems)
                }
            }
        } else {
            print("error with selectedCollection")
        }
    }
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.coverImage = Image(uiImage: uiImage)

    }
    
    func uploadCollection() async throws {
        isLoading = true
        let descriptionToSend: String? = description.isEmpty ? nil : description
        try await collectionService.uploadCollection(uid: user.id, title: title, description: descriptionToSend, username: user.username, uiImage: uiImage)
        await fetchCollections(user: user.id)
        isLoading = false
    }
}
