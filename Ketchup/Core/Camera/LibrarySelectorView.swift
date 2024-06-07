//
//  LibrarySelectorView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/10/24.
//

import SwiftUI

import SwiftUI
import PhotosUI

struct LibrarySelectorView: View {
    
    @ObservedObject var uploadViewModel: UploadViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    @EnvironmentObject var tabBarController: TabBarController
    
    @State var showVideoPicker = false
    @State var showImagePicker = false
    
    @State var selectedPhotos: [PhotosPickerItem] = []
    @State var selectedVideo: [PhotosPickerItem] = []

    var body: some View {
        VStack(spacing: 20) {
            
            Button("Select Photos") {
                showImagePicker = true
            }
            
            Button("Select Video") {
                showVideoPicker = true
            }
        }
        .navigationDestination(isPresented: $uploadViewModel.navigateToUpload) {
            ReelsUploadView(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel)
                .toolbar(.hidden, for: .tabBar)
        }
        .onChange(of: selectedVideo) {
            Task {
                await loadVideoURL()
            }
        }
        .onChange(of: selectedPhotos) {
            Task {
                await loadPhotoImages()
            }
        }
        .onChange(of: tabBarController.selectedTab) {
            cameraViewModel.reset()
            uploadViewModel.reset()
        }
        .photosPicker(
            isPresented: $showVideoPicker,
            selection: $selectedVideo,
            maxSelectionCount: 1,
            matching: .videos
        )
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedPhotos,
            maxSelectionCount: 5,
            matching: .images
        )
    }
    
    func loadVideoURL() async {
        guard let videoItem = selectedVideo.first else { return }
        do {
            if let video: Movie = try await videoItem.loadTransferable(type: Movie.self) {
                DispatchQueue.main.async {
                    uploadViewModel.videoURL = video.url
                    uploadViewModel.mediaType = "video"
                    uploadViewModel.fromInAppCamera = false
                    uploadViewModel.navigateToUpload = true
                }
            } else {
                print("No URL available for the video item")
            }
        } catch {
            print("Error loading video URL: \(error)")
        }
    }
    
    func loadPhotoImages() async {
        var images: [UIImage] = []
        for photoItem in selectedPhotos {
            do {
                if let imageData: Data = try await photoItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: imageData) {
                    images.append(image)
                }
            } catch {
                print("Error loading image: \(error)")
            }
        }
        DispatchQueue.main.async {
            uploadViewModel.images = images
            uploadViewModel.mediaType = "photo"
            uploadViewModel.fromInAppCamera = false
            uploadViewModel.navigateToUpload = true
        }
    }
}
