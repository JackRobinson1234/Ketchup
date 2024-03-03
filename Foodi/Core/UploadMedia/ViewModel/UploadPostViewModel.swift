//
//  UploadPostViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Firebase
import PhotosUI

@MainActor
class RestaurantUploadPostViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var mediaPreview: Movie?
    @Published var caption = ""
    @Published var selectedMediaForUpload: Movie?
    @Published var selectedItem: PhotosPickerItem? {
        didSet { Task { await loadVideo(fromItem: selectedItem) } }
    }
    private let restaurant: Restaurant?
    private let service: UploadPostService
    
    
    init(service: UploadPostService, restaurant: Restaurant?) {
        self.service = service
        self.restaurant = restaurant
    }
    
    func uploadPost() async {
        guard !caption.isEmpty else { return }
        guard let videoUrlString = mediaPreview?.url.absoluteString else { return }
        isLoading = true
        if let restaurant {
            do {
                print("running upload post")
                try await service.uploadPost(caption: caption, videoUrlString: videoUrlString, restaurant: restaurant)
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func setMediaItemForUpload() {
        selectedMediaForUpload = mediaPreview
    }
    
    
    func reset() {
        caption = ""
        mediaPreview = nil
        error = nil
        selectedItem = nil
        selectedMediaForUpload = nil
    }
    
    func loadVideo(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        isLoading = true
        
        do {
            guard let movie = try await item.loadTransferable(type: Movie.self) else { return }
            self.mediaPreview = movie
            isLoading = false
        } catch {
            print("DEBUG: Failed with error \(error.localizedDescription)")
        }
    }
}
