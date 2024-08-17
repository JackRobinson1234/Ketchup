//
//  LibrarySelectorView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/10/24.
//

import SwiftUI
import PhotosUI

//struct LibrarySelectorView: View {
//    @ObservedObject var uploadViewModel: UploadViewModel
//    @ObservedObject var cameraViewModel: CameraViewModel
//    @EnvironmentObject var tabBarController: TabBarController
//    
//    @State private var showVideoPicker = false
//    @State private var showImagePicker = false
//    @State private var selectedPhotos: [PhotosPickerItem] = []
//    @State private var selectedVideo: [PhotosPickerItem] = []
//    @State private var isLoading = false
//    @State private var hasSelectedMedia = false
//    
//    @Environment(\.presentationMode) var presentationMode
//    
//    var body: some View {
//        ZStack {
//            Color(.systemBackground).edgesIgnoringSafeArea(.all)
//            
//            VStack(spacing: 40) {
//                HStack {
//                    Button(action: {
//                        uploadViewModel.reset()
//                        clearSelectedMedia()
//                        cameraViewModel.reset()
//                        presentationMode.wrappedValue.dismiss()
//                    }) {
//                        Image(systemName: "chevron.left")
//                            .font(.title2)
//                            .foregroundColor(Color("Colors/AccentColor"))
//                    }
//                    .padding(.leading)
//                    
//                    Spacer()
//                }
//                
//                Text("Media Selection")
//                    .font(.title)
//                    .fontWeight(.semibold)
//                    .foregroundColor(Color("Colors/AccentColor"))
//                
//                VStack(spacing: 20) {
//                    SelectionButton(title: "Select Photos", icon: "photo.on.rectangle.angled") {
//                        showImagePicker = true
//                    }
//                    
//                    SelectionButton(title: "Select Video", icon: "video") {
//                        showVideoPicker = true
//                    }
//                }
//                
//                if hasSelectedMedia {
//                    Text(selectedMediaText)
//                        .font(.headline)
//                        .foregroundColor(Color("Colors/AccentColor"))
//                        .padding(.top)
//                    
//                    Button(action: {
//                        uploadViewModel.navigateToUpload = true
//                    }) {
//                        Text("Continue with Selected Media")
//                            .fontWeight(.medium)
//                            .foregroundColor(.white)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color("Colors/AccentColor"))
//                            .cornerRadius(12)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//                
//                Spacer()
//            }
//            .padding()
//            
//            if isLoading {
//                LoadingView()
//            }
//        }
//        .navigationBarHidden(true)
//                .navigationDestination(isPresented: $uploadViewModel.navigateToUpload) {
//                    ReelsUploadView(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel)
//                        .toolbar(.hidden, for: .tabBar)
//                }
//                .onChange(of: selectedVideo) { newValue in
//                    if !newValue.isEmpty {
//                        selectedPhotos.removeAll() // Clear selected photos
//                        uploadViewModel.images = []
//                        isLoading = true
//                        Task {
//                            await loadVideoURL()
//                            isLoading = false
//                            hasSelectedMedia = true
//                        }
//                    } else {
//                        hasSelectedMedia = !selectedPhotos.isEmpty
//                    }
//                }
//                .onChange(of: selectedPhotos) { newValue in
//                    if !newValue.isEmpty {
//                        selectedVideo.removeAll() // Clear selected video
//                        uploadViewModel.videoURL = nil
//                        isLoading = true
//                        Task {
//                            await loadPhotoImages()
//                            isLoading = false
//                            hasSelectedMedia = true
//                        }
//                    } else {
//                        hasSelectedMedia = !selectedVideo.isEmpty
//                    }
//                }
//                .onChange(of: tabBarController.selectedTab) {
//                    cameraViewModel.reset()
//                    uploadViewModel.reset()
//                    hasSelectedMedia = false
//                }
//                .photosPicker(isPresented: $showVideoPicker, selection: $selectedVideo, maxSelectionCount: 1, matching: .videos)
//                .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotos, maxSelectionCount: 5, matching: .images)
//            }
//    
//    private var selectedMediaText: String {
//        if !selectedVideo.isEmpty {
//            return "1 Video Selected"
//        } else if !selectedPhotos.isEmpty {
//            let count = selectedPhotos.count
//            return "\(count) Photo\(count > 1 ? "s" : "") Selected"
//        }
//        return ""
//    }
//    private func clearSelectedMedia() {
//            selectedPhotos.removeAll()
//            selectedVideo.removeAll()
//            uploadViewModel.reset()
//            isLoading = false
//            hasSelectedMedia = false
//        }
//    func loadVideoURL() async {
//        guard let videoItem = selectedVideo.first else { return }
//        do {
//            if let video: Movie = try await videoItem.loadTransferable(type: Movie.self) {
//                DispatchQueue.main.async {
//                    uploadViewModel.videoURL = video.url
//                    uploadViewModel.mediaType = .video
//                    uploadViewModel.fromInAppCamera = false
//                    uploadViewModel.navigateToUpload = true
//                }
//            } else {
//                print("No URL available for the video item")
//            }
//        } catch {
//            print("Error loading video URL: \(error)")
//        }
//    }
//    
//    func loadPhotoImages() async {
//        var images: [UIImage] = []
//        for photoItem in selectedPhotos {
//            do {
//                if let imageData: Data = try await photoItem.loadTransferable(type: Data.self),
//                   let image = UIImage(data: imageData) {
//                    images.append(image)
//                }
//            } catch {
//                print("Error loading image: \(error)")
//            }
//        }
//        DispatchQueue.main.async {
//            uploadViewModel.images = images
//            uploadViewModel.mediaType = .photo
//            uploadViewModel.fromInAppCamera = false
//            uploadViewModel.navigateToUpload = true
//        }
//    }
//}
//struct LoadingView: View {
//    var body: some View {
//        ZStack {
//            Color(.systemBackground)
//                .opacity(0.8)
//                .ignoresSafeArea()
//            
//            VStack {
//                FastCrossfadeFoodImageView()
//                    .scaleEffect(1.5)
//                    .padding()
//                
//                Text("Processing media...")
//                    .font(.headline)
//                    .foregroundColor(Color("Colors/AccentColor"))
//            }
//            .padding(40)
//            .background(
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(Color(.secondarySystemBackground))
//                    .shadow(radius: 10)
//            )
//        }
//    }
//}
//
//struct SelectionButton: View {
//    let title: String
//    let icon: String
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            HStack {
//                Image(systemName: icon)
//                    .font(.title2)
//                    .foregroundColor(.black)
//                Text(title)
//                    .fontWeight(.medium)
//                    .foregroundColor(.black)
//                Spacer()
//            }
//            .frame(maxWidth: .infinity)
//            .padding()
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(Color("Colors/AccentColor"), lineWidth: 1)
//            )
//            .buttonStyle(PlainButtonStyle())
//        }
//        
//    }
//}
