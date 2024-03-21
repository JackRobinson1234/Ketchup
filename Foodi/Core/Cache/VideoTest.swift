//
//  VideoTest.swift
//  Foodi
//
//  Created by Jack Robinson on 3/15/24.
//

import SwiftUI
import AVFoundation

struct VideoTest: View {
    @State private var videoURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!
    @State private var fileExtension = "mp4"
    private let videoURLs = [
            URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!,
            URL(string: "https://example.com/video2.mp4")!
        ]
    @StateObject private var coordinator = VideoPlayerCoordinator()
    @State private var isPlaying = false
    @State private var videoReady = false
    var body: some View {
        VStack {
            if videoReady{
                VideoPlayerView(coordinator: coordinator)
                }
                
            
            Button{coordinator.configurePlayer(url: videoURL, fileExtension: fileExtension)
                videoReady.toggle()
                } label: {Text("Testing")}
        }
        .onTapGesture {
            print("touched")
                            isPlaying.toggle()
                            if isPlaying {
                                coordinator.play()
                            } else {
                                coordinator.pause()
                            }
                        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        VideoTest()
    }
}

