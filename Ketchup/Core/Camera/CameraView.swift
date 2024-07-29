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

struct CameraView: View {
    @StateObject var cameraViewModel = CameraViewModel()
    @EnvironmentObject var tabBarController: TabBarController
    @ObservedObject var feedViewModel: FeedViewModel
    @StateObject var uploadViewModel: UploadViewModel
    @StateObject var keyboardObserver = KeyboardObserver()
    @State var dragDirection = "left"
    @State var isDragging = false
    @State private var canSwitchTab = true
    @State private var isImagePickerPresented = true
    @State private var selectedItems: [YPMediaItem] = []
    
    init(feedViewModel: FeedViewModel) {
        _feedViewModel = ObservedObject(wrappedValue: feedViewModel)
        _uploadViewModel = StateObject(wrappedValue: UploadViewModel(feedViewModel: feedViewModel))
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                guard canSwitchTab else { return }
                
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if cameraViewModel.selectedCamTab > 0 {
                        switchTab(to: cameraViewModel.selectedCamTab - 1)
                    }
                } else {
                    self.dragDirection = "right"
                    if cameraViewModel.selectedCamTab < 3 {
                        switchTab(to: cameraViewModel.selectedCamTab + 1)
                    }
                }
                self.isDragging = false
            }
    }
    
    var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    Color.white.edgesIgnoringSafeArea(.all)
                    
                    // Main content area
                    ZStack {
                        if cameraViewModel.audioOrVideoPermissionsDenied {
                            PermissionDeniedView()
                        } else {
                            if cameraViewModel.selectedCamTab == 1 || cameraViewModel.selectedCamTab == 2 {
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
                            }
                            
                            if cameraViewModel.showFlashOverlay {
                                Color.white.opacity(0.5)
                            }
                            
                            if !cameraViewModel.audioOrVideoPermissionsDenied {
                                VStack {
                                    if cameraViewModel.selectedCamTab == 0 {
                                        ImagePicker(isPresented: $isImagePickerPresented,  uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel)
                                    } else if cameraViewModel.selectedCamTab == 1 {
                                        VideoCameraControls(cameraViewModel: cameraViewModel, uploadViewModel: uploadViewModel)
                                    } else if cameraViewModel.selectedCamTab == 2 {
                                        PhotoCameraControls(cameraViewModel: cameraViewModel, uploadViewModel: uploadViewModel)
                                    } else if cameraViewModel.selectedCamTab == 3 {
                                        ReelsUploadView(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel, writtenReview: true)
                                    }
                                }
                                .edgesIgnoringSafeArea(.bottom)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.bottom,60)
                            }
                        }
                    }
                    .edgesIgnoringSafeArea(.top)
                    
                    // Top controls
                    VStack {
                        HStack {
                            if cameraViewModel.selectedCamTab != 0 {
                                Button {
                                    cameraViewModel.stopCameraSession()
                                    cameraViewModel.reset()
                                    uploadViewModel.reset()
                                    tabBarController.selectedTab = 0
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.custom("MuseoSansRounded-300", size: 28))
                                        .foregroundColor(cameraViewModel.selectedCamTab == 3 ? .black : .white)
                                }
                            } else {
                                Spacer().frame(width: 28) // Placeholder to maintain layout
                            }
                            
                            Spacer()
                            
                            if !cameraViewModel.audioOrVideoPermissionsDenied && (cameraViewModel.selectedCamTab == 1 || cameraViewModel.selectedCamTab == 2) {
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
                                            .frame(width: 28, height: 28)
                                            .foregroundColor(.white)
                                    }
                                }
                                .disabled(cameraViewModel.isRecording)
                                .opacity(cameraViewModel.isRecording ? 0 : 1)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, geometry.safeAreaInsets.top)
                        .frame(height: 60)
                        
                        Spacer()
                    }
                    
                    // Bottom tab bar
                    VStack(spacing: 0) {
                                           Spacer()
                                           
                                           HStack {
                                               CameraTabBarButton(text: "Library", isSelected: cameraViewModel.selectedCamTab == 0)
                                                   .onTapGesture { switchTab(to: 0) }
                                               CameraTabBarButton(text: "Video", isSelected: cameraViewModel.selectedCamTab == 1)
                                                   .onTapGesture { switchTab(to: 1) }
                                               CameraTabBarButton(text: "Photo", isSelected: cameraViewModel.selectedCamTab == 2)
                                                   .onTapGesture { switchTab(to: 2) }
                                               CameraTabBarButton(text: "Written", isSelected: cameraViewModel.selectedCamTab == 3)
                                                   .onTapGesture { switchTab(to: 3) }
                                           }
                                           .frame(height: 60)
                                           .frame(maxWidth: .infinity)
                                           .background(Color.clear) // Add this line to ensure consistent background
                                           .padding(.bottom, geometry.safeAreaInsets.bottom)
                                       }
                                       .edgesIgnoringSafeArea(.bottom)
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
            .onChange(of: tabBarController.selectedTab) {
                cameraViewModel.reset()
            }
            .onChange(of: cameraViewModel.selectedCamTab) { _, newValue in
                if newValue == 3 {
                    cameraViewModel.togglePreview(false)
                } else {
                    cameraViewModel.togglePreview(true)
                }
                
                if newValue == 0 {
                    isImagePickerPresented = true
                } else {
                    isImagePickerPresented = false
                }
            }
        
    }
    
    func switchTab(to newTab: Int) {
        guard canSwitchTab else { return }
        
        withAnimation {
            cameraViewModel.selectedCamTab = newTab
        }
        
        canSwitchTab = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            canSwitchTab = true
        }
        
        if newTab == 3 {
            cameraViewModel.togglePreview(false)
        } else {
            cameraViewModel.togglePreview(true)
        }
        
        if newTab == 0 {
            isImagePickerPresented = true
        } else {
            isImagePickerPresented = false
        }
    }
}

import Combine
import SwiftUI
import YPImagePicker

class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .sink { [weak self] height in
                self?.keyboardHeight = height
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
            .sink { [weak self] height in
                self?.keyboardHeight = height
            }
            .store(in: &cancellables)
    }
}
