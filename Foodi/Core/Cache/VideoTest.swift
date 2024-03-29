//
//  VideoTest.swift
//  Foodi
//
//  Created by Jack Robinson on 3/15/24.
//

import SwiftUI
import AVFoundation

struct VideoTest: View {
    @State private var videoURL = URL(string: "https://firebasestorage.googleapis.com:443/v0/b/foodi-v1-e989b.appspot.com/o/post_videos%2F1E03B7E6-4C08-4867-B3DF-728E111D6927?alt=media&token=8cdc8b86-407e-463a-8254-98989e08810a")!
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
                
            /*
            Button{coordinator.configurePlayer(url: videoURL, fileExtension: fileExtension)
                videoReady.toggle()
                } label: {Text("Testing")}
            Button{coordinator.configurePlayer(url: videoURLs[0], fileExtension: fileExtension)
                
                } label: {Text("Testing2")} */
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

