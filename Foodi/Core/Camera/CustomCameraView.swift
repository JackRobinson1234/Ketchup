//
//  CustomCameraView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 3/10/24.
//
import SwiftUI


struct CustomCameraView: View {
    
    @StateObject private var cameraViewModel = CameraViewModel()
    
    @EnvironmentObject var tabBarController: TabBarController

    @State private var selectingMedia = false
    @State private var capturedPhotoUrl: URL?
    @State private var navigateToCreatePostSelection =   false

    var body: some View {
        NavigationStack {
            ZStack {
                
                CameraView(viewModel: cameraViewModel)
                    .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Button {
                            tabBarController.selectedTab = 0
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
            .alert(item: $cameraViewModel.alertItem) { alertItem in
                Alert(title: Text(alertItem.title),
                      message: Text(alertItem.message),
                      dismissButton: alertItem.dismissButton)
            }
            .onAppear {
                //viewModel.mediaPreview = nil
                navigateToCreatePostSelection = false
                cameraViewModel.isImageCaptured = false
            }
            
            .navigationDestination(isPresented: $cameraViewModel.isImageCaptured) {
                ImageEditView(viewModel: cameraViewModel)
            }
            
            .onChange(of: cameraViewModel.selectedItem) {
                if cameraViewModel.selectedItem != nil {
                    navigateToCreatePostSelection = true
                }
            }
            
//            .navigationDestination(isPresented: $navigateToCreatePostSelection) {
//                CreatePostSelection(selectedTab: $selectedTab, viewModel: cameraViewModel)
//            }
        }
        .photosPicker(isPresented: $selectingMedia, selection: $cameraViewModel.selectedItem)
    }
}


struct ExitButtonView: View {
    
    @Binding var selectedTab: Int
    
    var body: some View {
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
    }
}








struct CustomCameraView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock values for the bindings and other required data
        CustomCameraView()
    }
}
