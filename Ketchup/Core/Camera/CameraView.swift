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
    @Environment(\.dismiss) var dismiss

    enum CameraMode {
        case video, photo
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Main content area
                    ZStack {
                        
                        if cameraViewModel.selectedCamTab == 1 {
                            if cameraViewModel.audioOrVideoPermissionsDenied {
                                PermissionDeniedView()
                            } else {
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
                                
                            }
                        } else if cameraViewModel.selectedCamTab == 0 {
                                ImagePicker(isPresented: $isImagePickerPresented, uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel)
                            } else if cameraViewModel.selectedCamTab == 3 {
                                ReelsUploadView(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel, writtenReview: true)
                            }
                        
                        topControls
                            .padding(.top, geometry.safeAreaInsets.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom tab bar
                    if !isKeyboardVisible {
                        bottomTabBar
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                }
                .edgesIgnoringSafeArea(.vertical)
            }
            .edgesIgnoringSafeArea(.vertical)
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
                            .onDisappear {
                                if !uploadViewModel.dismissAll{
                                    cameraViewModel.restartCameraSession()
                                }
                            }
                    }
                }
                .animation(.easeInOut, value: cameraViewModel.navigateToUpload)
                .onChange(of: tabBarController.selectedTab) {newValue in
                    cameraViewModel.reset()
                }
                .onAppear {
                    setupKeyboardObservers()
                    cameraViewModel.checkPermission()
                    cameraViewModel.setUp()
                    cameraViewModel.togglePreview(true)
                }
                .onDisappear {
                    removeKeyboardObservers()
                    cameraViewModel.stopCameraSession()
                }
                .onChange(of: uploadViewModel.dismissAll) {newValue in
                    if newValue {
                        uploadViewModel.dismissAll = false
                        dismiss()
                        //cameraViewModel.restartCameraSession()
                    }
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
    }
    
    private var topControls: some View {
        VStack {
            HStack {
                if cameraViewModel.selectedCamTab == 1 && cameraViewModel.previewURL == nil && cameraViewModel.images.isEmpty {
                    Button {
                        cameraViewModel.stopCameraSession()
                        cameraViewModel.reset()
                        uploadViewModel.reset()
                        dismiss()
                        //tabBarController.selectedTab = 0
                     
                    } label: {
                        Image(systemName: "xmark")
                            .font(.custom("MuseoSansRounded-300", size: 28))
                            .foregroundColor(.white)
                            .frame(width: 80)
                    }
                } else {
                    Spacer().frame(width: 80)
                }
                
                Spacer()
                
                if !cameraViewModel.audioOrVideoPermissionsDenied && cameraViewModel.selectedCamTab == 1 && cameraViewModel.previewURL == nil && cameraViewModel.images.isEmpty {
                    cameraModeSelector
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
                    }
                    .frame(width: 80)
                    .disabled(cameraViewModel.isRecording)
                    .opacity(cameraViewModel.isRecording ? 0 : 1)
                } else {
                    Spacer().frame(width: 80)  // To maintain balance when buttons are not shown
                }
            }
            .padding(.horizontal)
            .frame(height: 60)
            
            Spacer()
        }
    }
    private var bottomTabBar: some View {
        ZStack(alignment: .bottom) {
            // Background
            Color.white.opacity(0.5)
                .frame(height: 40)
            
            // Tab buttons
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
            .frame(maxWidth: .infinity)
            .frame(height: 40)  // Consistent height for the tab bar
        }
        // Consistent overall height
        .animation(.easeInOut, value: cameraViewModel.selectedCamTab)
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
                .font(.custom("MuseoSansRounded-500", size: 16))
                .foregroundColor(isSelected ? Color("Colors/AccentColor") : .gray)
                .frame(maxWidth: .infinity)
        }
    }
}
