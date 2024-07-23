//
//  ProfileCollectionsViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//
import Kingfisher
import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore
@MainActor
class CollectionsViewModel: ObservableObject {
    @Published var collections = [Collection]()
    @Published var selectedCollection: Collection? {
        didSet {
            if let collection = selectedCollection {
                editTitle = collection.name
                editDescription = collection.description ?? ""
                editImageUrl = collection.coverImageUrl ?? ""
            }
        }
    }
    @Published var uploadComplete = false
    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(fromItem: selectedImage) } }
    }
    @Published var coverImage: Image?
    @Published var isLoading: Bool = false
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
    @Published var notes: String = ""
    @Published var notesPreview: CollectionItem?
    @Published var editItems: [CollectionItem] = []
    @Published var restaurantRequest: RestaurantRequest?
    private var lastDocument: QueryDocumentSnapshot?
    private let limit = 10
    private var hasMoreCollections = true
    private var currentTask: Task<Void, Never>?
    init(post: Post? = nil, restaurant: Restaurant? = nil, selectedCollection: Collection? = nil) {
        self.post = post
        self.restaurant = restaurant
        self.selectedCollection = selectedCollection
        self.selectedCollection = selectedCollection
    }
    //MARK: fetchCollections
    
    /// fetches all collections for a user
    /// - Parameter user: user to fetch collections for
    ///  @Published var collections: [Collection] = []
    
    func loadInitialCollections() {
        guard collections.isEmpty else { return }
        loadMore()
    }
    
    func loadMore() {
        guard !isLoading, hasMoreCollections else { return }
        
        currentTask?.cancel()
        currentTask = Task { @MainActor in
            do {
                isLoading = true
                print("Starting to fetch collections")
                
                let (newCollections, lastDoc) = try await CollectionService.shared.fetchPaginatedCollections(
                    lastDocument: lastDocument,
                    limit: limit
                )
                
                collections.append(contentsOf: newCollections)
                lastDocument = lastDoc
                hasMoreCollections = newCollections.count == limit
                print("Fetched \(newCollections.count) collections. Total: \(collections.count)")
            } catch {
                print("Error loading collections: \(error)")
            }
            isLoading = false
        }
    }
    func fetchCollections(user: String) async {
        isLoading = true
        print("fetching Collections")
        do {
            self.collections = try await CollectionService.shared.fetchCollections(user: user)
            isLoading = false
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
            isLoading = false
        }
    }
    func fetchItems() async throws{
        if let selectedCollection{
            let fetchedItems = try await CollectionService.shared.fetchItems(collection: selectedCollection)
            self.items = fetchedItems
        }
    }
    //MARK: addItemToCollection
    /// Adds an item to selectedCollection and on firebase. Updates the selectedCollection variable as well, which is what is actually displayed for the user to reduce networking, Also updates the collections array to reduce networking.
    /// - Parameter item: Collection Item to be inserted into selectedCollection
    func addItemToCollection(collectionItem: CollectionItem) async throws {
        guard var selectedCollection = self.selectedCollection else { return }
        
        var item = collectionItem
        item.collectionId = selectedCollection.id
        item.notes = notes
        self.notes = ""
        
        try await CollectionService.shared.addItemToCollection(collectionItem: item)
        
        if !self.items.contains(item) {
            self.items.append(item)
            selectedCollection.restaurantCount += 1
            selectedCollection.updatetempImageUrls(with: item)
            
            // Update the collections array
            if let index = collections.firstIndex(where: { $0.id == selectedCollection.id }) {
                collections[index] = selectedCollection
            }
            
            // Update the published selectedCollection
            self.selectedCollection = selectedCollection
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
            if let user = AuthService.shared.userSession{
                let collectionItem = CollectionItem(
                    collectionId: "",
                    id: post.restaurant.id,
                    name: post.restaurant.name,
                    image: post.restaurant.profileImageUrl,
                    city: post.restaurant.city,
                    state: post.restaurant.state,
                    geoPoint: post.restaurant.geoPoint,
                    privateMode: user.privateMode
                )
                return collectionItem
                
            }
        }
        return nil
    }
    
    func convertRequestToCollectionItem(name: String, city: String, state: String) -> CollectionItem {
        let user = AuthService.shared.userSession!
        let collectionItem = CollectionItem(
            collectionId: "",
            id: "construction" + NSUUID().uuidString,
            name: name,
            image: nil,
            city: city,
            state: state,
            geoPoint: nil,
            privateMode: user.privateMode
        )
        return collectionItem
        
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
    //MARK: crateCollageImage
    
    
    /// converts a Restaurant Object to a CollectionItem object
    /// - Returns: CollectionItemObject
    func convertRestaurantToCollectionItem() -> CollectionItem? {
        if let restaurant = self.restaurant {
            if let user = AuthService.shared.userSession{
                var collectionItem = CollectionItem(
                    collectionId: "",
                    id: restaurant.id,
                    name: restaurant.name,
                    image: restaurant.profileImageUrl,
                    city: restaurant.city,
                    state: restaurant.state,
                    geoPoint: restaurant.geoPoint,
                    privateMode: user.privateMode
                )
                if let geopoint = restaurant.geoPoint{
                    collectionItem.geoPoint = geopoint
                } else if let geoLoc = restaurant._geoloc {
                    collectionItem.geoPoint = GeoPoint(latitude: geoLoc.lat, longitude: geoLoc.lng)
                }
                return collectionItem
            }
        }
        return nil
    }
    func convertRestaurantToCollectionItem(restaurant: Restaurant) -> CollectionItem {
        let user = AuthService.shared.userSession!
        var collectionItem = CollectionItem(
            collectionId: "",
            id: restaurant.id,
            name: restaurant.name,
            image: restaurant.profileImageUrl,
            city: restaurant.city,
            state: restaurant.state,
            geoPoint: restaurant.geoPoint,
            privateMode: user.privateMode
        )
        if let geopoint = restaurant.geoPoint{
            collectionItem.geoPoint = geopoint
        } else if let geoLoc = restaurant._geoloc {
            collectionItem.geoPoint = GeoPoint(latitude: geoLoc.lat, longitude: geoLoc.lng)
        }
        return collectionItem
        
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
        if let user = AuthService.shared.userSession{
            isLoading = true
            let descriptionToSend: String? = editDescription.isEmpty ? nil : editDescription
            let collection = try await CollectionService.shared.uploadCollection(uid: user.id, title: editTitle, description: descriptionToSend, username: user.username, uiImage: uiImage, profileImageUrl: user.profileImageUrl, fullname: user.fullname)
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
            resetViewModel()
            isLoading = false
        }
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
        self.notes = ""
        self.editItems = []
        self.restaurantRequest = nil

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
            self.notes = ""
            self.editItems = []
            self.restaurantRequest = nil
        }
    }
    //MARK: saveEditedCollection
    /// if there are any differencs from the original selectedCollection variables, this function puts them into the data array then  updates the firebase selectedCollection with the new variables.Then clears the edits after completing
    func saveEditedCollection() async throws {
        guard var selectedCollection = self.selectedCollection else { return }
        var changed = false
        var data: [String: Any] = [:]
        
        if coverImage != nil, let uiImage = self.uiImage {
            let imageUrl = try await ImageUploader.uploadImage(image: uiImage, type: .collection)
            data["coverImageUrl"] = imageUrl
            selectedCollection.coverImageUrl = imageUrl
            changed = true
        }
        
        if self.editDescription != selectedCollection.description {
            selectedCollection.description = self.editDescription
            data["description"] = self.editDescription
            changed = true
        }
        
        if self.editTitle != selectedCollection.name {
            selectedCollection.name = self.editTitle
            data["name"] = self.editTitle
            changed = true
        }
        
        if !self.deleteItems.isEmpty {
            for item in self.deleteItems {
                try await CollectionService.shared.removeItemFromCollection(collectionItem: item)
                selectedCollection.restaurantCount -= 1
                selectedCollection.removeCoverImageUrl(for: item)
            }
            self.items = self.items.filter { !self.deleteItems.contains($0) }
            changed = true
        }
        
        if !self.editItems.isEmpty {
            for item in self.editItems {
                try await CollectionService.shared.addItemToCollection(collectionItem: item)
                selectedCollection.updatetempImageUrls(with: item)
            }
            let editItemsDict = Dictionary(uniqueKeysWithValues: self.editItems.map { ($0.id, $0) })
            self.items = self.items.map { editItemsDict[$0.id] ?? $0 }
            changed = true
        }
        
        if changed {
            if let tempImageUrls = selectedCollection.tempImageUrls {
                data["tempImageUrls"] = tempImageUrls
            }
            try await FirestoreConstants.CollectionsCollection.document(selectedCollection.id).updateData(data)
            
            // Update the collections array
            if let index = collections.firstIndex(where: { $0.id == selectedCollection.id }) {
                collections[index] = selectedCollection
            }
            
            // Update the published selectedCollection
            self.selectedCollection = selectedCollection
        }
        
        clearEdits()
    }
    //MARK: deleteCollection
    /// deletes a collection from firebase and from the collections array.
    func deleteCollection() async throws {
        guard let collection = self.selectedCollection else { return }
        
        dismissCollectionView = true
        AuthService.shared.userSession?.stats.collections -= 1
        
        try await CollectionService.shared.deleteCollection(selectedCollection: collection)
        
        // Update the collections array
        collections.removeAll { $0.id == collection.id }
        
        // Clear the selectedCollection
        selectedCollection = nil
        resetViewModel()
    }
}

