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
    @Published var editTitle = ""
    @Published var editDescription = ""
    @Published var editImageUrl = ""
    @Published var items: [CollectionItem] = []
    @Published var deleteItems: [CollectionItem] = []
    @Published var dismissListView: Bool = false
    @Published var dismissCollectionView: Bool = false
    @Published var post: Post?
    @Published var restaurant: Restaurant?
    
    init(user: User, post: Post? = nil, restaurant: Restaurant? = nil) {
        self.user = user
        self.post = post
        self.restaurant = restaurant
    }
    //MARK: fetchCollections
    
    /// fetches all collections for a user
    /// - Parameter user: user to fetch collections for
    func fetchCollections(user: String) async {
        isLoading = true
        print("fetching Collections")
        do {
            self.collections = try await collectionService.fetchCollections(user: user)
            isLoading = false
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
            isLoading = false
        }
    }
    func fetchItems() async throws{
        if let selectedCollection{
            let fetchedItems = try await collectionService.fetchItems(collection: selectedCollection)
            self.items = fetchedItems
        }
    }
    //MARK: addItemToCollection
    /// Adds an item to selectedCollection and on firebase. Updates the selectedCollection variable as well, which is what is actually displayed for the user to reduce networking, Also updates the collections array to reduce networking.
    /// - Parameter item: Collection Item to be inserted into selectedCollection
    func addItemToCollection(collectionItem: CollectionItem) async throws {
        var item = collectionItem
        if let selectedCollection = self.selectedCollection {
            item.collectionId = selectedCollection.id
            try await collectionService.addItemToCollection(collectionItem: item)
            if !self.items.contains(item){
                self.items.append(item)
                if let index = collections.firstIndex(where: { $0.id == selectedCollection.id }) {
                    if collectionItem.postType == "restaurant"{
                        collections[index].restaurantCount += 1
                    } else if collectionItem.postType == "atHome"{
                        collections[index].atHomeCount += 1
                    }
                }
            }
        }
    }
    //MARK: addPostToCollection
    /// adds self.post as a CollectionItem to selectedCollection on Firebase
    func addPostToCollection() async throws{
        if self.post != nil {
            if let collectionItem = convertPostToCollectionItem() {
                try await addItemToCollection(collectionItem: collectionItem)
            } else {
                print("Error converting post to collection Item")
            }
        }
    }
    
    /// Converts a Post object into a CollectionItem
    /// - Returns: A CollectionItem
    func convertPostToCollectionItem() -> CollectionItem? {
        if let post = self.post {
            if post.postType == "atHome" {
                let collectionItem = CollectionItem(
                    collectionId: "",
                    id: post.id,
                    postType: post.postType,
                    name: post.caption,
                    image: post.thumbnailUrl,
                    postUserFullname: post.user.fullName
                )
                return collectionItem
            } else if post.postType == "restaurant",
                      let id = post.restaurant?.id,
                      let name = post.restaurant?.name{
                let collectionItem = CollectionItem(
                    collectionId: "",
                    id: id,
                    postType: post.postType,
                    name: name,
                    image: post.restaurant?.profileImageUrl,
                    city: post.restaurant?.city,
                    state: post.restaurant?.state,
                    geoPoint: post.restaurant?.geoPoint
                )
                return collectionItem
            }
        }
        return nil
    }
    //MARK: addRestaurantToCollection
    
    /// adds self.restaurant to selectedCollection on Firebase
    func addRestaurantToCollection() async throws {
        if self.restaurant != nil {
            if let collectionItem = convertRestaurantToCollectionItem() {
                try await addItemToCollection(collectionItem: collectionItem)
            } else {
                print("Error converting restaurant to collection Item")
            }
        } else {
            print("No restaurant found")
        }
    }
    //MARK: convertRestaurantToCollectionItem
    
    /// converts a Restaurant Object to a CollectionItem object
    /// - Returns: CollectionItemObject
    func convertRestaurantToCollectionItem() -> CollectionItem? {
        if let restaurant = self.restaurant {
            let collectionItem = CollectionItem(
                collectionId: "",
                id: restaurant.id,
                postType: "restaurant",
                name: restaurant.name,
                image: restaurant.profileImageUrl,
                city: restaurant.city,
                state: restaurant.state,
                geoPoint: restaurant.geoPoint
            )
            return collectionItem
        }
        return nil
    }
    //MARK: loadImage
    
    /// Loads an image selected from the photopicker, puts it into self.uiImage. Self.coverImage is only shown when there is a new image, if the user doesnt interact with the cover photo, no cover image will be present. selectedImage is the actual photo that the user selects from photopicker, which we reset to nil after its selected, so there is no memory on the system of what photo is selected.
    /// - Parameter item: <#item description#>
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.coverImage = Image(uiImage: uiImage)
        self.selectedImage = nil
    }
    //MARK: uploadCollection
    
    /// uploads selectedCollection to Firebase. Makes the description nil if there isnt any.  Otherwise takes from the self variables assigned throughout the edit/ upload process
    func uploadCollection() async throws {
        isLoading = true
        let descriptionToSend: String? = editDescription.isEmpty ? nil : editDescription
        let collection = try await collectionService.uploadCollection(uid: user.id, title: editTitle, description: descriptionToSend, username: user.username, uiImage: uiImage)
        if let collection{
            print(collection)
            self.collections.insert(collection, at: 0)
        }
        // Adds post if there is one selected
        if self.post != nil, let collection = collection{
            updateSelectedCollection(collection: collection)
            try await addPostToCollection()
        }
        
        if self.restaurant != nil, let collection = collection {
            updateSelectedCollection(collection: collection)
            try await addRestaurantToCollection()
        }
        isLoading = false
    }
    //MARK: updateSelectedCollection
    /// updates the selectedCollection when the user selects a collection to view
    /// - Parameter collection: Collection that is selected
    func updateSelectedCollection(collection: Collection){
        self.selectedCollection = collection
        self.editTitle = collection.name
        self.editDescription = collection.description ?? ""
        self.editImageUrl = collection.coverImageUrl ?? ""
        self.deleteItems = []
        
    }
    //MARK: resetViewModel
    /// clears every variable
    func resetViewModel() {
        self.selectedCollection = nil
        self.editTitle = ""
        self.editDescription = ""
        self.editImageUrl = ""
        self.coverImage = nil
        self.uiImage = nil
        self.deleteItems = []
        self.items = []
        self.restaurant = nil
        self.post = nil
    }
    //MARK: clearEdits
    /// resets the variables to the original selectedCollection that hasn't been updated
    func clearEdits() {
        if let collection = self.selectedCollection {
            self.selectedCollection = collection
            self.editTitle = collection.name
            self.editDescription = collection.description ?? ""
            self.editImageUrl = collection.coverImageUrl ?? ""
            self.coverImage = nil
            self.uiImage = nil
            self.deleteItems = []
        }
    }
    //MARK: saveEditedCollection
    /// if there are any differencs from the original selectedCollection variables, this function puts them into the data array then  updates the firebase selectedCollection with the new variables.Then clears the edits after completing
    func saveEditedCollection() async throws {
        var changed = false
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
                    changed = true
                }
                
                if self.editDescription != collection.description {
                    self.selectedCollection?.description = self.editDescription
                    data["description"] = self.editDescription
                    collections[index].description = self.editDescription
                    changed = true
                }
                
                if self.editTitle != collection.name {
                    self.selectedCollection?.name = self.editTitle
                    data["name"] = self.editTitle
                    collections[index].name = self.editTitle
                    changed = true
                }
                
                if  !self.deleteItems.isEmpty {
                    for item in self.deleteItems {
                        try await collectionService.removeItemFromCollection(collectionItem: item)
                        if item.postType == "restaurant"{
                            collections[index].restaurantCount -= 1
                        } else if item.postType == "atHome"{
                            collections[index].atHomeCount -= 1
                        }
                    }
                    self.items = self.items.filter { !self.deleteItems.contains($0) }
                    updateItems = true
                }
                
                if changed{
                    try await FirestoreConstants.CollectionsCollection.document(collection.id).updateData(data)
                    print("ran collections update")
                }
                print("no updates")
                clearEdits()
            }
        }
    }
    //MARK: deleteCollection
    /// deletes a collection from firebase and from the collections array.
    func deleteCollection() async throws {
        if let collection = self.selectedCollection {
            guard let index = collections.firstIndex(where: { $0.id == collection.id }) else {
                print("Collection with ID \(collection) not found.")
                return
            }
            let collection = collections[index]
            try await collectionService.deleteCollection(selectedCollection: collection)
            
            // Update the collections array and selectedCollection
            collections.remove(at: index)
            if selectedCollection?.id == collection.id {
                selectedCollection = nil
                clearEdits()
            }
        }
    }
}

