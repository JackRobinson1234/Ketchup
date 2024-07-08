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
        ZStack {
            VStack {
                HStack {
                    Button {
                        cameraViewModel.clearPics()
                        cameraViewModel.mediaType = .video
                    } label: {
                        Image(systemName: "xmark")
                            .font(.custom("MuseoSansRounded-300", size: 20))
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
                        VStack{
                            if cameraViewModel.images.count > 0 {
                                Text("Edit")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundColor(.white)
                                
                            }
                        }
                        Text("\(cameraViewModel.images.count)/5")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    Image(systemName: "xmark")
                        .font(.custom("MuseoSansRounded-300", size: 20))
                        .foregroundColor(.white)
                        .padding(.trailing)
                        .opacity(0)
                }
                
                Spacer()
                
                HStack(spacing: 30) {
                    Button {
                        cameraViewModel.clearLatestPic()
                    } label: {
                        VStack{
                            Image(systemName: "delete.left")
                                .resizable()
                                .foregroundStyle(.white)
                                .scaledToFit()
                                .frame(height: 35)
                                
                        }
                        .frame(width: 100, height: 50)
                        
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
                            cameraViewModel.mediaType = .photo
                            uploadViewModel.images = cameraViewModel.images
                            uploadViewModel.mediaType = .photo
                        }
                    } label: {
                        Group{
                            Label {
                                Image(systemName: "chevron.right")
                                    .font(.callout)
                            } icon: {
                                Text("Next")
                                    .font(.custom("MuseoSansRounded-500", size: 18))
                                    .foregroundStyle(.black)
                                
                            }
                        }
                        .frame(width: 70, height: 30)
                        .padding(.horizontal,5)
                        .padding(.vertical,3)
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
        .onChange(of: cameraViewModel.images.count) { count in
            maxPhotosReached = count >= 5
        }
        .sheet(isPresented: $showReorderView) {
            PhotoReorderView(cameraViewModel: cameraViewModel)
        }
    }
}


