//
//  PhotoCameraControls.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/8/24.
//

import SwiftUI

struct PhotoCameraControls: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    @ObservedObject var uploadViewModel: UploadViewModel
    
    @State private var showFlash = false
    @State private var maxPhotosReached = false
    @State private var showWarning = false
    @State private var showReorderView = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80) // Add some space at the top
                    
                    // Top controls
                    HStack {
                        closeButton
                        Spacer()
                        photoStack
                        Spacer()
                        placeholderButton
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack(spacing: 30) {
                        deleteButton
                        captureButton
                        nextButton
                    }
                    .padding(.bottom, 20) // Adjust this value to create space above the tab bar
                }
                
                flashOverlay
                warningOverlay
            }
        }
        .onChange(of: cameraViewModel.images.count) { count in
            maxPhotosReached = count >= 5
        }
        .sheet(isPresented: $showReorderView) {
            PhotoReorderView(cameraViewModel: cameraViewModel)
        }
    }
    
    private var closeButton: some View {
        Button {
            cameraViewModel.clearPics()
            cameraViewModel.mediaType = .video
        } label: {
            Image(systemName: "xmark")
                .font(.custom("MuseoSansRounded-300", size: 20))
                .foregroundColor(.white)
        }
        .opacity(cameraViewModel.isPhotoTaken ? 1 : 0)
    }
    
    private var photoStack: some View {
            VStack(spacing: 4) { // Reduce spacing between elements
                HStack(spacing: -30) {
                    ForEach((0..<5).reversed(), id: \.self) { index in
                        photoStackItem(at: index)
                    }
                }
                
                if cameraViewModel.images.count > 0 {
                    Text("Edit")
                        .font(.custom("MuseoSansRounded-300", size: 14)) // Slightly smaller font
                        .foregroundColor(.white)
                }
                
                Text("\(cameraViewModel.images.count)/5")
                    .font(.custom("MuseoSansRounded-300", size: 14)) // Slightly smaller font
                    .foregroundColor(.white)
            }
        }
    
    private func photoStackItem(at index: Int) -> some View {
        Group {
            if index < cameraViewModel.images.count {
                Image(uiImage: cameraViewModel.images[cameraViewModel.images.count - 1 - index])
                    .resizable()
                    .scaledToFill()
                    .frame(width: 31.2, height: 45)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 1))
                    .offset(x: CGFloat((2 - index) * 10), y: 0)
                    .onTapGesture {
                        showReorderView.toggle()
                    }
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 31.2, height: 45)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(
                        Group {
                            if cameraViewModel.isLoading && index == 0 {
                                ProgressView().tint(.white)
                            }
                        }
                    )
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 1))
                    .offset(x: CGFloat((2 - index) * 10), y: 0)
            }
        }
    }
    
    private var placeholderButton: some View {
        Image(systemName: "xmark")
            .font(.custom("MuseoSansRounded-300", size: 20))
            .foregroundColor(.white)
            .opacity(0)
    }
    
    private var deleteButton: some View {
        Button {
            cameraViewModel.clearLatestPic()
        } label: {
            Image(systemName: "delete.left")
                .resizable()
                .foregroundStyle(.white)
                .scaledToFit()
                .frame(height: 35)
                .frame(width: 80)
        }
        .opacity(cameraViewModel.isPhotoTaken ? 1 : 0)
    }
    
    private var captureButton: some View {
        Button {
            if !maxPhotosReached {
                cameraViewModel.takePic()
            } else {
                showWarning = true
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(maxPhotosReached || cameraViewModel.isLoading ? .gray : .white, lineWidth: 5)
                    .frame(width: 70, height: 70)
                Circle()
                    .fill(maxPhotosReached || cameraViewModel.isLoading ? .gray : .white)
                    .frame(width: 60, height: 60)
                
                if cameraViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .disabled(cameraViewModel.isLoading)
    }
    
    private var nextButton: some View {
        Button {
            if cameraViewModel.isPhotoTaken {
                cameraViewModel.navigateToUpload.toggle()
                cameraViewModel.mediaType = .photo
                uploadViewModel.images = cameraViewModel.images
                uploadViewModel.mediaType = .photo
            }
        } label: {
            Label {
                Image(systemName: "chevron.right")
                    .font(.callout)
            } icon: {
                Text("Next")
                    .font(.custom("MuseoSansRounded-500", size: 16))
            }
            .foregroundColor(.black)
            .frame(width: 70, height: 30)
            .background(Capsule().fill(.white))
        }
        .frame(width: 80)
        .opacity(cameraViewModel.isPhotoTaken ? 1 : 0)
    }
    
    private var flashOverlay: some View {
        Color.white
            .opacity(showFlash ? 0.8 : 0)
            .animation(.easeOut(duration: 0.3), value: showFlash)
    }
    
    private var warningOverlay: some View {
        Group {
            if showWarning {
                Text("Maximum photos reached")
                    .foregroundColor(.white)
                    .font(.custom("MuseoSansRounded-300", size: 18))
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(10)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showWarning = false
                        }
                    }
            }
        }
    }
}
