//
//  Photo.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//

//import UIKit
//import PhotosUI
//import SwiftUI
//
//struct Photo: Transferable {
//    let url: URL
//    
//    static var transferRepresentation: some TransferRepresentation {
//        FileRepresentation(contentType: .image) { photo in
//            SentTransferredFile(photo.url)
//        } importing: { received in
//            // Define the destination path for the photo
//            let fileName = UUID().uuidString + ".jpeg"
//            let copy = URL.documentsDirectory.appendingPathComponent(fileName)
//            
//            if FileManager.default.fileExists(atPath: copy.path) {
//                try FileManager.default.removeItem(at: copy)
//            }
//            
//            // Assuming received.file is a URL pointing to the image file, copy it to the app's document directory
//            try FileManager.default.copyItem(at: received.file, to: copy)
//            
//            return Self.init(url: copy)
//        }
//    }
//}
//
//extension URL {
//    // Helper to get the documents directory URL
//    static var documentsDirectory: URL {
//        // Use the user domain mask to get the documents directory
//        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        return paths[0]
//    }
//}
//
//extension Photo: Hashable {}
