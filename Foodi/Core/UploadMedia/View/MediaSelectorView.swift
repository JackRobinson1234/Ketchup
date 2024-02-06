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
        self._viewModel = StateObject(wrappedValue: UploadPostViewModel(service: UploadPostService()))
    }
        var body: some View {
            //NavigationStack {
            VStack {
                Text("Hello")
                if let movie = viewModel.mediaPreview {
                    VideoPlayer(player: player)
                        .onAppear {
                            player.replaceCurrentItem(with: AVPlayerItem(url: movie.url))
                            player.play()
                            print("VideoPlayer appeared")
                        }
                        .onDisappear { player.pause()
                            print("VideoPlayer disappeared")
                        }
                        .padding()
                   
                }
            }
            .onAppear {
                if viewModel.selectedMediaForUpload == nil { showImagePicker.toggle() }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        player.pause()
                        player = AVPlayer(playerItem: nil)
                        viewModel.reset()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Next") {
                        viewModel.setMediaItemForUpload()
                    }
                    .disabled(viewModel.mediaPreview == nil)
                    .font(.headline)
                }
            }
            .navigationBarBackButtonHidden()
            .navigationDestination(item: $viewModel.selectedMediaForUpload, destination: { movie in
                UploadPostView(movie: movie, viewModel: viewModel, tabIndex: $tabIndex, restaurant: restaurant)
            })
            .photosPicker(isPresented: $showImagePicker, selection: $viewModel.selectedItem, matching: .videos)
            .toolbar(.hidden, for: .tabBar)
        }
    }
//}

#Preview {
    MediaSelectorView(tabIndex: .constant(0), restaurant: DeveloperPreview.restaurants[0])
}
