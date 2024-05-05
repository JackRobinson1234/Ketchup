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
    
    @State var showLibraryTypeMenu = false
    @State var showImagePicker = false
    @State var selectedItem: PhotosPickerItem? {
        didSet { Task { await uploadViewModel.loadMediafromPhotosPicker(fromItem: selectedItem) } }
    }
    @State var snapshotImage: UIImage?
    
    var body: some View {
        
        NavigationStack {
            ZStack(alignment: .bottom) {
                
                Color.black
                    .ignoresSafeArea()
//                
//                // WHAT THE CAMERA SEES
//                CameraPreview(cameraViewModel: cameraViewModel, size: CGSize(width: 390.0, height: 844.0))
//                    .environmentObject(cameraViewModel)
//                    .cornerRadius(10)
//                    .onAppear { cameraViewModel.checkPermission() }
//                    .gesture(cameraViewModel.drag)
                    
                
                if let snapshotImage = snapshotImage, showLibraryTypeMenu {
                    Image(uiImage: snapshotImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 390, height: 844)
                        .blur(radius: 10)
                        .transition(.opacity)
                } else {
                    CameraPreview(cameraViewModel: cameraViewModel, size: CGSize(width: 390.0, height: 844.0))
                        .environmentObject(cameraViewModel)
                        .cornerRadius(10)
                        .onAppear { cameraViewModel.checkPermission() }
                        .gesture(cameraViewModel.drag)
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
                    
                    Spacer()
                    
                    HStack {
                        Button {
                            showLibraryTypeMenu = true
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
            }
//            .onChange(of: showLibraryTypeMenu) { isShowing in
//                if isShowing {
//                    snapshotImage = cameraViewModel.capturePreviewSnapshot()
//                    cameraViewModel.session.stopRunning()
//                } else {
//                    cameraViewModel.session.startRunning()
//                    snapshotImage = nil
//                }
//            }
            
            .overlay(
                Group {
                    if showLibraryTypeMenu {
                        LibraryTypeMenuView(uploadViewModel: uploadViewModel, showLibraryTypeMenu: $showLibraryTypeMenu)
                            .animation(.easeInOut, value: showLibraryTypeMenu)
                            .transition(.move(edge: .bottom))
                    }
                }
            )
            .navigationDestination(isPresented: $cameraViewModel.navigateToUpload) {
                ReelsUploadView(uploadViewModel: uploadViewModel)
                    
            }
            
            .photosPicker(isPresented: $showImagePicker, selection: $selectedItem, matching: .videos)
            .animation(.easeInOut, value: cameraViewModel.navigateToUpload)
        }

    }
}


struct VideoCameraControls: View {
    
    @ObservedObject var cameraViewModel: CameraViewModel
    
    @ObservedObject var uploadViewModel: UploadViewModel
    
    var body: some View {
        
        VStack {
            
            // VIDEO PROGRESS BAR
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.black.opacity(0.25))
                
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 390.0 * (cameraViewModel.recordedDuration / cameraViewModel.maxDuration))
            }
            .frame(height: 20)
            .cornerRadius(10)
            
            // X BUTTON
            HStack {
                Button {
                    cameraViewModel.recordedDuration = 0
                    cameraViewModel.previewURL = nil
                    cameraViewModel.recordedURLs.removeAll()
                    cameraViewModel.mediaType = "none"
                } label: {
                    Image(systemName: "xmark")
                        .font(.title)
                        .foregroundColor(.white)
                }
                .opacity((cameraViewModel.previewURL == nil && cameraViewModel.recordedURLs.isEmpty) || cameraViewModel.isRecording ? 0 : 1)
                .padding(.top)
                .padding(.leading)
                
                Spacer()
            }
            
            
            Spacer()
            
            // BOTTOM BUTTONS
            HStack(spacing: 30) {
                
                Rectangle()
                    .frame(width: 100, height: 50) // Outer frame
                    .hidden()
                
                
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
                            .fill(cameraViewModel.isRecording ? .clear : .red)
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
                        if cameraViewModel.previewURL == nil && !cameraViewModel.recordedURLs.isEmpty{
                            // Merging Videos
                            ProgressView()
                                .tint(.black)
                        }
                        else{
                            Label {
                                Image(systemName: "chevron.right")
                                    .font(.callout)
                            } icon: {
                                Text("Preview")
                            }
                            .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal,10)
                    .padding(.vertical,5)
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
                    Button {
                        cameraViewModel.untakePic()
                        cameraViewModel.mediaType = "none"
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .opacity(cameraViewModel.isPhotoTaken ? 1 : 0)
                    .padding(.top)
                    .padding(.leading)
                    
                    Spacer()
                    
                    HStack {
                        Text("\(cameraViewModel.picData.count)/3")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: -30) {
                            ForEach((0..<3).reversed(), id: \.self) { index in
                                if index < cameraViewModel.picData.count {
                                    Image(uiImage: UIImage(data: cameraViewModel.picData[cameraViewModel.picData.count - 1 - index]) ?? UIImage())
                                        .resizable()
                                        .frame(width: 30, height: 45)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 1))
                                        .offset(x: CGFloat((2 - index) * 10), y: 0) // Adjust offset for reversed order
                                } else {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(width: 30, height: 45)
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
                    .padding(.top)
                    .padding(.trailing, 30)
                }
                
                Spacer()
                
                
                HStack(spacing: 30) {
                    Rectangle()
                        .frame(width: 100, height: 50) // Outer frame
                        .hidden()
                    
                    
                    // TAKE PIC BUTTON
                    Button {
                        cameraViewModel.takePic()
                        withAnimation {
                            showFlash = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showFlash = false
                            }
                        }
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
                            
                            
                            uploadViewModel.picData = cameraViewModel.picData
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
        
        // adjust to our own properties
        cameraViewModel.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(cameraViewModel.preview)
        
        cameraViewModel.session.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
}
