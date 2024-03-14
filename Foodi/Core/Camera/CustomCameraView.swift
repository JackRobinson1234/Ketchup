//
//  CustomCameraView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 3/10/24.
//

import SwiftUI

struct CustomCameraView: View {
    
    @StateObject private var cameraViewModel = CameraViewModel()
    @Binding var tabIndex: Int
    @State private var isImageCaptured = false
    @Binding var visibility: Visibility

    @Environment(\.presentationMode) private var presentationMode
    
    
    init(tabIndex: Binding<Int>, visibility: Binding<Visibility>){
        self._tabIndex = tabIndex
        self._visibility = visibility
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CameraView(cameraService: cameraViewModel.cameraService) { result in
                    switch result {
                    case .success(let photo):
                        if let data = photo.fileDataRepresentation() {
                            cameraViewModel.capturedImage = UIImage(data: data)
                            isImageCaptured = true
                        } else {
                            print("Error: No image data found")
                        }
                    case .failure(let err):
                        print(err.localizedDescription)
                    }
                }
                .ignoresSafeArea()
                
                NavigationLink(destination: ImageEditView(image: cameraViewModel.capturedImage), isActive: $isImageCaptured) {
                    EmptyView()
                }
                
                VStack {
                    HStack {
                        Button {
                            tabIndex = 0
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                            
                        }
                        Spacer()
                    }
                    .padding(.leading)
                    Spacer()
                }
                
                
                
                VStack {
                    Spacer()
                    Button(action: {
                        cameraViewModel.cameraService.ourCapturePhoto()
                    }, label: {
                        Image(systemName: "circle")
                            .font(.system(size: 72))
                            .foregroundColor(.white)
                    })
                    .padding(.bottom)
                }
            }
        }
        .onAppear {
            visibility = .hidden // Hide toolbar when view appears
        }
        .onDisappear {
            visibility = .visible // Show toolbar when view disappears
        }
    }
}
