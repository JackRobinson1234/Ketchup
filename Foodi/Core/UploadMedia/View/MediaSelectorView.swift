//
//  MediaSelectorView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
/*
struct MediaSelectorView: View {
    @State private var player = AVPlayer()
    @StateObject var viewModel: UploadPostViewModel
    @State private var showImagePicker = false
    @Binding var tabIndex: Int
    private let restaurant: Restaurant?
    @Environment(\.dismiss) var dismiss
    @Binding var cover: Bool
    private let postType: PostType
        
    init(tabIndex: Binding<Int>, restaurant: Restaurant? = nil, cover: Binding<Bool>, postType: PostType) {
        self._cover = cover
        self._tabIndex = tabIndex
        self.restaurant = restaurant
        self._viewModel = StateObject(wrappedValue: UploadPostViewModel(service: UploadPostService(), restaurant: restaurant))
        self.postType = postType
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
            .navigationBarBackButtonHidden()
            
            // if showImagePicker is true, the photospicker appears
            //.photosPicker(isPresented: $showImagePicker, selection: $viewModel.selectedItem, matching: .videos)
            
            .onDisappear{player.pause()}
            .toolbar(.hidden, for: .tabBar)
        }
    }
/*
#Preview {
    MediaSelectorView(tabIndex: .constant(0), restaurant: DeveloperPreview.restaurants[0])
}
*/
*/
