//
//  EditProfileViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import PhotosUI
import FirebaseFirestoreSwift
import Firebase

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var uploadComplete = false
    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(fromItem: selectedImage) } }
    }
    @Published var profileImage: Image?
    
    private var uiImage: UIImage?
    var fullname = ""
    var bio = ""
    var username = ""
                
    init(user: User) {
        self.user = user
        if let bio = user.bio {
            self.bio = bio
        }
        self.fullname = user.fullname
        self.username = user.username
    }
    
    @MainActor
    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.profileImage = Image(uiImage: uiImage)

    }
    
    func updateProfileImage(_ uiImage: UIImage) async throws {
        let imageUrl = try? await ImageUploader.uploadImage(image: uiImage, type: .profile)
        self.user.profileImageUrl = imageUrl
    }
    
    func updateUserData() async throws {
        var data: [String: String] = [:]

        if let uiImage = uiImage {
            try? await updateProfileImage(uiImage)
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
        
        if !bio.isEmpty, user.bio != bio {
            user.bio = bio
            data["bio"] = bio
        }
        
        try await FirestoreConstants.UserCollection.document(user.id).updateData(data)
    }
}
