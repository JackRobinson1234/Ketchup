//
//  CameraViewModel.swift
//  Foodi
//
//  Created by Joe Ciminelli on 3/10/24.
//

import SwiftUI
import PhotosUI


@MainActor
class CameraViewModel: ObservableObject {
    
    @Published var capturedPhoto: UIImage?
    @Published var alertItem: AlertItem?
    @Published var isImageCaptured = false
    @Published var selectedItem: PhotosPickerItem? {
        didSet {
            Task {
                loadImageFromPhotosPicker(from: selectedItem!)
            }
        }
    }
    
    
    
    let cameraService = CameraService()
    
    
    
    
    
    
    
    
    
    
    
    func loadImageFromPhotosPicker(from item: PhotosPickerItem) {
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    self.capturedPhoto = UIImage(data: data)
                }
            } catch {
                print("Error loading image: \(error)")
            }
        }
    }
//    func saveImageToFileSystem(_ image: UIImage) -> URL? {
//        guard let data = image.jpegData(compressionQuality: 1) else { return nil }
//        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let fileName = UUID().uuidString + ".jpeg"
//        let fileURL = documentsDirectory.appendingPathComponent(fileName)
//        
//        do {
//            try data.write(to: fileURL)
//            return fileURL
//        } catch {
//            print("Error saving file: \(error.localizedDescription)")
//            return nil
//        }
//    }
}
