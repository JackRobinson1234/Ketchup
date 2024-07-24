//
//  VideoCameraControls.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/8/24.
//

import SwiftUI

struct VideoCameraControls: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    @ObservedObject var uploadViewModel: UploadViewModel
    @EnvironmentObject var tabBarController: TabBarController
    
    var body: some View {
        VStack(spacing: 0) {
            // VIDEO PROGRESS BAR
            Spacer().frame(height: 30) 
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.black.opacity(0.25))
                
                Rectangle()
                    .fill(Color("Colors/AccentColor"))
                    .frame(width: UIScreen.main.bounds.width * (cameraViewModel.recordedDuration / cameraViewModel.maxDuration))
            }
            .frame(height: 4)
            
            Spacer()
            
            // BOTTOM BUTTONS
            HStack(spacing: 30) {
                deleteButton
                recordButton
                nextButton
            }
            .padding(.bottom, 20)
        }
        .onReceive(Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()) { _ in
            if cameraViewModel.recordedDuration <= cameraViewModel.maxDuration && cameraViewModel.isRecording {
                cameraViewModel.recordedDuration += 0.01
            }
            if cameraViewModel.recordedDuration >= cameraViewModel.maxDuration && cameraViewModel.isRecording {
                cameraViewModel.stopRecording()
                cameraViewModel.isRecording = false
            }
        }
    }
    
    private var deleteButton: some View {
        Button {
            cameraViewModel.reset()
            uploadViewModel.reset()
        } label: {
            Group {
                if cameraViewModel.isLoading {
                    // DO NOTHING
                } else {
                    Text("Delete")
                        .foregroundColor(.white)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                }
            }
            .frame(width: 70, height: 30)
            .background(Capsule().fill(Color("Colors/AccentColor")))
        }
        .frame(width: 80)
        .opacity((cameraViewModel.previewURL == nil || cameraViewModel.recordedURLs.isEmpty) || cameraViewModel.isRecording ? 0 : 1)
    }
    
    private var recordButton: some View {
        Button {
            if cameraViewModel.isRecording {
                cameraViewModel.stopRecording()
            } else {
                cameraViewModel.startRecording()
                if cameraViewModel.previewURL == nil {
                    cameraViewModel.previewURL = URL(string: "_")
                }
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(.white, lineWidth: 5)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .fill(cameraViewModel.isRecording ? .clear : Color("Colors/AccentColor"))
                    .frame(width: 60, height: 60)
            }
        }
    }
    
    private var nextButton: some View {
        Button {
            if let _ = cameraViewModel.previewURL {
                cameraViewModel.navigateToUpload.toggle()
                cameraViewModel.mediaType = .video
                
                uploadViewModel.videoURL = cameraViewModel.previewURL
                uploadViewModel.mediaType = .video
            }
        } label: {
            Group {
                if cameraViewModel.isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Label {
                        Image(systemName: "chevron.right")
                            .font(.callout)
                    } icon: {
                        Text("Next")
                            .font(.custom("MuseoSansRounded-500", size: 16))
                    }
                    .foregroundColor(.black)
                }
            }
            .frame(width: 70, height: 30)
            .background(Capsule().fill(.white))
        }
        .frame(width: 80)
        .opacity((cameraViewModel.previewURL == nil && cameraViewModel.recordedURLs.isEmpty) || cameraViewModel.isRecording ? 0 : 1)
    }
}
