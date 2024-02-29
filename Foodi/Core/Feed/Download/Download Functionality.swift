//
//  Download Functionality.swift
//  Foodi
//
//  Created by Jack Robinson on 3/1/24.
//
import Firebase
import AVKit
import SwiftUI
import Photos
class ViewController: UIViewController {
    func downloadVideo(url: URL) {
        let task = URLSession.shared.downloadTask(with: url) { (tempLocalURL, response, error) in
            if let tempLocalURL = tempLocalURL, error == nil {
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationURL = documentsDirectory.appendingPathComponent("downloadedVideo.mp4")
                
                do {
                    try FileManager.default.moveItem(at: tempLocalURL, to: destinationURL)
                    print("Video downloaded to: \(destinationURL)")
                    
                    // Save the video to the photo library
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: destinationURL)
                    }) { (success, error) in
                        if success {
                            print("Video saved to photo library.")
                        } else {
                            print("Error saving video to photo library: \(error?.localizedDescription ?? "")")
                        }
                    }
                    
                } catch {
                    print("Error moving file: \(error.localizedDescription)")
                }
            } else {
                print("Error downloading video: \(error?.localizedDescription ?? "")")
            }
        }
        
        task.resume()
    }
}
