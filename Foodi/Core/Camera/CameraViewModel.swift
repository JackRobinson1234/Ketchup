//
//  CameraViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//

import SwiftUI
import AVFoundation

@MainActor
class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
        
    // SESSION
    @Published var session = AVCaptureSession()
    
    // ERROR CATCHING
    @Published var alert = false
    
    // PHOTO AND VID OUTPUT
    @Published var photoOutput = AVCapturePhotoOutput()
    @Published var videoOutput = AVCaptureMovieFileOutput()
    
    // this the preview
    @Published var preview: AVCaptureVideoPreviewLayer!
    
    // PHOTO PROPERTIES
    // @Published var isPhotoSaved = false
    @Published var images: [UIImage] = []
    @Published var isPhotoTaken = false
    
    // VIDEO PROPERTIES
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewURL: URL?
    
    // EDIT/PREVIEW VIEW PROPERTIES
    @Published var navigateToUpload: Bool = false
    @Published var mediaType: String = "none"
    
    // NAVIGATES TO LIBRARY SELECTION
    @Published var uploadFromLibray = false
    
    // TOP PROGRESS BAR
    @Published var recordedDuration: CGFloat = 0
    @Published var maxDuration: CGFloat = 20
    
    // DRAGGING TO SWITCH CAMERA MODE
    @Published var isDragging = false
    @Published var dragDirection = "left"
    
    //LOADING STUFF
    @Published var isLoading = false
    
    // USER CAMERA SETTINGS
    @Published var cameraPosition: CameraPosition = .back
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var showFlashOverlay = false
    @Published var originalBrightness: CGFloat? = nil
    @Published var zoomFactor: CGFloat = 1.0

    @Published var isDragEnabled: Bool = true
    var drag: some Gesture {
        DragGesture(minimumDistance: 85)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    self.isDragging = false
                } else {
                    self.dragDirection = "right"
                    self.isDragging = false
                }
            }
    }
    
    
    func checkPermission() {
        
        // check perms
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            setUp()
            return
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status {
                    self.setUp()
                }
            }
            
        case .denied:
            self.alert.toggle()
            return
            
        default:
            return
            
        }
        
    }
    
    func setUp() {
        
        do {
            self.session.beginConfiguration()
            session.inputs.forEach { session.removeInput($0) }
            
            let cameraDevice: AVCaptureDevice?
            
            switch cameraPosition {
                case .front:
                    cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                case .back:
                    cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                }

            let videoInput = try AVCaptureDeviceInput(device: cameraDevice!)
            
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            // check for input
            if self.session.canAddInput(videoInput) && self.session.canAddInput(audioInput) {
                self.session.addInput(videoInput)
                self.session.addInput(audioInput)
            }
            
            //check for output
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }
            
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            
            self.session.commitConfiguration()
            
        }
        catch {
            print(error.localizedDescription)
        }
        
    }
    
    func startRecording() {
        isRecording = true
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        configureFlash()  // Only configure flash if using the back camera
        videoOutput.startRecording(to: URL(fileURLWithPath: tempURL), recordingDelegate: self)

    }

    func stopRecording() {
        isRecording = false
        configureFlash()  // Turn off the torch if it was on and we're using the back camera
        isLoading = true
        videoOutput.stopRecording()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        // CREATED SUCCESSFULLY
        recordedURLs.append(outputFileURL)
        if recordedURLs.count == 1 {
            // Create AVURLAsset from URL
            let singleAsset = AVURLAsset(url: outputFileURL)

            // Process single video with the asset
            processSingleVideo(asset: singleAsset) { exporter in
                exporter.exportAsynchronously {
                    if exporter.status == .completed, let processedURL = exporter.outputURL {
                        DispatchQueue.main.async {
                            self.previewURL = processedURL
                            self.isLoading = false
                        }
                    } else {
                        self.isLoading = false
                        print("Failed to process video: \(String(describing: exporter.error))")
                    }
                }
            }
            return
        }
        
        // CONVERTING URLs TO ASSETS
        let assets = recordedURLs.map { AVURLAsset(url: $0) }
        
        // MERGING VIDEOS
        mergeVideos(assets: assets) { exporter in
            exporter.exportAsynchronously {
                if exporter.status == .failed {
                    // HANDLE ERROR
                    print(exporter.error!)
                } else {
                    if let finalURL = exporter.outputURL {
                        print(finalURL)
                        DispatchQueue.main.async {
                            self.previewURL = finalURL
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    func processSingleVideo(asset: AVURLAsset, completion: @escaping (_ exporter: AVAssetExportSession) -> ()) {
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
            print("Failed to add tracks to the composition")
            return
        }

        // Add video track from asset
        do {
            let videoAssetTrack = asset.tracks(withMediaType: .video)[0]
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try videoTrack.insertTimeRange(timeRange, of: videoAssetTrack, at: .zero)

            // Check and add audio track if available
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first {
                try audioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
            }
        } catch {
            print("Error inserting time ranges: \(error)")
            return
        }

        // Applying only vertical flip transformation
        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: videoTrack.naturalSize.height, y: 0) // Adjust for rotation
        transform = transform.rotated(by: 90 * (.pi / 180)) // 90 degrees rotation
        if cameraPosition == .front {
            transform = transform.scaledBy(x: 1, y: -1) // Horizontal flip
            transform = transform.translatedBy(x: 0, y: -videoTrack.naturalSize.height) // Adjust post-mirroring
        }
        layerInstructions.setTransform(transform, at: .zero)

        let instructions = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        instructions.layerInstructions = [layerInstructions]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width) // Adjust for the rotated aspect
        videoComposition.instructions = [instructions]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "Processed-\(Date()).mp4")
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            print("Failed to create export session")
            return
        }

        exporter.outputFileType = .mp4
        exporter.outputURL = tempURL
        exporter.videoComposition = videoComposition

        completion(exporter)
    }
    
    func mergeVideos(assets: [AVURLAsset], completion: @escaping (_ exporter: AVAssetExportSession)->()){
        let composition = AVMutableComposition()
        var lastTime: CMTime = .zero
        
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
            print("Failed to add tracks to the composition")
            return
        }
        
        for asset in assets {
            do {
                let videoAssetTrack = asset.tracks(withMediaType: .video)[0]
                let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
                
                try videoTrack.insertTimeRange(timeRange, of: videoAssetTrack, at: lastTime)
                
                if let audioAssetTrack = asset.tracks(withMediaType: .audio).first {
                    try audioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: lastTime)
                }
            } catch {
                print("Error during composition: \(error)")
            }
            lastTime = CMTimeAdd(lastTime, asset.duration)
        }
        
        // Setting up the video composition with the correct transform
        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: videoTrack.naturalSize.height, y: 0) // Adjust for rotation
        transform = transform.rotated(by: 90 * (.pi / 180)) // 90 degrees rotation
        if cameraPosition == .front {
            transform = transform.scaledBy(x: 1, y: -1) // Horizontal flip
            transform = transform.translatedBy(x: 0, y: -videoTrack.naturalSize.height) // Adjust post-mirroring
        }
        layerInstructions.setTransform(transform, at: .zero)
        
        let instructions = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRange(start: .zero, duration: lastTime)
        instructions.layerInstructions = [layerInstructions]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width) // Adjust for the rotated aspect
        videoComposition.instructions = [instructions]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "Reel-\(Date()).mp4")
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            print("Failed to create export session")
            return
        }
        
        exporter.outputFileType = .mp4
        exporter.outputURL = tempURL
        exporter.videoComposition = videoComposition
        
        completion(exporter)
    }
    
    
    func takePic() {
        if images.count < 5 {
            DispatchQueue.global(qos:.background).async {
                let photoSettings = AVCapturePhotoSettings()
                if self.photoOutput.supportedFlashModes.contains(self.flashMode) {
                    photoSettings.flashMode = self.flashMode
                }
                
                if self.flashMode == .off {
                    DispatchQueue.main.async {
                        self.showFlashOverlay = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.showFlashOverlay = false
                        }
                    }
                }
                self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
            }
        } else {
            // Additional logic if needed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.session.stopRunning()
                self.isPhotoTaken = false
            }
        }
    }
    

    func untakePic() {

        DispatchQueue.global(qos: .background).async {

            self.session.startRunning()

            DispatchQueue.main.async {
                self.images.removeAll()
                self.isPhotoTaken.toggle()
                // self.isPhotoSaved = false
            }

        }

    }
    

    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
            print("Failed to convert photo to UIImage.")
            return
        }
        
        // Adjusting the image based on the camera used
        var adjustedImage = image
        if cameraPosition == .front {
            // Ensure the image is mirrored horizontally
            if let cgImage = image.cgImage {
                let mirroredImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .leftMirrored)
                adjustedImage = fixOrientation(of: mirroredImage)
            }
        }

        DispatchQueue.main.async {
            self.images.append(adjustedImage)
            self.isPhotoTaken = true
        }
    }

    func fixOrientation(of image: UIImage) -> UIImage {
        // Check if the image orientation is already correct
        if image.imageOrientation == .up {
            return image
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalizedImage
    }
    
    func toggleCamera() {
        guard isRecording else {
            // If not currently recording, just switch the camera
            switchCameraInput()
            return
        }

        // Stop recording with the current camera
        stopRecording()
        switchCameraInput()
        startRecording()
    }

    func switchCameraInput() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        setUp() // Reconfigure the session with the new camera
        configureFlash()
    }
    func reset() {
        // Reset the photo and video capture properties
        images.removeAll()
        recordedURLs.removeAll()
        previewURL = nil
        isPhotoTaken = false
        isRecording = false
        navigateToUpload = false
        mediaType = "none"
        recordedDuration = 0
        isDragging = false
        uploadFromLibray = false
        isDragEnabled = true
        
    }
    
    
    func configureFlash() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            try device.lockForConfiguration()

            // Only manage the torch if using the back camera
            if cameraPosition == .back {
                if isRecording && flashMode == .on {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                // Restore original brightness when using back camera
                if let originalBrightness = originalBrightness {
                    UIScreen.main.brightness = originalBrightness
                    self.originalBrightness = nil // Reset the stored original brightness
                }
                showFlashOverlay = false
            } else {
                // Manage front camera settings
                device.torchMode = .off  // Ensure torch is off for the front camera
                if isRecording && flashMode == .on {
                    if originalBrightness == nil { // Store the current brightness if not already stored
                        originalBrightness = UIScreen.main.brightness
                    }
                    UIScreen.main.brightness = CGFloat(1.0)  // Maximize brightness
                    showFlashOverlay = true
                } else {
                    if let originalBrightness = originalBrightness {
                        UIScreen.main.brightness = originalBrightness // Restore original brightness
                        self.originalBrightness = nil // Reset the stored original brightness
                    }
                    showFlashOverlay = false
                }
            }

            device.unlockForConfiguration()
        } catch {
            print("Flash could not be configured: \(error)")
        }
    }
    
    func getDragStatus() -> Bool {
        if isRecording || isLoading || isPhotoTaken || previewURL != nil || !recordedURLs.isEmpty {
            return false
        } else {
            return true
        }
    }
        
}

enum CameraPosition {
    case front
    case back
}
extension CameraPosition {
    func toAVCaptureDevicePosition() -> AVCaptureDevice.Position {
        switch self {
        case .front:
            return .front
        case .back:
            return .back
        }
    }
}

//    func savePic() {
//
//        // prob shouldnt force unwrap
//        let image = UIImage(data: self.picData)!
//
//        // saving image
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
//
//        self.isSaved = true
//    }
//
//}
