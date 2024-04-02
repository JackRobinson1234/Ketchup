//
//  CameraView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 3/10/24.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    
    @ObservedObject var viewModel: CameraViewModel
    
    typealias UIViewControllerType = UIViewController
    
    //let didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()
    
    func makeUIViewController(context: Context) -> UIViewController {
        
        viewModel.cameraService.start(delegate: context.coordinator) { err in
            if let err = err {
                //TODO want to pass error into context or something like that here
                print(err)
                viewModel.alertItem = AlertContext.deviceInput
                return
            }
        }
        
        let viewController = UIViewController()
        viewController.view.backgroundColor = .black
        viewController.view.layer.addSublayer(viewModel.cameraService.previewLayer)
        viewModel.cameraService.previewLayer.frame = viewController.view.bounds
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(cameraView: self)
    }
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        let cameraView: CameraView
        
        init(cameraView: CameraView) {
            self.cameraView = cameraView
        }
        
        @MainActor func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
            if let error = error {
                //didFinishProcessingPhoto(.failure(error))
                // TODO use the error here
                print(error)
                cameraView.viewModel.alertItem = AlertContext.deviceInput
                return
            }
            if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
                cameraView.viewModel.capturedPhoto = image
                cameraView.viewModel.isImageCaptured = true
            } else {
                print("Error: No image data found")
            }
        }
    }
}
