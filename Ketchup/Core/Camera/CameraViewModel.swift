//
//  CameraViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//

import SwiftUI
import AVFoundation


class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    @Published var selectedCamTab: Int = 0
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var photoOutput = AVCapturePhotoOutput()
    @Published var videoOutput = AVCaptureMovieFileOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var images: [UIImage] = []
    @Published var isPhotoTaken = false
    @Published var isRecording: Bool = false
    @Published var previewURL: URL?
    @Published var navigateToUpload: Bool = false
    @Published var mediaType: MediaType = .photo
    @Published var uploadFromLibray = false
    @Published var recordedDuration: CGFloat = 0
    @Published var maxDuration: CGFloat = 20
    @Published var isDragging = false
    @Published var dragDirection = "left"
    @Published var isLoading = false
    @Published var audioOrVideoPermissionsDenied = false
    @Published var cameraPosition: CameraPosition = .back
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var showFlashOverlay = false
    @Published var originalBrightness: CGFloat? = nil
    @Published var zoomFactor: CGFloat = 1.0 {
        didSet {
            let clampedZoomFactor = max(1.0, min(zoomFactor, 3.0))
            if zoomFactor != clampedZoomFactor {
                zoomFactor = clampedZoomFactor
            } else {
                setZoomFactor(zoomFactor)
            }
        }
    }
    @Published var isZooming: Bool = false
    private var initialZoomFactor: CGFloat = 1.0
    @Published var recordedURLs: [URL] = []
    @Published var recordedCameraPositions: [CameraPosition] = []
    @Published var isPreviewActive = true

    func togglePreview(_ active: Bool) {
        DispatchQueue.main.async {
            self.isPreviewActive = active
        }
    }
    
    func setZoomFactor(_ factor: CGFloat) {
        guard cameraPosition == .back, let device = AVCaptureDevice.default(for: .video) else {
            return
        }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = factor
            device.unlockForConfiguration()
        } catch {
            print("Failed to set zoom factor: \(error)")
        }
    }
    
    func handlePinchGesture(scale: CGFloat) {
        guard cameraPosition == .back else { return }
        let sensitivity: CGFloat = 1
        let newZoomFactor = initialZoomFactor * (1 + (scale - 1) * sensitivity)
        zoomFactor = newZoomFactor
        isZooming = true
    }

    func startPinchGesture() {
        initialZoomFactor = zoomFactor
        isZooming = false
    }
    
    func checkPermission() {
        let videoPermission = AVCaptureDevice.authorizationStatus(for: .video)
        let audioPermission = AVCaptureDevice.authorizationStatus(for: .audio)
        
        if videoPermission == .authorized && audioPermission == .authorized {
            DispatchQueue.main.async {
                self.setUp()
            }
            return
        }
        
        if videoPermission == .denied || audioPermission == .denied {
            DispatchQueue.main.async {
                self.audioOrVideoPermissionsDenied = true
            }
            return
        }
        
        if videoPermission == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.checkPermission()
                    } else {
                        self.audioOrVideoPermissionsDenied = true
                    }
                }
            }
            return
        }
        
        if audioPermission == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.checkPermission()
                    } else {
                        self.audioOrVideoPermissionsDenied = true
                    }
                }
            }
            return
        }
    }
    
    func restartCameraSession() {
        DispatchQueue.main.async {
            self.startCameraSession()
            self.togglePreview(true)
        }
    }
    func setUp() {
        sessionQueue.async {
            do {
                self.session.beginConfiguration()
                self.session.inputs.forEach { self.session.removeInput($0) }
                self.session.outputs.forEach { self.session.removeOutput($0) }
                
                let cameraDevice: AVCaptureDevice?
                
                switch self.cameraPosition {
                    case .front:
                        cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                    case .back:
                        cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                }
                
                let videoInput = try AVCaptureDeviceInput(device: cameraDevice!)
                let audioDevice = AVCaptureDevice.default(for: .audio)
                let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
                
                if self.session.canAddInput(videoInput) && self.session.canAddInput(audioInput) {
                    self.session.addInput(videoInput)
                    self.session.addInput(audioInput)
                }
                
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                }
                
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }
                
                self.session.commitConfiguration()
                self.startCameraSession()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    // Add this property to your CameraViewModel
    private let sessionQueue = DispatchQueue(label: "com.yourapp.sessionQueue")

    // Modify startCameraSession and stopCameraSession
    func startCameraSession() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopCameraSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    func startRecording() {
        isRecording = true
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        configureFlash()
        videoOutput.startRecording(to: URL(fileURLWithPath: tempURL), recordingDelegate: self)
        recordedCameraPositions.append(cameraPosition)
    }

    func stopRecording() {
        isRecording = false
        configureFlash()
        isLoading = true
        videoOutput.stopRecording()
    }
    
    func startRecordingForNewCam() {
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        videoOutput.startRecording(to: URL(fileURLWithPath: tempURL), recordingDelegate: self)
        recordedCameraPositions.append(cameraPosition)
    }

    func stopRecordingForNewCam() {
        videoOutput.stopRecording()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
            return
        }
        
        recordedURLs.append(outputFileURL)

        let assets = recordedURLs.map { AVURLAsset(url: $0) }
        
        if !isRecording {
            Task {
                do {
                    guard let exporter = try await mergeVideos(assets: assets) else {
                        print("Failed to create exporter")
                        return
                    }
                    
                    await exporter.export()
                    
                    switch exporter.status {
                    case .completed:
                        if let finalURL = exporter.outputURL {
                            await MainActor.run {
                                self.previewURL = finalURL
                                self.isLoading = false
                            }
                        }
                    case .failed:
                        if let error = exporter.error {
                            print("Export failed: \(error.localizedDescription)")
                        }
                    case .cancelled:
                        print("Export cancelled")
                    default:
                        print("Export ended with status: \(exporter.status.rawValue)")
                    }
                } catch {
                    print("Error merging videos: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func mergeVideos(assets: [AVURLAsset]) async throws -> AVAssetExportSession? {
        let composition = AVMutableComposition()
        var lastTime: CMTime = .zero
        
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
            print("Failed to add tracks to the composition")
            return nil
        }
        
        var instructions: [AVMutableVideoCompositionInstruction] = []
        
        let urlsCopy = recordedURLs
        for index in urlsCopy.indices {
            let recordedUrl = recordedURLs[index]
            let asset = AVURLAsset(url: recordedUrl)
            let duration = try await asset.load(.duration)
            let timeRange = CMTimeRange(start: .zero, duration: duration)
            
            do {
                let videoAssetTrack = try await asset.loadTracks(withMediaType: .video)[0]
                try videoTrack.insertTimeRange(timeRange, of: videoAssetTrack, at: lastTime)
                
                if let audioAssetTrack = try await asset.loadTracks(withMediaType: .audio).first {
                    try audioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: lastTime)
                }
            } catch {
                print("Error during composition: \(error)")
                continue
            }
            
            let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: videoTrack.naturalSize.height, y: 0).rotated(by: 90 * (.pi / 180))
            
            if recordedCameraPositions[index] == .front {
                transform = transform.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: -videoTrack.naturalSize.height)
            }
            
            layerInstructions.setTransform(transform, at: lastTime)
            
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: lastTime, duration: duration)
            instruction.layerInstructions = [layerInstructions]
            instructions.append(instruction)
            
            lastTime = CMTimeAdd(lastTime, duration)
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        videoComposition.instructions = instructions
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "Reel-\(Date()).mp4")
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            print("Failed to create export session")
            return nil
        }
        
        exporter.outputFileType = .mp4
        exporter.outputURL = tempURL
        exporter.videoComposition = videoComposition
        return exporter
    }
    
    func takePic() {
        if images.count < 8 {
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
            self.isLoading = true
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.session.stopRunning()
                self.isPhotoTaken = false
            }
        }
    }
    
    func clearPics() {
        self.images.removeAll()
        self.isPhotoTaken.toggle()
    }
    
    func clearLatestPic() {
        _ = self.images.popLast()
        
        if self.images.isEmpty {
            self.isPhotoTaken.toggle()
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
        
        var adjustedImage = image
        if cameraPosition == .front {
            if let cgImage = image.cgImage {
                let mirroredImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .leftMirrored)
                adjustedImage = fixOrientation(of: mirroredImage)
            }
        }

        DispatchQueue.main.async {
            self.isLoading = false
            self.images.append(adjustedImage)
            self.isPhotoTaken = true
        }
    }


    func fixOrientation(of image: UIImage) -> UIImage {
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
            switchCameraInput()
            return
        }

        stopRecordingForNewCam()
        switchCameraInput()
        startRecordingForNewCam()
    }

    func switchCameraInput() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        zoomFactor = 1.0
        setUp()
        configureFlash()
    }
    
   
    func reset() {
        DispatchQueue.main.async {
            self.images.removeAll()
            self.recordedURLs.removeAll()
            self.recordedCameraPositions.removeAll()
            self.previewURL = nil
            self.isPhotoTaken = false
            self.isRecording = false
            self.navigateToUpload = false
            self.mediaType = .photo
            self.recordedDuration = 0
            self.isDragging = false
            self.uploadFromLibray = false
            //self.selectedCamTab = 0
        }
    }
    
    
    func configureFlash() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            try device.lockForConfiguration()

            if cameraPosition == .back {
                if isRecording && flashMode == .on {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                if let originalBrightness = originalBrightness {
                    UIScreen.main.brightness = originalBrightness
                    self.originalBrightness = nil
                }
                showFlashOverlay = false
            } else {
                device.torchMode = .off
                if isRecording && flashMode == .on {
                    if originalBrightness == nil {
                        originalBrightness = UIScreen.main.brightness
                    }
                    UIScreen.main.brightness = CGFloat(1.0)
                    showFlashOverlay = true
                } else {
                    if let originalBrightness = originalBrightness {
                        UIScreen.main.brightness = originalBrightness
                        self.originalBrightness = nil
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
