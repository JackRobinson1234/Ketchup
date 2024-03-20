//
//  CameraViewModel.swift
//  Foodi
//
//  Created by Joe Ciminelli on 3/10/24.
//

import SwiftUI

class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    let cameraService = CameraService()
    
    
    func saveImageToFileSystem(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 1) else { return nil }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = UUID().uuidString + ".jpeg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving file: \(error.localizedDescription)")
            return nil
        }
    }
}
