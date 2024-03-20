//
//  MediahHelpers.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import Foundation
import SwiftUI
import AVKit

struct MediaHelpers {
    static func generateThumbnail(path: String) -> UIImage? {        
        guard let url = URL(string: path) else {
            print("DEBUG: Invalid URL")
            return nil
        }
        
        // Determine the file type
        let fileExtension = url.pathExtension.lowercased()
        if ["png", "jpg", "jpeg"].contains(fileExtension) {
            // Handle image file
            return UIImage(contentsOfFile: url.path)
        } else if ["mov", "mp4"].contains(fileExtension) {
            // Handle video file
            do {
                let asset = AVURLAsset(url: url, options: nil)
                let imgGenerator = AVAssetImageGenerator(asset: asset)
                imgGenerator.appliesPreferredTrackTransform = true
                let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
                return UIImage(cgImage: cgImage)
            } catch {
                print("DEBUG: Error generating video thumbnail: \(error.localizedDescription)")
                return nil
            }
        } else {
            // Unsupported file type
            print("DEBUG: Unsupported file type")
            return nil
        }
    }
}
