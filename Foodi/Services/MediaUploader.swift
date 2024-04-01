//
//  MediaUploader.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation
import UIKit
import Firebase
import FirebaseStorage
import AVKit
import AVFoundation

enum UploadType {
    case profile
    case post
    
    var filePath: StorageReference {
        let filename = NSUUID().uuidString
        switch self {
        case .profile:
            return Storage.storage().reference(withPath: "/profile_images/\(filename)")
        case .post:
            return Storage.storage().reference(withPath: "/post_images/\(filename)")
        }
    }
}

struct ImageUploader {
    static func uploadImage(image: UIImage, type: UploadType) async throws -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return nil }
        let ref = type.filePath
        
        do {
            let _ = try await ref.putDataAsync(imageData)
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            print("DEBUG: Failed to upload image \(error.localizedDescription)")
            return nil
        }
    }
}

import UIKit
import Firebase

struct VideoUploader {
    static func uploadVideoToStorage(withUrl url: URL) async throws -> String? {
        let filename = NSUUID().uuidString
        let ref = Storage.storage().reference(withPath: "/post_videos/").child(filename)
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        let mp4Url = URL( string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")
        do {
            let data = try Data(contentsOf: mp4Url!)
            let _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            print("DEBUG: Failed to upload video with error: \(error.localizedDescription)")
            throw error
        }
    }
    static func convertVideoToMP4(from url: URL) async throws -> URL {
            let asset = AVURLAsset(url: url)
            let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
            
            guard let session = exportSession else {
                throw NSError(domain: "VideoUploaderErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
            }
            
            let mp4Filename = NSUUID().uuidString
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let mp4Url = documentsUrl.appendingPathComponent("\(mp4Filename).mp4")
            
            session.outputURL = mp4Url
            session.outputFileType = .mp4
            
            await session.export()
            
            if session.status == .completed {
                return mp4Url
            } else if let error = session.error {
                throw error
            } else {
                throw NSError(domain: "VideoUploaderErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error during video conversion"])
            }
        }
}
