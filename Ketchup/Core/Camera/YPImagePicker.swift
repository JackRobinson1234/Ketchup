//
//  YPImagePicker.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/23/24.
//

import SwiftUI
import YPImagePicker
import AVFoundation


struct YPImagePickerSwiftUI: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedItems: [YPMediaItem]
    @ObservedObject var uploadViewModel: UploadViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    var configuration: YPImagePickerConfiguration
    
    func makeUIViewController(context: Context) -> YPImagePicker {
        let picker = YPImagePicker(configuration: configuration)
//        picker.didFinishPicking { [unowned picker] items, cancelled in
//            if cancelled {
//                self.isPresented = false
//            } else {
//                self.selectedItems = items
//                self.isPresented = false
//            }
//            picker.dismiss(animated: true, completion: nil)
//        }
        picker.didFinishPicking { [unowned picker] items, cancelled in
            for item in items {
                switch item {
                case .photo(let photo):
                    print(photo)
                case .video(let video):
                    print(video)
                }
                
            }
            uploadViewModel.navigateToUpload = true
            //picker.dismiss(animated: true, completion: nil)
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: YPImagePicker, context: Context) {}
}

struct ImagePicker: View {
    @Binding var isPresented: Bool
    @Binding var selectedItems: [YPMediaItem]
    @ObservedObject var uploadViewModel: UploadViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    var body: some View {
        VStack{
            YPImagePickerSwiftUI(
                isPresented: $isPresented,
                selectedItems: $selectedItems,
                
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
                .toolbar(.hidden, for: .tabBar)
        }
    }
}
