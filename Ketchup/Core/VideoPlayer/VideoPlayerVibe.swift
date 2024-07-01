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
class VideoPrefetcher {
    static let shared = VideoPrefetcher()
    private var preloadedPlayerItems: NSCache<NSString, VideoPlayerCoordinator> = NSCache()
    private let queue = DispatchQueue(label: "video.prefetcher.queue", attributes: .concurrent)

    private init() {}

    func getPlayerItem(for post: Post) -> VideoPlayerCoordinator {
        if let existingCoordinator = preloadedPlayerItems.object(forKey: post.id as NSString) {
            return existingCoordinator
        } else {
            let newCoordinator = VideoPlayerCoordinator()
            preloadedPlayerItems.setObject(newCoordinator, forKey: post.id as NSString)
            
            // Start prefetching for the new coordinator
            if let url = post.mediaUrls.first, let videoURL = URL(string: url) {
                newCoordinator.prefetch(url: videoURL, postId: post.id) {
                    // Prefetch completed
                }
            }
            
            return newCoordinator
        }
    }
    
    func prefetchPosts(_ posts: [Post]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            for post in posts {
                if self.preloadedPlayerItems.object(forKey: post.id as NSString) == nil {
                    self.preparePost(for: post)
                }
            }
        }
    }
    
    private func preparePost(for post: Post) {
        let coordinator = VideoPlayerCoordinator()
        if let url = post.mediaUrls.first, let videoURL = URL(string: url) {
            coordinator.prefetch(url: videoURL, postId: post.id) { [weak self] in
                self?.preloadedPlayerItems.setObject(coordinator, forKey: post.id as NSString)
            }
        }
    }
}

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
    private var configured = false
    private var currentUrl: URL?
    private var currentPostId: String?
    private var retries: Int = 0
    private var playerTimeObserver: PlayerTimeObserver?
    private var cancellables = Set<AnyCancellable>()
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    var isInUse = false
    @State var readyToPlay = true
    @State var prefetching = false

    func resetPlayer() {
        print("Resetting player")
        player.pause()
        player.removeAllItems()
        player.replaceCurrentItem(with: nil)
        playerItem = nil
        isInUse = false
        readyToPlay = false
        configured = false
    }
    
    func newConfigurePlayer(item: CachingPlayerItem) {
        item.delegate = self
    }
    
    func configurePlayer() {
        if configured {
            print("Player is already configured for this post.")
            return
        }
        
        configured = true

        if let playerItem = self.playerItem {
            player.replaceCurrentItem(with: playerItem)
            player.automaticallyWaitsToMinimizeStalling = false
            looper = AVPlayerLooper(player: player, templateItem: playerItem)
            configured = true
        } else {
            print("Error: Failed to create player item.")
        }
        
        setupTimeObserver()
    }
    
    func prefetch(url: URL?, postId: String, completion: @escaping () -> Void) {
        if prefetching {
            print("Already prefetching")
            completion()
            return
        }
        prefetching = true
        
        guard let url = url else {
            print("URL Error")
            prefetching = false
            completion()
            return
        }

        currentUrl = url
        currentPostId = postId
        
        do {
            var saveFilePath = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            saveFilePath.appendPathComponent(postId)
            saveFilePath.appendPathExtension("mp4")
            
            if FileManager.default.fileExists(atPath: saveFilePath.path) {
                playerItem = CachingPlayerItem(filePathURL: saveFilePath)
                playerItem?.delegate = self
                player.replaceCurrentItem(with: playerItem)
            } else {
                playerItem = CachingPlayerItem(url: url, saveFilePath: saveFilePath.path, customFileExtension: "mp4")
                playerItem?.delegate = self
                playerItem?.download()
                player.replaceCurrentItem(with: playerItem)
            }
            configurePlayer()
            completion()
        } catch {
            print("File path error: \(error)")
            prefetching = false
            completion()
        }
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
        print("**************************ERROR*************************")
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
        timeObservation = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: nil) { [weak self] time in
            guard let self = self else { return }
            self.publisher.send(time.seconds)
        }
    }
    
    deinit {
        if let player = player, let timeObservation = timeObservation {
            player.removeTimeObserver(timeObservation)
        }
    }
}
