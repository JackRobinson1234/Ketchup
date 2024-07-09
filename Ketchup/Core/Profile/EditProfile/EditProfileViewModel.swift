//
//  EditProfileViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import PhotosUI
@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var uploadComplete = false
    @Published var selectedImage: PhotosPickerItem? {
         didSet {
            if let item = selectedImage {
                Task {
                    await loadImage(fromItem: item)
                    // Reset selectedItem to nil after loading
                    DispatchQueue.main.async {
                        self.selectedImage = nil
                    }
                }
            }
        }
    }
    @Published var profileImage: Image?
    @Published var favoritesPreview: [FavoriteRestaurant] {
        didSet {
            print("Favorites Preview Changed: \(favoritesPreview)")
        }
    }
    @Published var validUsername: Bool? = true
    @Published var fullname = ""
    @Published var username = ""
    @Published var showingImageCropper = false
    @Published var croppedImage: UIImage?
    
    @Published var uiImage: UIImage?
                
    init(user: User) {
        self.user = user
        self.fullname = user.fullname
        self.username = user.username
        self.favoritesPreview = user.favorites
    }
    
    @MainActor
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.showingImageCropper = true
    }
    
    func setCroppedImage(_ image: UIImage) {
        self.croppedImage = image
        self.profileImage = Image(uiImage: image)
        self.uiImage = image
    }
    
    func updateProfileImage(_ uiImage: UIImage) async throws {
        let imageUrl = try? await ImageUploader.uploadImage(image: uiImage, type: .profile)
        self.user.profileImageUrl = imageUrl
    }
    @MainActor
    func updateUserData() async throws {
        var data: [String: Any] = [:]

        if let croppedImage = croppedImage {
            try? await updateProfileImage(croppedImage)
            data["profileImageUrl"] = user.profileImageUrl
        }
        
        if !fullname.isEmpty, user.fullname != fullname {
            user.fullname = fullname
            data["fullname"] = fullname
        }
        
        if !username.isEmpty, user.username != username {
            user.username = username
            data["username"] = username
        }
        
        if !favoritesPreview.isEmpty, user.favorites != favoritesPreview {
            user.favorites = favoritesPreview
            let cleanedData = favoritesPreview.map { ["name": $0.name, "id": $0.id, "restaurantProfileImageUrl": $0.restaurantProfileImageUrl ?? ""] }
            data["favorites"] = cleanedData
        }
        
        try await FirestoreConstants.UserCollection.document(user.id).updateData(data)
        AuthService.shared.userSession = self.user
    }
    
    func checkIfUsernameAvailable() async throws {
        if user.username == self.username {
            validUsername = true
            return
        }
        let query = FirestoreConstants.UserCollection.whereField("username", isEqualTo: self.username)
        let querySnapshot = try await query.getDocuments()
        if querySnapshot.documents.isEmpty {
           validUsername = true
        } else {
            validUsername = false
        }
    }
}
