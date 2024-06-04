//
//  CameraView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//


import Foundation
import SwiftUI
import AVKit
import PhotosUI

struct CameraView: View {
    
    @StateObject var cameraViewModel = CameraViewModel()
    
    @StateObject var uploadViewModel = UploadViewModel()
    
    @EnvironmentObject var tabBarController: TabBarController
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                
                Color.black
                    .ignoresSafeArea()

                
                // WHAT THE CAMERA SEES
                CameraPreview(cameraViewModel: cameraViewModel, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
                    .cornerRadius(10)
                    .environmentObject(cameraViewModel)
                    .onAppear { cameraViewModel.checkPermission() }
                    .gesture(cameraViewModel.getDragStatus() ? cameraViewModel.drag : nil)
                    .onTapGesture(count: 2) {
                        cameraViewModel.toggleCamera()
                    }
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                cameraViewModel.handlePinchGesture(scale: value)
                            }
                            .onEnded { _ in
                                // Reset initial zoom factor at the end of the gesture
                                cameraViewModel.startPinchGesture()
                            }
                    )
                
                if cameraViewModel.showFlashOverlay {
                    Color.white.opacity(0.5)
                        .cornerRadius(10)
                }
                
                // MARK: CameraControls
                ZStack {
                    if cameraViewModel.dragDirection == "left" {
                        VideoCameraControls(cameraViewModel: cameraViewModel, uploadViewModel: uploadViewModel)
                    } else {
                        PhotoCameraControls(cameraViewModel: cameraViewModel, uploadViewModel: uploadViewModel)
                    }
                }
                
                
                // BEFORE ANY MEDIA PREVIEWS ARE CAPTURED
                VStack {
                    
                    HStack {
                        Button {
                            tabBarController.selectedTab = 0
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        .opacity((cameraViewModel.previewURL == nil && cameraViewModel.recordedURLs.isEmpty) || cameraViewModel.isRecording || !cameraViewModel.isPhotoTaken ? 1 : 0)
                        .padding(.top, 35)
                        .padding(.leading)

                        Spacer()
                        
                    }
                    
                    
                    Spacer()
                    
                    
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                        
                        // Write actual zoom level here
                        Text(String(format: "%.1fx", cameraViewModel.zoomFactor))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .blendMode(.destinationOut)
                    }
                    .padding(.bottom, 20)
                    
                    
                    HStack {
                        Button {
                            cameraViewModel.uploadFromLibray = true
                        } label: {
                                Image(systemName: "photo.on.rectangle")
                                    .resizable()
                                    .foregroundColor(.white)
                                    .scaledToFit()
                                    .frame(width: 50, height:50)
                                    .padding(.leading, 60)
                        }
                        
                        Spacer()
                    }
                    
                    .padding(.bottom, 20)
                    
                    HStack {
                        Text("Video")
                            .foregroundColor(cameraViewModel.dragDirection == "left" ? .white : .gray)
                            .fontWeight(cameraViewModel.dragDirection == "left" ? .bold : .regular)
                            .onTapGesture {
                                cameraViewModel.dragDirection = "left"
                            }
                        
                        Text("Photo")
                            .foregroundColor(cameraViewModel.dragDirection == "right" ? .white : .gray)
                            .fontWeight(cameraViewModel.dragDirection == "right" ? .bold : .regular)
                            .onTapGesture {
                                cameraViewModel.dragDirection = "right"
                            }
                    }
                    .padding(.bottom, 10)
                    
                }
                .opacity(cameraViewModel.isPhotoTaken || (cameraViewModel.previewURL != nil || !cameraViewModel.recordedURLs.isEmpty) || cameraViewModel.isRecording ? 0 : 1)
                
                HStack {
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        
                        Button(action: {
                            cameraViewModel.toggleCamera()
                        }) {
                            Image(systemName: "camera.rotate")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            switch cameraViewModel.flashMode {
                            case .off:
                                cameraViewModel.flashMode = .on
                            case .on:
                                cameraViewModel.flashMode = .off
                            default:
                                cameraViewModel.flashMode = .off
                            }
                        }) {
                            Image(systemName: cameraViewModel.flashMode == .off ? "bolt.slash.fill" : "bolt.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 35, height: 35)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.trailing)
                    .padding(.top, 35)
                }
                .opacity(cameraViewModel.isRecording ? 0 : 1)
                
                
            }
            .navigationDestination(isPresented: $cameraViewModel.navigateToUpload) {
                ReelsUploadView(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel)
                    .toolbar(.hidden, for: .tabBar)
            }
            .navigationDestination(isPresented: $cameraViewModel.uploadFromLibray) {
                LibrarySelectorView(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel)
                    .toolbar(.hidden, for: .tabBar)
            }

            .animation(.easeInOut, value: cameraViewModel.navigateToUpload)
            
            .onChange(of: tabBarController.selectedTab) {
                cameraViewModel.reset()
                uploadViewModel.reset()
            }
        }
    }
}


struct VideoCameraControls: View {
    
    @ObservedObject var cameraViewModel: CameraViewModel
    
    @ObservedObject var uploadViewModel: UploadViewModel
    @EnvironmentObject var tabBarController: TabBarController
    
    var body: some View {
        
        VStack {
            
            // VIDEO PROGRESS BAR
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.black.opacity(0.25))
                
                Rectangle()
                    .fill(Color("Colors/AccentColor"))
                    .frame(width: 390.0 * (cameraViewModel.recordedDuration / cameraViewModel.maxDuration))
            }
            .frame(height: 20)
            .cornerRadius(10)
            
            Spacer()
            
            // BOTTOM BUTTONS
            HStack(spacing: 30) {
                
                Button {
                    cameraViewModel.reset()
                    uploadViewModel.reset()
                } label: {
                    Group {
                        if cameraViewModel.isLoading{
                            // DO NOTHING
                        } else {
                            Text("Delete")
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 70, height: 30)
                    .cornerRadius(3)
                    .background {
                        Capsule()
                            .fill(Color("Colors/AccentColor"))
                    }
                }
                .frame(width: 100)
                .opacity((cameraViewModel.previewURL == nil || cameraViewModel.recordedURLs.isEmpty) || cameraViewModel.isRecording ? 0 : 1)
                
                
                // RECORD BUTTON
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
                
                
                // NAV TO UPLOAD BUTTON
                Button {
                    if let _ = cameraViewModel.previewURL {
                        cameraViewModel.navigateToUpload.toggle()
                        cameraViewModel.mediaType = "video"
                        
                        uploadViewModel.videoURL = cameraViewModel.previewURL
                        uploadViewModel.mediaType = "video"
                        
                    }
                } label: {
                    Group{
                        if cameraViewModel.isLoading{
                            // Merging Videos
                            ProgressView()
                                .tint(.black)
                        }
                        else{
                            Label {
                                Image(systemName: "chevron.right")
                                    .font(.callout)
                            } icon: {
                                Text("Next")
                            }
                            .foregroundColor(.black)
                        }
                    }
                    .frame(width: 70, height: 30)
                    .cornerRadius(3)
                    .background {
                        Capsule()
                            .fill(.white)
                    }
                }
                .frame(width: 100)
                .opacity((cameraViewModel.previewURL == nil && cameraViewModel.recordedURLs.isEmpty) || cameraViewModel.isRecording ? 0 : 1)
                
                
            }
            .padding(.bottom, 50)
            
        }
        .onReceive(Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()) { _ in
            if cameraViewModel.recordedDuration <= cameraViewModel.maxDuration && cameraViewModel.isRecording{
                cameraViewModel.recordedDuration += 0.01
            }
            if cameraViewModel.recordedDuration >= cameraViewModel.maxDuration && cameraViewModel.isRecording{
                cameraViewModel.stopRecording()
                cameraViewModel.isRecording = false
            }
        }
    }
}

struct PhotoCameraControls: View {
    
    @ObservedObject var cameraViewModel: CameraViewModel
    
    @ObservedObject var uploadViewModel: UploadViewModel
    
    @State private var showFlash = false
    
    var body: some View {
        
        
        ZStack {
            VStack {
                
                // TOP BUTTONS
                HStack {
                    
                    Spacer()
                    
                    VStack {
                        HStack(spacing: -30) {
                            ForEach((0..<5).reversed(), id: \.self) { index in
                                if index < cameraViewModel.images.count {
                                    Image(uiImage: cameraViewModel.images[cameraViewModel.images.count - 1 - index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 31.2, height: 45)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 1))
                                        .offset(x: CGFloat((2 - index) * 10), y: 0) // Adjust offset for reversed order
                                } else {
                                    if cameraViewModel.isLoading && index == 0 {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(width: 31.2, height: 45)
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                            .overlay(
                                                ProgressView()
                                                    .tint(.white)
                                            )
                                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 1))
                                            .offset(x: CGFloat((2 - index) * 10), y: 0) // Adjust offset for placeholders
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(width: 31.2, height: 45)
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                            .overlay(
                                                Text("+")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.white)
                                            )
                                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 1))
                                            .offset(x: CGFloat((2 - index) * 10), y: 0) // Adjust offset for placeholders
                                    }
                                    
                                }
                            }
                        }
                        
                        Text("\(cameraViewModel.images.count)/5")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                }
                
                Spacer()
                
                
                HStack(spacing: 30) {
                    Button {
                        cameraViewModel.untakePic()
                        cameraViewModel.mediaType = "none"
                    } label: {
                        Text("Delete")
                            .frame(width: 100, height: 50)
                            .background(Color("Colors/AccentColor"))
                            .cornerRadius(3.0)
                            .foregroundColor(.white)
                    }
                    .opacity(cameraViewModel.isPhotoTaken ? 1 : 0)
                    
                    
                    // TAKE PIC BUTTON
                    Button {
                        cameraViewModel.takePic()
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 5)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .fill(.white)
                                .frame(width: 60, height: 60)
                        }
                    }
                    
                    
                    // NAV TO UPLOAD BUTTON
                    Button {
                        if cameraViewModel.isPhotoTaken {
                            cameraViewModel.navigateToUpload.toggle()
                            cameraViewModel.mediaType = "photo"
                            uploadViewModel.images = cameraViewModel.images
                            uploadViewModel.mediaType = "photo"
                        }
                    } label: {
                        Label {
                            Image(systemName: "chevron.right")
                                .font(.callout)
                        } icon: {
                            Text("Preview")
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal,10)
                        .padding(.vertical,5)
                        .background {
                            Capsule()
                                .fill(.white)
                        }
                    }
                    .frame(width: 100)
                    .opacity(cameraViewModel.isPhotoTaken ? 1 : 0)
                }
                .padding(.bottom, 50)
            }
            
            if showFlash {
                Color.white
                    .opacity(0.8)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.3), value: showFlash)
            }
        }
    }
}

struct LibraryTypeMenuView: View {
    
    @ObservedObject var uploadViewModel: UploadViewModel
    @Binding var showLibraryTypeMenu: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            Text("Select Media Type")
                .font(.headline)
                .fontWeight(.bold)
                .frame(height: 50)
            
            Divider()
                .frame(width: 260)
            
            HStack(spacing: 0) {
                Button(action: {
                    showLibraryTypeMenu = false
                }) {
                    VStack {
                        Image(systemName: "video")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .foregroundColor(.black)
                            .opacity(0.6)
                                    
                        Text("Upload Videos")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .frame(width: 130, height: 100)
                }
                
                Divider()
                    .frame(height: 100)
                
                Button(action: {
                    showLibraryTypeMenu = false
                }) {
                    VStack {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .foregroundColor(.black)
                            .opacity(0.6)
                        
                        Text("Upload Photos")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .frame(width: 130, height: 100)
                }
            }
            
            Divider()
        }
        .frame(width: 260)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}



struct CameraPreview: UIViewRepresentable {
    
    @ObservedObject var cameraViewModel: CameraViewModel
    var size: CGSize
    
    func makeUIView(context: Context) -> UIView {
        
        let view = UIView()
        
        cameraViewModel.preview = AVCaptureVideoPreviewLayer(session: cameraViewModel.session)
        cameraViewModel.preview.frame.size = size
        cameraViewModel.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(cameraViewModel.preview)
        
        cameraViewModel.session.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
}
