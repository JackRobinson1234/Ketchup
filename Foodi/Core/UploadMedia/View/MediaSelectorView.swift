//
//  MediaSelectorView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit

struct MediaSelectorView: View {
    @State private var player = AVPlayer()
    @StateObject var viewModel: UploadPostViewModel
    @State private var showImagePicker = false
    @Binding var tabIndex: Int
    private let restaurant: Restaurant
    @Environment(\.dismiss) var dismiss
        
    init(tabIndex: Binding<Int>, restaurant: Restaurant) {
        self._tabIndex = tabIndex
        self.restaurant = restaurant
        self._viewModel = StateObject(wrappedValue: UploadPostViewModel(service: UploadPostService(), restaurant: restaurant))
    }
        var body: some View {
            VStack {
                // If a movie is selected, creates a player for the user to preview the video
                if let movie = viewModel.mediaPreview {
                    VideoPlayer(player: player)
                        .onAppear {
                            player.replaceCurrentItem(with: AVPlayerItem(url: movie.url))
                            player.play()
                            
                            viewModel.setMediaItemForUpload()
                            
                        }
                        .onDisappear { player.pause()
                        }
                        .padding()
                }
                //loading bubble appears while the viewmodel loads the selected video
                else {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 44, height: 44)
                    } else {
                        Text("No Video Selected")
                    }
                }
                    
                    
                }
            // image chooser appears when the mediaselectorview is selected
            .onAppear {
                if viewModel.selectedMediaForUpload == nil { showImagePicker.toggle() }
            }
            
            // back button clears the viewmodel if gone back
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        player.pause()
                        player = AVPlayer(playerItem: nil)
                        viewModel.reset()
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .imageScale(.large)
                    }
                }
                // "Next" appears if a video is selected and navigates to upload post view
                if let movie = viewModel.selectedMediaForUpload {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: UploadPostView(movie: movie, viewModel: viewModel, tabIndex: $tabIndex, restaurant: restaurant)) {
                            Text("Next")
                        }
                    }
                }
                // "Select Different Video Appears" if a video is selected
                if let _ = viewModel.selectedMediaForUpload, !viewModel.isLoading {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Select Different Video") {
                            viewModel.reset()
                            showImagePicker.toggle()
                        }
                    }
                    // Select Video appears if no video is selected
                } else {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Select Video") {
                            viewModel.reset()
                            showImagePicker.toggle()
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden()
            
            // if showImagePicker is true, the photospicker appears
            .photosPicker(isPresented: $showImagePicker, selection: $viewModel.selectedItem, matching: .videos)
            
            
            .toolbar(.hidden, for: .tabBar)
        }
    }

#Preview {
    MediaSelectorView(tabIndex: .constant(0), restaurant: DeveloperPreview.restaurants[0])
}
