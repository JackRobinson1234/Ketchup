//
//  CustomCameraView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 3/10/24.
//
import SwiftUI


struct CustomCameraView: View {
    
    @StateObject private var cameraViewModel = CameraViewModel()
    @Binding var selectedTab: Int
    @State private var isImageCaptured = false
    @Binding var visibility: Visibility
    @State private var selectingMedia = false
    @StateObject var viewModel: UploadPostViewModel
    @State private var capturedPhotoUrl: URL?
    @State private var navigateToCreatePostSelection = false
    
    init(selectedTab: Binding<Int>, visibility: Binding<Visibility>) {
        self._selectedTab = selectedTab
        self._visibility = visibility
        self._viewModel = StateObject(wrappedValue: UploadPostViewModel(service: UploadPostService(), restaurant: nil))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CameraView(cameraService: cameraViewModel.cameraService) { result in
                    switch result {
                    case .success(let photo):
                            if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
                                if let imageURL = cameraViewModel.saveImageToFileSystem(image) {
                                    capturedPhotoUrl = imageURL
                                    viewModel.mediaPreview = .photo(Photo(url: capturedPhotoUrl!))
                                    isImageCaptured = true
                            } else {
                                print("Error: No image data found")
                            }
                        }
                    case .failure(let err):
                        print(err.localizedDescription)
                    }
                }
                .ignoresSafeArea(.all)

                VStack {
                    HStack {
                        Button {
                            selectedTab = 0
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding([.top, .leading], 30)
            
                    Spacer()
                }
                           
                VStack {
                    Spacer()
                    HStack(spacing: 50) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                            .hidden()
                
                        Button(action: {
                            cameraViewModel.cameraService.ourCapturePhoto()
                        }, label: {
                            Image(systemName: "circle")
                                .font(.system(size: 72))
                                .foregroundColor(.white)
                        })
                        
                        Button(action: {
                            selectingMedia = true
                        }, label: {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 35))
                                .foregroundColor(.white)
                        })
                    }
                    .padding(.bottom, 15)
                }
            }
            .onAppear {
                viewModel.mediaPreview = nil
                navigateToCreatePostSelection = false
                isImageCaptured = false
            }
            
            .navigationDestination(isPresented: $isImageCaptured) {
                ImageEditView(selectedTab: $selectedTab, viewModel: viewModel)
            }
            
            .onChange(of: viewModel.selectedItem) {
                if viewModel.selectedItem != nil {
                    navigateToCreatePostSelection = true
                }
            }
            
            .navigationDestination(isPresented: $navigateToCreatePostSelection) {
                CreatePostSelection(selectedTab: $selectedTab, viewModel: viewModel)
            }
        }
        .photosPicker(isPresented: $selectingMedia, selection: $viewModel.selectedItem)
    }
}


struct CustomCameraView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock values for the bindings and other required data
        CustomCameraView(selectedTab: .constant(2), visibility: .constant(.hidden))
    }
}
