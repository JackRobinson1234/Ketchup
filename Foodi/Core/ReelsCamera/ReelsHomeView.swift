//
//  ReelsCameraView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/1/24.
//

import Foundation
import SwiftUI
import AVKit

struct ReelsHomeView: View {
    @StateObject var cameraModel = ReelsCameraViewModel()
    
    @State var longPress = false
    @State var longPressTimer: Timer?
    
    @State private var isDragging = false
    @State private var dragDirection = "left"
    
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

    var body: some View {
        
        NavigationStack {
            ZStack(alignment: .bottom) {
                
                Color.black
                    .ignoresSafeArea()
                
                // WHAT THE CAMERA SEES
                CameraPreview(cameraModel: cameraModel, size: CGSize(width: 390.0, height: 844.0))
                    .environmentObject(cameraModel)
                    .cornerRadius(10)
                    .onAppear { cameraModel.checkPermission() }
                    .gesture(drag)
                    
                
                // MARK: CameraControls
                ZStack {
                    if self.dragDirection == "left" {
                        VideoCameraControls(cameraModel: cameraModel)
                    } else {
                        PhotoCameraControls(cameraModel: cameraModel)
                    }
                }
                
                
                // BEFORE ANY MEDIA PREVIEWS ARE CAPTURED
                VStack {
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .resizable()
                            .foregroundColor(.white)
                            .scaledToFit()
                            .frame(width: 50, height:50)
                            .padding(.leading, 60)
                        
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    
                    HStack {
                        Text("Video")
                            .foregroundColor(self.dragDirection == "left" ? .white : .gray)
                            .fontWeight(self.dragDirection == "left" ? .bold : .regular)
                            .onTapGesture {
                                self.dragDirection = "left"
                            }
                        
                        Text("Photo")
                            .foregroundColor(self.dragDirection == "right" ? .white : .gray)
                            .fontWeight(self.dragDirection == "right" ? .bold : .regular)
                            .onTapGesture {
                                self.dragDirection = "right"
                            }
                    }
                    .padding(.bottom, 10)
                    
                }
                .opacity(cameraModel.isPhotoTaken || (cameraModel.previewURL != nil || !cameraModel.recordedURLs.isEmpty) || cameraModel.isRecording ? 0 : 1)

                
            }
            .navigationDestination(isPresented: $cameraModel.showPreview) {
                ReelsUploadView()
                    
            }
            .animation(.easeInOut, value: cameraModel.showPreview)
        }

    }
}


struct FinalVideoPreview: View {
    
    @ObservedObject var cameraModel: ReelsCameraViewModel
    
    var body: some View {
        
        if let url = cameraModel.previewURL {
            let player = AVPlayer(url: url)
            VideoPlayer(player: player)
                .cornerRadius(10)
                .overlay(alignment: .topLeading) {
                    Button {
                        cameraModel.showPreview.toggle()
                    } label: {
                        Label {
                            Text("Back")
                        } icon: {
                            Image(systemName: "chevron.left")
                        }
                        .foregroundColor(.white)
                    }
                    .padding(.leading)
                    .padding(.top, 22)
                }
                .onAppear { player.play() }
        }
    }
}

struct FinalPhotoPreview: View {
    
    @ObservedObject var cameraModel: ReelsCameraViewModel
    
    @State private var currentPage = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)

                TabView(selection: $currentPage) {
                    ForEach(cameraModel.picData.indices, id: \.self) { index in
                        Image(uiImage: UIImage(data: cameraModel.picData[index]) ?? UIImage())
                            .resizable()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .cornerRadius(10)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .overlay(alignment: .topLeading) {
            Button {
                cameraModel.showPreview.toggle()
            } label: {
                Label {
                    Text("Back")
                } icon: {
                    Image(systemName: "chevron.left")
                }
                .foregroundColor(.white)
            }
            .padding(.leading)
            .padding(.top, 22)
        }
    }
}

struct VideoCameraControls: View {
    
    @ObservedObject var cameraModel: ReelsCameraViewModel
    
    var body: some View {
        
        VStack {
            
            // VIDEO PROGRESS BAR
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.black.opacity(0.25))
                
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 390.0 * (cameraModel.recordedDuration / cameraModel.maxDuration))
            }
            .frame(height: 20)
            .cornerRadius(10)
            
            // X BUTTON
            HStack {
                Button {
                    cameraModel.recordedDuration = 0
                    cameraModel.previewURL = nil
                    cameraModel.recordedURLs.removeAll()
                    cameraModel.previewType = "none"
                } label: {
                    Image(systemName: "xmark")
                        .font(.title)
                        .foregroundColor(.white)
                }
                .opacity((cameraModel.previewURL == nil && cameraModel.recordedURLs.isEmpty) || cameraModel.isRecording ? 0 : 1)
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
                    if cameraModel.isRecording {
                        cameraModel.stopRecording()
                    } else {
                        cameraModel.startRecording()
                        if cameraModel.previewURL == nil {
                            cameraModel.previewURL = URL(string: "_")
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 5)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .fill(cameraModel.isRecording ? .clear : .red)
                            .frame(width: 60, height: 60)
                    }
                }
                
                
                // PREVIEW BUTTON
                Button {
                    if let _ = cameraModel.previewURL {
                        cameraModel.showPreview.toggle()
                        cameraModel.previewType = "video"
                    }
                } label: {
                    Group{
                        if cameraModel.previewURL == nil && !cameraModel.recordedURLs.isEmpty{
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
                .opacity((cameraModel.previewURL == nil && cameraModel.recordedURLs.isEmpty) || cameraModel.isRecording ? 0 : 1)
                
                
            }
            .padding(.bottom, 50)
            
        }
        .onReceive(Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()) { _ in
            if cameraModel.recordedDuration <= cameraModel.maxDuration && cameraModel.isRecording{
                cameraModel.recordedDuration += 0.01
            }
            if cameraModel.recordedDuration >= cameraModel.maxDuration && cameraModel.isRecording{
                cameraModel.stopRecording()
                cameraModel.isRecording = false
            }
        }
    }
}

struct PhotoCameraControls: View {
    
    @ObservedObject var cameraModel: ReelsCameraViewModel
    
    @State private var showFlash = false
    
    var body: some View {
        
        
        ZStack {
            VStack {
                
                // TOP BUTTONS
                HStack {
                    Button {
                        cameraModel.untakePic()
                        cameraModel.previewType = "none"
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .opacity(cameraModel.isPhotoTaken ? 1 : 0)
                    .padding(.top)
                    .padding(.leading)
                    
                    Spacer()
                    
                    HStack {
                        Text("\(cameraModel.picData.count)/3")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: -30) {
                            ForEach((0..<3).reversed(), id: \.self) { index in
                                if index < cameraModel.picData.count {
                                    Image(uiImage: UIImage(data: cameraModel.picData[cameraModel.picData.count - 1 - index]) ?? UIImage())
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
                        cameraModel.takePic()
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
                    
                    
                    // PREVIEW BUTTON
                    Button {
                        if cameraModel.isPhotoTaken {
                            cameraModel.showPreview.toggle()
                            cameraModel.previewType = "photo"
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
                    .opacity(cameraModel.isPhotoTaken ? 1 : 0)
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

struct CameraPreview: UIViewRepresentable {
    
    @ObservedObject var cameraModel: ReelsCameraViewModel
    var size: CGSize
    
    func makeUIView(context: Context) -> UIView {
        
        let view = UIView()
        
        cameraModel.preview = AVCaptureVideoPreviewLayer(session: cameraModel.session)
        cameraModel.preview.frame.size = size
        
        // adjust to our own properties
        cameraModel.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(cameraModel.preview)
        
        cameraModel.session.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
}
