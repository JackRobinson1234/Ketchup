//
//  CombinedCameraControls.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/29/24.
//

import SwiftUI

struct CombinedCameraControls: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    @ObservedObject var uploadViewModel: UploadViewModel
    @EnvironmentObject var tabBarController: TabBarController
    @State private var cameraMode: CameraMode = .photo
    
    enum CameraMode {
        case photo, video
    }
    
    var body: some View {
        VStack {
            if cameraViewModel.previewURL == nil && cameraViewModel.images.isEmpty {
                cameraModeSelector
            }
            
            Spacer()
            
            HStack {
                // Delete button (for video mode)
                if cameraViewModel.selectedCamTab == 1 && (cameraViewModel.previewURL != nil || !cameraViewModel.recordedURLs.isEmpty) {
                    deleteButton
                } else {
                    Spacer()
                }
                
                // Capture button
                Button(action: captureMedia) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 80, height: 80)
                    }
                }
                
                // Next button
                if (cameraViewModel.selectedCamTab == 1 && cameraViewModel.previewURL != nil) ||
                   (cameraViewModel.selectedCamTab == 2 && cameraViewModel.isPhotoTaken) {
                    nextButton
                } else {
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private var cameraModeSelector: some View {
        HStack(spacing: 0) {
            Button(action: { cameraMode = .photo }) {
                Image(systemName: "camera")
                    .foregroundColor(cameraMode == .photo ? .black : .white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(cameraMode == .photo ? Color.white : Color.clear)
                    )
            }
            
            Button(action: { cameraMode = .video }) {
                Image(systemName: "video")
                    .foregroundColor(cameraMode == .video ? .black : .white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(cameraMode == .video ? Color.white : Color.clear)
                    )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.5))
        )
        .padding(.top, 20)
    }
    
    private var deleteButton: some View {
        Button(action: {
            // Implement delete functionality
        }) {
            Image(systemName: "trash")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
    }
    
    private func captureMedia() {
        if cameraMode == .video {
            if cameraViewModel.isRecording {
                cameraViewModel.stopRecording()
            } else {
                cameraViewModel.startRecording()
            }
        } else {
            cameraViewModel.takePic()
        }
    }
    
    private var nextButton: some View {
        Button(action: {
            cameraViewModel.navigateToUpload.toggle()
            if cameraMode == .video {
                uploadViewModel.videoURL = cameraViewModel.previewURL
                uploadViewModel.mediaType = .video
            } else {
                uploadViewModel.images = cameraViewModel.images
                uploadViewModel.mediaType = .photo
            }
        }) {
            Text("Next")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white))
        }
    }
}
