//
//  VideoPlayerView.swift
//  Foodi
//
//  Created by Jack Robinson on 3/21/24.
//

import Foundation
import AVFoundation
import SwiftUI
import AVKit
import CachingPlayerItem
struct VideoPlayerView: UIViewControllerRepresentable {
    @StateObject var coordinator: VideoPlayerCoordinator
    var videoGravity: AVLayerVideoGravity
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerVC = AVPlayerViewController()
        playerVC.player = coordinator.player
        playerVC.delegate = context.coordinator
        playerVC.showsPlaybackControls = false
        playerVC.exitsFullScreenWhenPlaybackEnds = true
        playerVC.allowsPictureInPicturePlayback = true
        playerVC.videoGravity = videoGravity
        playerVC.allowsVideoFrameAnalysis = false
        return playerVC
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update logic here if needed
    }
    
    func makeCoordinator() -> VideoPlayerCoordinator {
        return coordinator
    }
}

class VideoPlayerCoordinator: NSObject, AVPlayerViewControllerDelegate, ObservableObject, CachingPlayerItemDelegate {
    var debouncer = Debouncer(delay: 0.3)
    @Published var player = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private var playerItem: CachingPlayerItem?
    @State var configured = false
    @State var currentUrl: URL?
    @State var currentPostId: String?
    private var retries: Int = 0
    private var playerTimeObserver: PlayerTimeObserver?
    private var cancellables = Set<AnyCancellable>()
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    var isInUse = false
    @State var readyToPlay = true
    @State var prefetching = false

    func resetPlayer() {
        player.pause()
        player.removeAllItems()
        player.replaceCurrentItem(with: nil)
        playerItem = nil
        isInUse = false
        readyToPlay = false
        configured = false
    }
    
    func configurePlayer(url: URL?, postId: String) {
        print("Running Configure Player")
        guard !configured else {
            print("Player is already configured.")
            return
        }
        
        currentUrl = url
        currentPostId = postId
        resetPlayer()
        
        guard let url = url else {
            print("URL Error")
            return
        }
        
        var saveFilePath = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        saveFilePath.appendPathComponent(postId)
        saveFilePath.appendPathExtension("mp4")
        
        if FileManager.default.fileExists(atPath: saveFilePath.path) && readyToPlay {
            print("Using existing cached item.")
            playerItem = CachingPlayerItem(filePathURL: saveFilePath)
        } else {
            print("Creating new player item.")
            playerItem = CachingPlayerItem(url: url, saveFilePath: saveFilePath.path, customFileExtension: "mp4")
        }
        
        if let playerItem = self.playerItem {
            player.replaceCurrentItem(with: playerItem)
            playerItem.delegate = self
            player.automaticallyWaitsToMinimizeStalling = false
            looper = AVPlayerLooper(player: player, templateItem: playerItem)
            configured = true
        }
        setupTimeObserver()
    }

    func prefetch(url: URL?, postId: String) {
        prefetching = true
        
        guard let url = url else {
            print("URL Error")
            return
        }
        currentUrl = url
        currentPostId = postId
        var saveFilePath = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        saveFilePath.appendPathComponent(postId)
        saveFilePath.appendPathExtension("mp4")
        
        if FileManager.default.fileExists(atPath: saveFilePath.path) {
            return
        }
        
        let prefetchedPlayerItem = CachingPlayerItem(url: url, saveFilePath: saveFilePath.path, customFileExtension: "mp4")
        let tempPlayer = AVQueuePlayer()
        tempPlayer.replaceCurrentItem(with: prefetchedPlayerItem)
        prefetchedPlayerItem.download()
    }
    
    func seekToTime(seconds: Double) {
        let seekTime = CMTime(seconds: seconds, preferredTimescale: 1)
        player.seek(to: seekTime) { completed in
            if completed {
                print("Successfully seeked to \(seconds) seconds.")
            }
        }
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func replay() {
        player.seek(to: .zero)
        play()
    }
    
    func playerItemReadyToPlay(_ playerItem: CachingPlayerItem) {
        print("Caching player item ready to play.")
        readyToPlay = true
    }
    
    func playerItemDidFailToPlay(_ playerItem: CachingPlayerItem, withError error: Error?) {
        if let postId = currentPostId, let url = currentUrl, retries <= 10 {
            debouncer.schedule {
                self.configured = false
                self.configurePlayer(url: url, postId: postId)
                self.retries += 1
            }
        }
    }
    
    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
        print("Not enough data for playback. Probably because of the poor network. Wait a bit and try to play later.")
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingFileAt filePath: String) {
        print("Caching player item file downloaded.", filePath)
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
        print("Caching player item file download failed with error: \(error.localizedDescription).")
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
        // Handle download progress if needed
    }
    
    func setupTimeObserver() {
        playerTimeObserver = PlayerTimeObserver(player: player)
        playerTimeObserver?.publisher
            .sink { [weak self] time in
                self?.handleTimeUpdate(time: time)
            }
            .store(in: &cancellables)
    }
    
    func handleTimeUpdate(time: TimeInterval) {
        self.currentTime = time
        if let currentItem = player.currentItem {
            self.duration = CMTimeGetSeconds(currentItem.duration)
        }
    }
}

import Combine

class PlayerTimeObserver {
    let publisher = PassthroughSubject<TimeInterval, Never>()
    private var timeObservation: Any?
    private weak var player: AVPlayer?
    
    init(player: AVPlayer) {
        self.player = player
        // Periodically observe the player's current time, whilst playing
        timeObservation = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: nil) { [weak self] time in
            guard let self = self else { return }
            // Publish the new player time
            self.publisher.send(time.seconds)
        }
    }
    
    deinit {
        if let player = player, let timeObservation = timeObservation {
            player.removeTimeObserver(timeObservation)
        }
    }
}
