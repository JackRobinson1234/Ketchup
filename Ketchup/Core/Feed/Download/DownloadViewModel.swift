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

    func downloadMedia(post: Post, currentMediaIndex: Int) {
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await MainActor.run {
                if status == .authorized {
                    self.isDownloading = true
                    
                    let mediaURL: String?
                    let mediaType: MediaType
                    
                    if post.mediaType == .mixed {
                        mediaURL = post.mixedMediaUrls?[currentMediaIndex].url
                        mediaType = post.mixedMediaUrls?[currentMediaIndex].type ?? .photo
                    } else {
                        mediaURL = post.mediaUrls[currentMediaIndex]
                        mediaType = post.mediaType
                    }
                    
                    self.mediaType = mediaType
                    
                    guard let mediaURLString = mediaURL, let url = URL(string: mediaURLString) else {
                        self.isDownloading = false
                        self.downloadFailure = true
                        return
                    }
                    
                    let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
                    let task = session.dataTask(with: url) { (data, response, error) in
                        if let error = error {
                            Task { @MainActor in
                                self.isDownloading = false
                                self.downloadFailure = true
                            }
                            return
                        }
                        let downloadTask = session.downloadTask(with: url)
                        downloadTask.resume()
                    }
                    task.resume()
                } else {
                    self.isDownloading = false
                    self.downloadFailure = true
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let data = try? Data(contentsOf: location), let mediaType = self.mediaType else {
            Task { @MainActor in
                self.isDownloading = false
                self.downloadFailure = true
            }
            return
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL: URL
        
        switch mediaType {
        case .photo:
            destinationURL = documentsURL.appendingPathComponent("downloadedPhoto.jpg")
        case .video:
            destinationURL = documentsURL.appendingPathComponent("downloadedVideo.mp4")
        case .written, .mixed:
            Task { @MainActor in
                self.isDownloading = false
                self.downloadFailure = true
            }
            return
        }
  
        do {
            try data.write(to: destinationURL)
            saveMediaToAlbum(mediaURL: destinationURL, albumName: "Ketchup", mediaType: mediaType)
            Task { @MainActor in
                self.isDownloading = false
                self.downloadSuccess = true
            }
        } catch {
            //print("Error saving file:", error)
            Task { @MainActor in
                self.isDownloading = false
                self.downloadFailure = true
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        Task { @MainActor in
            self.progress = calculatedProgress
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
                    //print("Error creating album: \(error?.localizedDescription ?? "")")
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
            case .mixed:
                //print("DEBUG")
                return
            }
            
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            if let assetPlaceholder = assetChangeRequest?.placeholderForCreatedAsset {
                albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
            }
        }, completionHandler: { success, error in
            if success {
                //print("Successfully saved media to album")
            } else {
                //print("Error saving media to album: \(error?.localizedDescription ?? "")")
            }
        })
    }
}
