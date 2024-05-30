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

class VideoPlayerCoordinator: NSObject, AVPlayerViewControllerDelegate, ObservableObject,  CachingPlayerItemDelegate {
    var debouncer = Debouncer(delay: 0.3)
    @Published var player = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    var filePath: String?
    var playerItem: CachingPlayerItem?
    private var configured = false
    private var prefetched = false
    private var currentUrl: URL?
    private var currentPostId: String?
    private var retries: Int = 0
    private var playerTimeObserver: PlayerTimeObserver?
    private var cancellables = Set<AnyCancellable>()
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    
    
    
    //MARK: configurePlayer
    /// Clears the player as a safety to prevent crash. if theres already an item, return to make it more effecient. Then check the cache to see if the current video exists. If it does, make a new item out of that which should load fast. Or make a new cacheplayeritem, then put that into the player.
    /// - Parameters:
    ///   - url: url to be configured
    ///   - postId: postId where the cached video can be found (same as prefetch)
    func configurePlayer(url: URL?, postId: String)  {
        currentUrl = url
        currentPostId = postId
        if !player.items().isEmpty {
            player.removeAllItems()
            //print("removed all items")
        }
        guard let url = url else {
            print("URL Error")
            return
        }
        var saveFilePath = try! FileManager.default.url(for: .cachesDirectory,
                                                        in: .userDomainMask,
                                                        appropriateFor: nil,
                                                        create: true)
        saveFilePath.appendPathComponent(postId)
        saveFilePath.appendPathExtension("mp4")
        //print("Configure file path", saveFilePath.path)
        if FileManager.default.fileExists(atPath: saveFilePath.path) {
            playerItem = CachingPlayerItem(filePathURL: saveFilePath)
            //print("Item exists")
        } else {
            //print("Creating Item")
            playerItem = CachingPlayerItem(url: url, saveFilePath: saveFilePath.path, customFileExtension: "mp4")
        }
        if let playerItem = self.playerItem {
            // Check if the player already has an item
            if player.items().isEmpty {
                // If the player has no item, set the new item
                player.replaceCurrentItem(with: playerItem)
            }
            playerItem.delegate = self
            player.automaticallyWaitsToMinimizeStalling = false
            if let playerItem = player.currentItem {
                looper = AVPlayerLooper(player: player, templateItem: playerItem)
            }
        }
        setupTimeObserver()
    }
    //MARK: Prefetch
    /// downloads the given document and post ID to the cache at the savefilepath.  Needs to pass through an AVQueueplayer because thats the only way that i could trigger the download.
    /// - Parameters:
    ///   - url: url of the video to be prefetched
    ///   - postId: postId that is used as the cache storer identifier
    func prefetch(url: URL?, postId: String) {
        
        guard let url = url else {
            print("URL Error")
            return
        }
        var saveFilePath = try! FileManager.default.url(for: .cachesDirectory,
                                                        in: .userDomainMask,
                                                        appropriateFor: nil,
                                                        create: true)
        saveFilePath.appendPathComponent(postId)
        saveFilePath.appendPathExtension("mp4")
        if FileManager.default.fileExists(atPath: saveFilePath.path) {
            //print("Item exists")
            return
        }
        if !player.items().isEmpty {
            //print("player isnt empty")
            print(player.items().isEmpty)
            player.removeAllItems()
            print(player.items().isEmpty)
        }
        
        currentUrl = url
        currentPostId = postId
        let prefetchedPlayerItem = CachingPlayerItem(url: url, saveFilePath: saveFilePath.path, customFileExtension: "mp4")
        // If the player has no item, set the new item
        //print("replacing player with current item")
        AVQueuePlayer().replaceCurrentItem(with: prefetchedPlayerItem)
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
    
    func pause()  {
        player.pause()
    }
    
    func replay() {
        player.seek(to: .zero)
        play()
    }
    func playerItemReadyToPlay(_ playerItem: CachingPlayerItem) {
        //print("Caching player item ready to play.")
    }
    
    func playerItemDidFailToPlay(_ playerItem: CachingPlayerItem, withError error: Error?) {
        //print(error?.localizedDescription ?? "")
        if let postId = currentPostId, let url = currentUrl, self.retries <= 10 {
            debouncer.schedule{
                self.configurePlayer(url: url, postId: postId)
                self.retries += 1
                //print("***************** retrying *********************")
            }
        }
    }
    
    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
       // print("Not enough data for playback. Probably because of the poor network. Wait a bit and try to play later.")
    }
    
    
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingFileAt filePath: String) {
        //print("Caching player item file downloaded.", filePath)
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
        //print("Caching player item file download failed with error: \(error.localizedDescription).")
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
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
        //print("Current time: \(time) seconds")
        self.currentTime = time
        if let currentItem = player.currentItem {
            self.duration = CMTimeGetSeconds(currentItem.duration)
            print("Duration: \(duration) seconds")
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
