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
    var configuration: YPImagePickerConfiguration
    
    func makeUIViewController(context: Context) -> YPImagePicker {
        let picker = YPImagePicker(configuration: configuration)
        picker.didFinishPicking { [unowned picker] items, cancelled in
            if cancelled {
                self.isPresented = false
            } else {
                self.selectedItems = items
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
    @Binding var selectedItems: [YPMediaItem]
    
    var body: some View {
        VStack{
            YPImagePickerSwiftUI(
                isPresented: $isPresented,
                selectedItems: $selectedItems,
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
    }
}
