//
//  VideoTest.swift
//  Foodi
//
//  Created by Jack Robinson on 3/30/24.
//

import SwiftUI

struct VideoTest: View {
    @State var configured: Bool = false
    var coordinator: VideoPlayerCoordinator = VideoPlayerCoordinator()
    var body: some View {
        if configured {
            VideoPlayerView(coordinator: coordinator, videoGravity: .resizeAspectFill)
                .onTapGesture {
                    if let player = coordinator.videoPlayerManager.queuePlayer{
                        switch player.timeControlStatus {
                        case .paused:
                            Task{await coordinator.play()}
                        case .waitingToPlayAtSpecifiedRate:
                            break
                        case .playing:
                            Task{ await coordinator.pause()}
                        @unknown default:
                            break
                        }
                    }
                }
        }
        Button{
            Task{
                await coordinator.downloadToCache(url: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"), fileExtension: "mp4")
                
            }
        } label: {
            Text("Testing")
        }
        Button{
            Task{
                await coordinator.configurePlayer(url: URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"), fileExtension: "mp4")
                
            }
        } label: {
            Text("Testing")
        }
        Button{
            Task{
                self.configured.toggle()
            }
        } label: {
            Text("PlayVideo")
        }
        
        
        Text("hello")
    }
}


#Preview {
    VideoTest()
}
