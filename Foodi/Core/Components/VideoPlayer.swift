//
//  VideoPlayer.swift
//  Foodi
//
//  Created by Jack Robinson on 5/10/24.
//
import Foundation
import SwiftUI
import AVKit

struct VideoPlayer: UIViewControllerRepresentable {
    var player: AVPlayer
    var videoGravity: AVLayerVideoGravity
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.exitsFullScreenWhenPlaybackEnds = true
        controller.allowsPictureInPicturePlayback = true
        controller.videoGravity = videoGravity
        controller.allowsVideoFrameAnalysis = false// makes video full screen
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
