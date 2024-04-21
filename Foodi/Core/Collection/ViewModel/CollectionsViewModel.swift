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
    @Published var editItems: [CollectionItem] = []
    @Published var dismissListView: Bool = false
    @Published var dismissCollectionView: Bool = false
    var post: Post?
    var restaurant: Restaurant?
    
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
    //MARK: addItemToCollection
    
    /// Adds an item to selectedCollection and on firebase. Updates the selectedCollection variable as well, which is what is actually displayed for the user to reduce networking, Also updates the collections array to reduce networking.
    /// - Parameter item: Collection Item to be inserted into selectedCollection
    func addItemToCollection(item: CollectionItem) {
        // Make sure the collection's items array is not nil
        if let selectedCollection {
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
    //MARK: addPostToCollection
    /// adds self.post as a CollectionItem to selectedCollection on Firebase
    func addPostToCollection() {
        if self.post != nil {
            if let collectionItem = convertPostToCollectionItem() {
                addItemToCollection(item: collectionItem)
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
        func addRestaurantToCollection() {
            if self.restaurant != nil {
                if let collectionItem = convertRestaurantToCollectionItem() {
                    addItemToCollection(item: collectionItem)
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
            addPostToCollection()
        }
        
        if self.restaurant != nil, let collection = collection {
            updateSelectedCollection(collection: collection)
            addRestaurantToCollection()
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
        self.editItems = collection.items ?? []
        
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
        self.editItems = []
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
            self.editItems = collection.items ?? []
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
                
                if  collection.items != self.editItems {
                    var encodedItems: [Any] = []
                    for item in self.editItems {
                        guard let encodedItem = try? Firestore.Encoder().encode(item) else {
                            print("Failed to encode item:", item)
                            return
                        }
                        encodedItems.append(encodedItem)
                    }
                    data["items"] = encodedItems
                    self.selectedCollection?.items = editItems
                    collections[index].items = self.editItems
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
        if let collectionId = self.selectedCollection?.id {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else {
            print("Collection with ID \(collectionId) not found.")
            return
        }
            let collection = collections[index]
            
            // Delete the collection from Firestore
            try await FirestoreConstants.CollectionsCollection.document(collectionId).delete()
            
            // Optionally, delete the collection's cover image from storage
            if let imageUrl = collection.coverImageUrl {
                try await ImageUploader.deleteImage(fromUrl: imageUrl)
            }
            
            // Update the collections array and selectedCollection
            collections.remove(at: index)
            if selectedCollection?.id == collectionId {
                selectedCollection = nil
                clearEdits()
            }
            print("Collection deleted successfully.")
        }
    }
    
}
