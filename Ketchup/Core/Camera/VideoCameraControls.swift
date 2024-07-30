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
    @State private var showDeleteWarning = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // BOTTOM BUTTONS
            HStack(spacing: 30) {
                       deleteButton
                           .frame(width: 90)
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
                           .frame(width: 90)
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
               .alert(isPresented: $showDeleteWarning) {
                   Alert(
                       title: Text("Delete All"),
                       message: Text("Are you sure you want to delete all recorded videos? This action cannot be undone."),
                       primaryButton: .destructive(Text("Delete")) {
                           cameraViewModel.reset()
                           uploadViewModel.reset()
                       },
                       secondaryButton: .cancel()
                   )
               }
           }
    
    private var deleteButton: some View {
            Button {
                showDeleteWarning = true
            } label: {
                Text("Delete All")
                    .foregroundColor(.white)
                    .font(.custom("MuseoSansRounded-500", size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.red))
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            .opacity(!cameraViewModel.recordedURLs.isEmpty && !cameraViewModel.isRecording ? 1 : 0)
        }
    
    private var recordButton: some View {
        Button {
            if cameraViewModel.isRecording {
                cameraViewModel.stopRecording()
            } else {
                cameraViewModel.startRecording()
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
               if !cameraViewModel.recordedURLs.isEmpty {
                   cameraViewModel.navigateToUpload.toggle()
                   uploadViewModel.mediaType = .mixed
                   if let finalURL = cameraViewModel.previewURL {
                       uploadViewModel.mixedMediaItems = [MixedMediaItemHolder(localMedia: finalURL, type: .video)]
                   }
               }
           } label: {
               Group {
                   if cameraViewModel.isLoading {
                       ProgressView()
                           .tint(.white)
                   } else {
                       HStack(spacing: 4) {
                           Text("Next")
                               .font(.custom("MuseoSansRounded-500", size: 14))
                               .foregroundStyle(.black)
                           Image(systemName: "chevron.right")
                               .font(.system(size: 12, weight: .bold))
                               .foregroundStyle(.black)
                       }
                       .foregroundColor(.white)
                   }
               }
               .padding(.horizontal, 12)
               .padding(.vertical, 8)
               .background(Capsule().fill(.white))
               .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
           }
           .opacity(!cameraViewModel.recordedURLs.isEmpty && !cameraViewModel.isRecording ? 1 : 0)
       }
    
    private func addVideoToMixedMedia(videoURL: URL) {
        let mixedMediaItem = MixedMediaItemHolder(localMedia: videoURL, type: .video)
        uploadViewModel.mixedMediaItems.append(mixedMediaItem)
    }
}

// Helper struct for generating video thumbnails
