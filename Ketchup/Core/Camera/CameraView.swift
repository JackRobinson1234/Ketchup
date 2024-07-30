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
import UniformTypeIdentifiers
import YPImagePicker

struct CameraView: View {
    @StateObject var cameraViewModel = CameraViewModel()
    @EnvironmentObject var tabBarController: TabBarController
    @StateObject var uploadViewModel: UploadViewModel
    @State private var isImagePickerPresented = true
    @State private var isKeyboardVisible = false
    @State private var cameraMode: CameraMode = .video

    enum CameraMode {
        case video, photo
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Top controls
                    topControls
                        .padding(.top, geometry.safeAreaInsets.top)
                    
                    // Main content area
                    ZStack {
                        if cameraViewModel.audioOrVideoPermissionsDenied {
                            PermissionDeniedView()
                        } else {
                            if cameraViewModel.selectedCamTab == 1 {
                                CameraPreview(cameraViewModel: cameraViewModel, size: geometry.size)
                                    .environmentObject(cameraViewModel)
                                    .onAppear {
                                        cameraViewModel.checkPermission()
                                        cameraViewModel.setUp()
                                        cameraViewModel.togglePreview(true)
                                    }
                                    .onTapGesture(count: 2) {
                                        cameraViewModel.toggleCamera()
                                    }
                                    .gesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                cameraViewModel.handlePinchGesture(scale: value)
                                            }
                                            .onEnded { _ in
                                                cameraViewModel.startPinchGesture()
                                            }
                                    )
                                
                                if cameraViewModel.showFlashOverlay {
                                    Color.white.opacity(0.5)
                                }
                                
                                VStack {
                                    Spacer()
                                    if cameraMode == .video {
                                        VideoCameraControls(cameraViewModel: cameraViewModel, uploadViewModel: uploadViewModel)
                                    } else {
                                        PhotoCameraControls(cameraViewModel: cameraViewModel, uploadViewModel: uploadViewModel)
                                    }
                                }
                            } else if cameraViewModel.selectedCamTab == 0 {
                                ImagePicker(isPresented: $isImagePickerPresented, uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel)
                            } else if cameraViewModel.selectedCamTab == 3 {
                                ReelsUploadView(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel, writtenReview: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom tab bar
                    if !isKeyboardVisible {
                        bottomTabBar
                            .frame(height: 60)
                            .background(Color.black.opacity(0.5))
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                }
                .edgesIgnoringSafeArea(.vertical)
            }
        }
        .gesture(
            cameraViewModel.isPhotoTaken || cameraViewModel.previewURL != nil || cameraViewModel.isRecording || uploadViewModel.restaurant != nil ? nil : drag
        )
        .fullScreenCover(isPresented: $cameraViewModel.navigateToUpload) {
            NavigationStack {
                ReelsUploadView(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel)
                    .toolbar(.hidden, for: .tabBar)
                    .onAppear {
                        cameraViewModel.stopCameraSession()
                    }
            }
        }
        .animation(.easeInOut, value: cameraViewModel.navigateToUpload)
        .onChange(of: tabBarController.selectedTab) { _ in
            cameraViewModel.reset()
        }
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
    }
    
    private var topControls: some View {
        HStack {
            if cameraViewModel.selectedCamTab == 1 {
                Button {
                    cameraViewModel.stopCameraSession()
                    cameraViewModel.reset()
                    uploadViewModel.reset()
                    tabBarController.selectedTab = 0
                } label: {
                    Image(systemName: "xmark")
                        .font(.custom("MuseoSansRounded-300", size: 28))
                        .foregroundColor(.white)
                }
            } else {
                Spacer().frame(width: 28)
            }
            
            Spacer()
            
            if !cameraViewModel.audioOrVideoPermissionsDenied && cameraViewModel.selectedCamTab == 1 {
                HStack(spacing: 20) {
                    Button(action: {
                        cameraViewModel.toggleCamera()
                    }) {
                        Image(systemName: "camera.rotate")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        cameraViewModel.flashMode = cameraViewModel.flashMode == .off ? .on : .off
                    }) {
                        Image(systemName: cameraViewModel.flashMode == .off ? "bolt.slash.fill" : "bolt.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: toggleCameraMode) {
                        Image(systemName: cameraMode == .video ? "camera" : "video")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.white)
                    }
                }
                .disabled(cameraViewModel.isRecording)
                .opacity(cameraViewModel.isRecording ? 0 : 1)
            }
        }
        .padding(.horizontal)
        .frame(height: 60)
    }
    
    private var bottomTabBar: some View {
        HStack {
            TabButton(title: "Library", isSelected: cameraViewModel.selectedCamTab == 0) {
                switchTab(to: 0)
            }
            TabButton(title: "Camera", isSelected: cameraViewModel.selectedCamTab == 1) {
                switchTab(to: 1)
            }
            TabButton(title: "Written", isSelected: cameraViewModel.selectedCamTab == 3) {
                switchTab(to: 3)
            }
        }
    }
    
    private func toggleCameraMode() {
        cameraMode = cameraMode == .video ? .photo : .video
        cameraViewModel.mediaType = cameraMode == .video ? .video : .photo
        cameraViewModel.reset()
    }
    
    private var drag: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { _ in }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    if cameraViewModel.selectedCamTab > 0 {
                        switchTab(to: cameraViewModel.selectedCamTab - 1)
                    }
                } else {
                    if cameraViewModel.selectedCamTab < 3 {
                        switchTab(to: cameraViewModel.selectedCamTab + 1)
                    }
                }
            }
    }
    
    private func switchTab(to newTab: Int) {
        withAnimation {
            cameraViewModel.selectedCamTab = newTab
        }
        
        if newTab == 3 {
            cameraViewModel.togglePreview(false)
        } else {
            cameraViewModel.togglePreview(true)
        }
        
        isImagePickerPresented = (newTab == 0)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            self.isKeyboardVisible = true
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            self.isKeyboardVisible = false
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("MuseoSansRounded-500", size: 14))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
        }
    }
}
