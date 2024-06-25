//
//  Download.swift
//  Foodi
//
//  Created by Jack Robinson on 5/29/24.
//

import Firebase
import AVKit
import SwiftUI
import Photos
import Foundation
import AVFoundation


@MainActor
class DownloadViewModel: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: Float = 0
    @Published var isDownloading: Bool = false
    @Published var downloadSuccess: Bool = false
    @Published var downloadFailure: Bool = false

    private var mediaType: MediaType?

    func downloadMedia(url: URL, mediaType: MediaType) {
        self.mediaType = mediaType
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                self.isDownloading = true
                let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
                let task = session.dataTask(with: url) { (data, response, error) in
                    guard error == nil else {
                        return
                    }
                    let downloadTask = session.downloadTask(with: url)
                    downloadTask.resume()
                }
                task.resume()
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let data = try? Data(contentsOf: location), let mediaType = self.mediaType else {
            return
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL: URL
        
        switch mediaType {
        case .photo:
            destinationURL = documentsURL.appendingPathComponent("downloadedPhoto.jpg")
        case .video:
            destinationURL = documentsURL.appendingPathComponent("downloadedVideo.mp4")
        case .written:
            return
        }
  
        
        do {
            try data.write(to: destinationURL)
            saveMediaToAlbum(mediaURL: destinationURL, albumName: "Ketchup", mediaType: mediaType)
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadSuccess.toggle()
            }
        } catch {
            print("Error saving file:", error)
            DispatchQueue.main.async {
                self.isDownloading = false
                self.downloadFailure.toggle()
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            self.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        }
    }
    
    private func saveMediaToAlbum(mediaURL: URL, albumName: String, mediaType: MediaType) {
        if albumExists(albumName: albumName) {
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
            let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            if let album = collection.firstObject {
                saveMedia(mediaURL: mediaURL, to: album, mediaType: mediaType)
            }
        } else {
            var albumPlaceholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { success, error in
                if success {
                    guard let albumPlaceholder = albumPlaceholder else { return }
                    let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumPlaceholder.localIdentifier], options: nil)
                    guard let album = collectionFetchResult.firstObject else { return }
                    self.saveMedia(mediaURL: mediaURL, to: album, mediaType: mediaType)
                } else {
                    print("Error creating album: \(error?.localizedDescription ?? "")")
                }
            })
        }
    }
    
    private func albumExists(albumName: String) -> Bool {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        return collection.firstObject != nil
    }
    
    private func saveMedia(mediaURL: URL, to album: PHAssetCollection, mediaType: MediaType) {
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest: PHAssetChangeRequest?
            switch mediaType {
            case .photo:
                assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: mediaURL)
            case .video:
                assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: mediaURL)
            case .written:
                return 
            }
            
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            if let assetPlaceholder = assetChangeRequest?.placeholderForCreatedAsset {
                albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
            }
        }, completionHandler: { success, error in
            if success {
                print("Successfully saved media to album")
            } else {
                print("Error saving media to album: \(error?.localizedDescription ?? "")")
            }
        })
    }
}
