//
//  ProfileCollectionsViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore
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
    var editTitle = ""
    var editDescription = ""
    var editImageUrl = ""
    var editItems: [CollectionItem] = []
                
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
        self.selectedImage = nil
    }
    
    func uploadCollection() async throws {
        isLoading = true
        let descriptionToSend: String? = editDescription.isEmpty ? nil : editDescription
        try await collectionService.uploadCollection(uid: user.id, title: editTitle, description: descriptionToSend, username: user.username, uiImage: uiImage)
        await fetchCollections(user: user.id)
        isLoading = false
    }
    
    func updateSelectedCollection(collection: Collection){
        self.selectedCollection = collection
        self.editTitle = collection.name
        self.editDescription = collection.description ?? ""
        self.editImageUrl = collection.coverImageUrl ?? ""
        
    }
    
    func resetViewModel() {
        self.selectedCollection = nil
        self.editTitle = ""
        self.editDescription = ""
        self.editImageUrl = ""
        self.coverImage = nil
        self.uiImage = nil
    }
    
    func clearEdits() {
        if let collection = self.selectedCollection {
            self.selectedCollection = collection
            self.editTitle = collection.name
            self.editDescription = collection.description ?? ""
            self.editImageUrl = collection.coverImageUrl ?? ""
            self.coverImage = nil
            self.uiImage = nil
        }
    }
    
    func saveEditedCollection() async throws {
        if let collection = self.selectedCollection {
            if let index = collections.firstIndex(where: { $0.id == collection.id }) {
                var data: [String: Any] = [:]
                //handles updating the image
                if coverImage != nil, let uiImage = self.uiImage {
                    let imageUrl = try await ImageUploader.uploadImage(image: uiImage, type: .profile)
                    data["coverImageUrl"] = imageUrl
                    //updates selectedCollection with the new image
                    if let image = collection.coverImageUrl {
                        try await ImageUploader.deleteImage(fromUrl: image)
                    }
                    self.selectedCollection?.coverImageUrl = imageUrl
                    // updates the collections array with the updated image
                    collections[index].coverImageUrl = imageUrl
                }
                
                if self.editDescription != collection.description {
                    self.selectedCollection?.description = self.editDescription
                    data["description"] = self.editDescription
                    collections[index].description = self.editDescription
                }
                
                if self.editTitle != collection.name {
                    self.selectedCollection?.name = self.editTitle
                    data["name"] = self.editTitle
                    collections[index].name = self.editTitle
                }
                
                if  collection.items != self.editItems {
                    guard let cleanedData = try? Firestore.Encoder().encode(self.editItems) else {
                        print("not encoding editItems right")
                        return }
                    data["items"] = cleanedData
                    self.selectedCollection?.items = editItems
                    collections[index].items = self.editItems
                    
                }
                try await FirestoreConstants.CollectionsCollection.document(collection.id).updateData(data)
                clearEdits()
            }
        }
    }
}

