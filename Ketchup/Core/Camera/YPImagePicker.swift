//
//  YPImagePicker.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/23/24.
//

import SwiftUI
import YPImagePicker
import AVFoundation
import Photos


struct YPImagePickerSwiftUI: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @ObservedObject var uploadViewModel: UploadViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    var configuration: YPImagePickerConfiguration
    func makeUIViewController(context: Context) -> YPImagePicker {
           let picker = YPImagePicker(configuration: configuration)

           picker.didFinishPicking { [unowned picker] items, cancelled in
               uploadViewModel.mixedMediaItems = []
               if cancelled {
                   self.isPresented = false
                   picker.dismiss(animated: true, completion: nil)
               } else {
                   // Check if the first item is a video and assign its thumbnail
                   if let firstItem = items.first {
                       switch firstItem {
                       case .video(let video):
                           uploadViewModel.thumbnailImage = video.thumbnail
                       default:
                           // Do nothing for non-video items
                           break
                       }
                   }
                   // Process all items as before
                   for item in items {
                       uploadViewModel.addMixedMediaItem(item)
                   }
                   uploadViewModel.navigateToUpload = true
                   self.isPresented = false
               }
           }
           return picker
       }
    
    func updateUIViewController(_ uiViewController: YPImagePicker, context: Context) {}
}

struct ImagePicker: View {
    @Binding var isPresented: Bool
    @ObservedObject var uploadViewModel: UploadViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    
    var body: some View {
        VStack {
            if isPresented {
                YPImagePickerSwiftUI(
                    isPresented: $isPresented,
                    uploadViewModel: uploadViewModel,
                    cameraViewModel: cameraViewModel,
                    configuration: {
                        var config = YPImagePickerConfiguration()
                        config.library.mediaType = .photoAndVideo
                        config.library.maxNumberOfItems = 8
                        config.library.minNumberOfItems = 1
                        config.library.skipSelectionsGallery = true
                        config.library.defaultMultipleSelection = false
                        config.gallery.hidesRemoveButton = false
                        config.screens = [.library]
                        config.onlySquareImagesFromCamera = false
                        config.hidesBottomBar = true
                        config.shouldSaveNewPicturesToAlbum = false
                        config.showsPhotoFilters = false
                        config.showsVideoTrimmer = false
                        config.library.isSquareByDefault = false
                        config.colors.tintColor = .red
                        config.video.trimmerMaxDuration = 60.0
                        config.showsVideoTrimmer = true
                        config.video.trimmerMinDuration = 3.0
                        config.video.libraryTimeLimit = 60.0
                        config.video.minimumTimeLimit = 3.0
                        config.gallery.hidesRemoveButton = true
                        return config
                    }()
                )
            }
        }
        .onAppear {
            dismissKeyboard()
            
            let attributes = [NSAttributedString.Key.font: UIFont(name: "MuseoSansRounded-300", size: 16)]
            UINavigationBar.appearance().titleTextAttributes = attributes as [NSAttributedString.Key: Any] // Title fonts
            UIBarButtonItem.appearance().setTitleTextAttributes(attributes as [NSAttributedString.Key: Any], for: .normal)
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black] // Title color
            UINavigationBar.appearance().tintColor = .black // Left bar buttons
        }
        .edgesIgnoringSafeArea(.bottom)
        .fullScreenCover(isPresented: $uploadViewModel.navigateToUpload) {
            ReelsUploadView(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel)
                .onDisappear { isPresented = true }
        }
        .fullScreenCover(isPresented: $uploadViewModel.navigateToMediaCategorySelection) {
                    NavigationView {
                        MediaCategorySelectionView(uploadViewModel: uploadViewModel)
                    }
                    .onDisappear {
                        if uploadViewModel.navigateToUpload {
                            isPresented = false
                        } else if !uploadViewModel.navigateToMediaCategorySelection {
                            // Re-present the image picker
                            isPresented = true
                        }
                    }
                }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
