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
    
    var body: some View {
        VStack {
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
        if cameraViewModel.selectedCamTab == 1 {
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
            if cameraViewModel.selectedCamTab == 1 {
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
