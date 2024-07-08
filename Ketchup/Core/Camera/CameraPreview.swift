//
//  CameraPreview.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/8/24.
//

import Foundation
import SwiftUI
import AVFoundation
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraViewModel: CameraViewModel
    
    var size: CGSize
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.layer.addSublayer(setupCapturePreview())
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
    
    private func setupCapturePreview() -> AVCaptureVideoPreviewLayer {
        let capturePreview = AVCaptureVideoPreviewLayer(session: cameraViewModel.session)
        capturePreview.frame.size = size
        capturePreview.videoGravity = .resizeAspectFill
        return capturePreview
    }
}
