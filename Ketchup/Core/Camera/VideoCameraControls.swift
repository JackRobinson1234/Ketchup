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
            Spacer()
            
            // BOTTOM BUTTONS
            HStack(spacing: 30) {
                deleteButton
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 5)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(cameraViewModel.recordedDuration / cameraViewModel.maxDuration))
                        .stroke(Color("Colors/AccentColor"), lineWidth: 5)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    recordButton
                }
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
                    Text("Delete All")
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
                    .fill(cameraViewModel.isRecording ? .clear : Color("Colors/AccentColor"))
                    .frame(width: 60, height: 60)
                
                if cameraViewModel.isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("Colors/AccentColor"))
                        .frame(width: 20, height: 20)
                }
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
