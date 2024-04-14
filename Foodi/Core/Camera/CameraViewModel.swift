//
//  CameraViewModel.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/2/24.
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
    @Published var picData: [Data] = []
    @Published var isPhotoTaken = false
    
    // VIDEO PROPERTIES
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewURL: URL?
    
    // EDIT/PREVIEW VIEW PROPERTIES
    @Published var showPreview: Bool = false
    @Published var previewType: String = "none"
    
    // TOP PROGRESS BAR
    @Published var recordedDuration: CGFloat = 0
    @Published var maxDuration: CGFloat = 20
    
    // DRAGGING TO SWITCH CAMERA MODE
    @Published var isDragging = false
    @Published var dragDirection = "left"
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
            
            // might need to alter for our needs
            let cameraDevice = AVCaptureDevice.default(for: .video)
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
        // MARK: Temporary URL for recording Video
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        videoOutput.startRecording(to: URL(fileURLWithPath: tempURL), recordingDelegate: self)
        isRecording = true
    }

    
    func stopRecording() {
        videoOutput.stopRecording()
        isRecording = false
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        // CREATED SUCCESSFULLY
        print(outputFileURL)
        self.recordedURLs.append(outputFileURL)
        if self.recordedURLs.count == 1{
            self.previewURL = outputFileURL
            return
        }
        
        // CONVERTING URLs TO ASSETS
        let assets = recordedURLs.compactMap { url -> AVURLAsset in
            return AVURLAsset(url: url)
        }
        
        self.previewURL = nil
        // MERGING VIDEOS
        mergeVideos(assets: assets) { exporter in
            exporter.exportAsynchronously {
                if exporter.status == .failed{
                    // HANDLE ERROR
                    print(exporter.error!)
                }
                else{
                    if let finalURL = exporter.outputURL{
                        print(finalURL)
                        DispatchQueue.main.async {
                            self.previewURL = finalURL
                        }
                    }
                }
            }
        }
    }
    
    
    func mergeVideos(assets: [AVURLAsset],completion: @escaping (_ exporter: AVAssetExportSession)->()){
        
        let compostion = AVMutableComposition()
        var lastTime: CMTime = .zero
        
        guard let videoTrack = compostion.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else{return}
        guard let audioTrack = compostion.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else{return}
        
        for asset in assets {
            // Linking Audio and Video
            do{
                try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: asset.tracks(withMediaType: .video)[0], at: lastTime)
                // Safe Check if Video has Audio
                if !asset.tracks(withMediaType: .audio).isEmpty{
                    try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: asset.tracks(withMediaType: .audio)[0], at: lastTime)
                }
            }
            catch{
                // HANDLE ERROR
                print(error.localizedDescription)
            }
            
            // Updating Last Time
            lastTime = CMTimeAdd(lastTime, asset.duration)
        }
        
        // MARK: Temp Output URL
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory() + "Reel-\(Date()).mp4")
        
        // VIDEO IS ROTATED
        // BRINGING BACK TO ORIGNINAL TRANSFORM
        
        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        // MARK: Transform
        var transform = CGAffineTransform.identity
        transform = transform.rotated(by: 90 * (.pi / 180))
        transform = transform.translatedBy(x: 0, y: -videoTrack.naturalSize.height)
        layerInstructions.setTransform(transform, at: .zero)
        
        let instructions = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRange(start: .zero, duration: lastTime)
        instructions.layerInstructions = [layerInstructions]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        videoComposition.instructions = [instructions]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        guard let exporter = AVAssetExportSession(asset: compostion, presetName: AVAssetExportPresetHighestQuality) else{return}
        exporter.outputFileType = .mp4
        exporter.outputURL = tempURL
        exporter.videoComposition = videoComposition
        completion(exporter)
    }
    
    
    func takePic() {
        
        if picData.count < 3 {
            DispatchQueue.global(qos:.background).async {
                
                self.photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)

                DispatchQueue.main.async {
                    withAnimation {self.isPhotoTaken = true}
                }
            }
        }
        
        
        
        if picData.count >= 3 {
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
                self.picData.removeAll()
                self.isPhotoTaken.toggle()
                // self.isPhotoSaved = false
            }

        }

    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {

        if error != nil {
            print("DEBUG: went out cause error")
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            print("DEBUG: No image data")
            return
        }

        self.picData.append(imageData)
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
