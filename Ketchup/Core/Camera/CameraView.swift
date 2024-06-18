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


import Foundation
import SwiftUI
import AVKit
import PhotosUI
import UniformTypeIdentifiers


struct CameraView: View {
    
    @StateObject var cameraViewModel = CameraViewModel()
    
    @StateObject var uploadViewModel = UploadViewModel()
    
    @StateObject var reviewsViewModel = ReviewsViewModel()
    
    @EnvironmentObject var tabBarController: TabBarController
    
    @State private var selectedCamTab = 0
    
    @State var dragDirection = "left"
    @State var isDragging = false
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if selectedCamTab == 1 {
                        selectedCamTab = 0
                    } else if selectedCamTab == 2 {
                        selectedCamTab = 1
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
                Color.black
                    .ignoresSafeArea()
                
                // WHAT THE CAMERA SEES
                if cameraViewModel.audioOrVideoPermissionsDenied {
                    PermissionDeniedView()
                } else {
                    CameraPreview(cameraViewModel: cameraViewModel, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
                        .cornerRadius(10)
                        .environmentObject(cameraViewModel)
                        .onAppear {
                            cameraViewModel.checkPermission()
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
                                    // Reset initial zoom factor at the end of the gesture
                                    cameraViewModel.startPinchGesture()
                                }
                        )
                }
                
                if cameraViewModel.showFlashOverlay {
                    Color.white.opacity(0.5)
                        .cornerRadius(10)
                }
                
                // MARK: CameraControls
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
                
                // BEFORE ANY MEDIA PREVIEWS ARE CAPTURED
                VStack {
                    
                    HStack {
                        Button {
                            tabBarController.selectedTab = 0
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title)
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
                                
                                // Write actual zoom level here
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
                        }
                        
                    }
                }
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
            .padding(.bottom, 70)
            
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
    @State private var maxPhotosReached = false
    @State private var showWarning = false
    @State private var showReorderView = false

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        cameraViewModel.clearPics()
                        cameraViewModel.mediaType = "none"
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 12)
                    .padding(.leading)
                    .opacity(cameraViewModel.isPhotoTaken ? 1 : 0)
                    
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
                                        .offset(x: CGFloat((2 - index) * 10), y: 0)
                                        .onTapGesture {
                                            showReorderView.toggle()
                                        }
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
                                            .offset(x: CGFloat((2 - index) * 10), y: 0)
                                    } else {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(width: 31.2, height: 45)
                                            .clipShape(RoundedRectangle(cornerRadius: 5))
                                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 1))
                                            .offset(x: CGFloat((2 - index) * 10), y: 0)
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
                    
                    Image(systemName: "xmark")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.trailing)
                        .opacity(0)
                }
                
                Spacer()
                
                HStack(spacing: 30) {
                    Button {
                        cameraViewModel.clearLatestPic()
                    } label: {
                        Text("Delete Latest")
                            .frame(width: 100, height: 50)
                            .background(Color("Colors/AccentColor"))
                            .cornerRadius(3.0)
                            .foregroundColor(.white)
                    }
                    .opacity(cameraViewModel.isPhotoTaken ? 1 : 0)
                    
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
                        }
                        .overlay(
                            Group {
                                if cameraViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                        )
                    }
                    .disabled(cameraViewModel.isLoading)

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
                            Text("Next")
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
                .padding(.bottom, 70)
            }
            
            if showFlash {
                Color.white
                    .opacity(0.8)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.3), value: showFlash)
            }
            
            if showWarning {
                Text("Maximum photos reached")
                    .foregroundColor(.white)
                    .font(.headline)
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
        .onChange(of: cameraViewModel.images.count) { count in
            maxPhotosReached = count >= 5
        }
        .sheet(isPresented: $showReorderView) {
            PhotoReorderView(cameraViewModel: cameraViewModel)
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

struct PermissionDeniedView: View {
    
    var body: some View {
        VStack {
            Spacer()
            Text("Allow Ketchup to access camera and microphone")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            Text("This will let you use the in app camera")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .opacity(0.8)
                .padding()
            
            Button(action: {
                openAppSettings()
            }) {
                Text("Open Settings")
                    .foregroundColor(Color("Colors/AccentColor"))
            }
            
            Spacer()
        }
    }
    
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
}

struct PhotoReorderView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var draggedItem: UIImage?
    @State private var draggedIndex: Int?
    @State private var dropIndex: Int?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .foregroundColor(.blue)
                        .padding()
                }
                Spacer()
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(cameraViewModel.images.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: cameraViewModel.images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 104, height: 225)
                                .cornerRadius(10)
                                .clipped()
                                .shadow(radius: 5)
                                //.offset(y: draggedIndex == index ? -20 : 0)
                                .onDrag {
                                    self.draggedItem = cameraViewModel.images[index]
                                    self.draggedIndex = index
                                    return NSItemProvider(object: String(index) as NSString)
                                }
                                .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: cameraViewModel.images[index], listData: $cameraViewModel.images, current: index, draggedIndex: $draggedIndex, dropIndex: $dropIndex))
                                .onHover { hovering in
                                    if hovering {
                                        self.dropIndex = index
                                    } else {
                                        if self.dropIndex == index {
                                            self.dropIndex = nil
                                        }
                                    }
                                }

                            Button(action: {
                                cameraViewModel.images.remove(at: index)
                                if cameraViewModel.images.isEmpty {
                                    cameraViewModel.isPhotoTaken = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .padding(5)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onChange(of: dropIndex) { _ in
            if let draggedIndex = draggedIndex, let dropIndex = dropIndex {
                
                    reorderImages(from: draggedIndex, to: dropIndex)
                
            }
        }
        .onChange(of: draggedIndex) { _ in
            if draggedIndex == nil {
                dropIndex = nil
            }
        }
    }


    private func reorderImages(from source: Int, to destination: Int) {
        if source != destination {
            var images = cameraViewModel.images
            let item = images.remove(at: source)
            images.insert(item, at: destination)
            cameraViewModel.images = images
            self.draggedIndex = destination
        }
    }
}

struct DragRelocateDelegate: DropDelegate {
    let item: UIImage
    @Binding var listData: [UIImage]
    let current: Int
    @Binding var draggedIndex: Int?
    @Binding var dropIndex: Int?

    func dropEntered(info: DropInfo) {
        guard let draggedIndex = draggedIndex else { return }
        if current != draggedIndex {
            withAnimation {
                moveItem(from: draggedIndex, to: current)
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedIndex = draggedIndex, let dropIndex = dropIndex else { return false }
        withAnimation {
            moveItem(from: draggedIndex, to: dropIndex)
        }
        self.draggedIndex = nil
        self.dropIndex = nil
        return true
    }

    private func moveItem(from source: Int, to destination: Int) {
        if source != destination {
            var updatedList = listData
            let item = updatedList.remove(at: source)
            updatedList.insert(item, at: destination)
            listData = updatedList
            self.draggedIndex = destination
        }
    }
}

struct CameraTabBarButton: View {
    let text: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            if text == "Written" && isSelected {
                Text(text)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            } else {
                Text(text)
                    .foregroundColor(isSelected ? .white : .gray)
                    .padding(.horizontal, 20)
            }

            if isSelected {
                if text == "Written" {
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(.gray)
                } else {
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(.white)
                }
                
            } else {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(.clear)
            }
        }
        .frame(width: 100, height: 50)
    }
}
