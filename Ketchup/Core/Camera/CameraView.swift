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
    @StateObject var reviewsViewModel: ReviewsViewModel
    @EnvironmentObject var tabBarController: TabBarController
    @ObservedObject var feedViewModel: FeedViewModel
    @StateObject var uploadViewModel: UploadViewModel
    @StateObject var keyboardObserver = KeyboardObserver() // Add this line

    @State private var selectedCamTab = 0
    @State var dragDirection = "left"
    @State var isDragging = false

    init(feedViewModel: FeedViewModel) {
        _feedViewModel = ObservedObject(wrappedValue: feedViewModel)
        _uploadViewModel = StateObject(wrappedValue: UploadViewModel(feedViewModel: feedViewModel))
        _reviewsViewModel = StateObject(wrappedValue: ReviewsViewModel(feedViewModel: feedViewModel))
    }

    var drag: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if selectedCamTab == 1 {
                        selectedCamTab = 0
                    }
                } else {
                    self.dragDirection = "right"
                    if selectedCamTab == 0 {
                        selectedCamTab = 1
                    } else if selectedCamTab == 1 {
                        selectedCamTab = 2
                    }
                    self.isDragging = false
                }
            }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if selectedCamTab != 2 {
                    Color.black
                        .ignoresSafeArea()
                } else {
                    Color.white
                        .ignoresSafeArea()
                }

                if cameraViewModel.audioOrVideoPermissionsDenied {
                    PermissionDeniedView()
                } else {
                    if selectedCamTab != 2 {
                        CameraPreview(cameraViewModel: cameraViewModel, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
                            .cornerRadius(10)
                            .environmentObject(cameraViewModel)
                            .onAppear {
                                cameraViewModel.checkPermission()
                                cameraViewModel.startCameraSession()
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
                }

                if cameraViewModel.showFlashOverlay {
                    Color.white.opacity(0.5)
                        .cornerRadius(10)
                }

                if !cameraViewModel.audioOrVideoPermissionsDenied {
                    ZStack {
                        if selectedCamTab == 0 {
                            VideoCameraControls(cameraViewModel: cameraViewModel, uploadViewModel: uploadViewModel)
                        } else if selectedCamTab == 1 {
                            PhotoCameraControls(cameraViewModel: cameraViewModel, uploadViewModel: uploadViewModel)
                        } else if selectedCamTab == 2 {
                            UploadWrittenReviewView(reviewViewModel: reviewsViewModel, changeTab: true)
                        }
                    }
                }

                VStack {
                    HStack {
                        Button {
                            tabBarController.selectedTab = 0
                        } label: {
                            Image(systemName: "xmark")
                                .font(.custom("MuseoSansRounded-300", size: 28))
                                .foregroundColor(selectedCamTab == 2 ? .gray : .white)
                        }
                        .padding(.top, 35)
                        .padding(.leading)

                        Spacer()
                    }

                    Spacer()

                    if !cameraViewModel.audioOrVideoPermissionsDenied {
                        if cameraViewModel.isZooming && !(selectedCamTab == 2) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 30, height: 30)

                                Text(String(format: "%.1fx", cameraViewModel.zoomFactor))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .blendMode(.destinationOut)
                            }
                            .padding(.bottom, 20)
                        }

                        HStack {
                            Button {
                                cameraViewModel.uploadFromLibray = true
                            } label: {
                                Image(systemName: "photo.on.rectangle")
                                    .resizable()
                                    .foregroundColor(.white)
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .padding(.leading, 60)
                            }

                            Spacer()
                        }
                        .padding(.bottom, 10)
                        .opacity(selectedCamTab == 2 ? 0 : 1)

                        if uploadViewModel.restaurant == nil {
                            HStack {
                                CameraTabBarButton(text: "Video", isSelected: selectedCamTab == 0)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedCamTab = 0
                                        }
                                    }
                                CameraTabBarButton(text: "Photo", isSelected: selectedCamTab == 1)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedCamTab = 1
                                        }
                                    }
                                CameraTabBarButton(text: "Written", isSelected: selectedCamTab == 2)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedCamTab = 2
                                        }
                                    }
                            }
                            .padding(.bottom, 5)
                            .opacity(keyboardObserver.keyboardHeight > 0 ? 0 : 1)
                            .disabled(keyboardObserver.keyboardHeight > 0)
                        }
                    }
                }
                .padding(.bottom, keyboardObserver.keyboardHeight) // Add this line

                .opacity(cameraViewModel.isPhotoTaken || (cameraViewModel.previewURL != nil || !cameraViewModel.recordedURLs.isEmpty) || cameraViewModel.isRecording ? 0 : 1)

                if !cameraViewModel.audioOrVideoPermissionsDenied {
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
                    .opacity(selectedCamTab == 2 ? 0 : 1)
                }
            }
            .gesture(
                cameraViewModel.isPhotoTaken || cameraViewModel.previewURL != nil || cameraViewModel.isRecording || uploadViewModel.restaurant != nil ? nil : drag
            )
            .navigationDestination(isPresented: $cameraViewModel.navigateToUpload) {
                ReelsUploadView(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel)
                    .toolbar(.hidden, for: .tabBar)
                    .onAppear {
                        cameraViewModel.stopCameraSession()
                    }
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
            .onAppear {
                if uploadViewModel.restaurant == nil {
                    selectedCamTab = 0
                }
            }
            .onChange(of: selectedCamTab) { newValue in
                if newValue == 2 {
                    cameraViewModel.stopCameraSession()
                } else {
                    //cameraViewModel.startCameraSession()
                }
            }
        }
    }
}


import Combine
import SwiftUI

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
