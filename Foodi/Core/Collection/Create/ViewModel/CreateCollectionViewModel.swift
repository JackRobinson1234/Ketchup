//
//  CreateCollectionViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/16/24.
//

import Foundation
import PhotosUI
import Firebase
import SwiftUI

@MainActor
class CreateCollectionViewModel: ObservableObject {
    @Published var user: User
    @Published var uploadComplete = false
    @Published var selectedImage: PhotosPickerItem? {
        didSet { Task { await loadImage(fromItem: selectedImage) } }
    }
    @Published var coverImage: Image?
    @Published var isLoading: Bool = false
    var collectionService = CollectionService()
    
    
    private var uiImage: UIImage?
    var title = ""
    var description = ""
                
    init(user: User) {
        self.user = user
    }
    
    @MainActor
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
        isLoading = false
    }
}
