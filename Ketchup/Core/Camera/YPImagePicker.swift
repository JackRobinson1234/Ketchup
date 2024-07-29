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
                print("Picker was canceled")
                self.isPresented = false
            } else {
                for item in items {
                    uploadViewModel.addMixedMediaItem(item)
                }
                uploadViewModel.navigateToUpload = true
                self.isPresented = false
            }
            picker.dismiss(animated: true, completion: nil)
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
            YPImagePickerSwiftUI(
                isPresented: $isPresented,
                uploadViewModel: uploadViewModel,
                cameraViewModel: cameraViewModel,
                configuration: {
                    var config = YPImagePickerConfiguration()
                    config.library.mediaType = .photoAndVideo
                    config.library.maxNumberOfItems = 5
                    config.library.minNumberOfItems = 1
                    config.library.skipSelectionsGallery = true
                    config.library.defaultMultipleSelection = true
                    config.gallery.hidesRemoveButton = false
                    config.screens = [.library]
                    config.onlySquareImagesFromCamera = false
                    config.hidesBottomBar = true
                    config.shouldSaveNewPicturesToAlbum = false
                    config.showsPhotoFilters = false
                    config.showsVideoTrimmer = false
                    config.library.isSquareByDefault = false
                    return config
                }()
            )
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationDestination(isPresented: $uploadViewModel.navigateToUpload) {
            
            ReelsUploadView(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel)
            //.toolbar(.hidden, for: .tabBar)
            
        }
    }
}

