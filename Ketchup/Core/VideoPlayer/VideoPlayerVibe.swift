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
class CoordinatorWrapper: NSObject {
    var coordinators: [String: VideoPlayerCoordinator]
    
    init(coordinators: [String: VideoPlayerCoordinator] = [:]) {
        self.coordinators = coordinators
    }
}

class VideoPrefetcher {
    static let shared = VideoPrefetcher()
     private var preloadedPlayerItems: NSCache<NSString, VideoPlayerCoordinator> = NSCache()
     private var prefetchingStatus: [String: Bool] = [:]
     private let queue = DispatchQueue(label: "video.prefetcher.queue", attributes: .concurrent)
     private let semaphore = DispatchSemaphore(value: 3) 
    private init() {}

    func getPlayerItems(for post: Post) -> [(String, VideoPlayerCoordinator)] {
            var result: [(String, VideoPlayerCoordinator)] = []

            if let mixedMediaUrls = post.mixedMediaUrls {
                for mediaItem in mixedMediaUrls where mediaItem.type == .video {
                    let coordinator = getOrCreateCoordinator(for: mediaItem, postId: post.id)
                    result.append((mediaItem.id, coordinator))
                }
            } else if post.mediaType == .video, let url = post.mediaUrls.first {
                let coordinator = getOrCreateCoordinator(for: MixedMediaItem(id: "default", url: url, type: .video), postId: post.id)
                result.append(("default", coordinator))
            }

            return result
        }
    
    private func getOrCreateCoordinator(for mediaItem: MixedMediaItem, postId: String) -> VideoPlayerCoordinator {
            let key = mediaItem.id as NSString

            if let existingCoordinator = preloadedPlayerItems.object(forKey: key) {
                return existingCoordinator
            } else {
                let newCoordinator = VideoPlayerCoordinator()
                preloadedPlayerItems.setObject(newCoordinator, forKey: key)

                if prefetchingStatus[mediaItem.id] == true {
                    // Video is currently being prefetched
                    newCoordinator.prefetching = true
                } else if prefetchingStatus[mediaItem.id] == nil {
                    // Video hasn't been prefetched yet, start prefetching
                    prefetchingStatus[mediaItem.id] = true
                    prefetch(url: URL(string: mediaItem.url), mediaItemId: mediaItem.id)
                }

                return newCoordinator
            }
        }
    
    func prefetchPosts(_ posts: [Post]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            for post in posts {
                self.prefetchMediaItems(for: post)
            }
        }
    }
    
    private func prefetchMediaItems(for post: Post) {
        if let mixedMediaUrls = post.mixedMediaUrls {
            for mediaItem in mixedMediaUrls where mediaItem.type == .video {
                if preloadedPlayerItems.object(forKey: mediaItem.id as NSString) == nil {
                    prefetch(url: URL(string: mediaItem.url), mediaItemId: mediaItem.id)
                }
            }
        } else if post.mediaType == .video, let url = post.mediaUrls.first {
            let defaultMediaItem = MixedMediaItem(id: "default", url: url, type: .video)
            if preloadedPlayerItems.object(forKey: "default" as NSString) == nil {
                prefetch(url: URL(string: defaultMediaItem.url), mediaItemId: defaultMediaItem.id)
            }
        }
    }
    
    private func prefetch(url: URL?, mediaItemId: String) {
           guard let url = url else { return }

           queue.async {
               self.semaphore.wait() // Wait if there are already 3 prefetch tasks running

               Task.detached(priority: .utility) { [weak self] in
                   defer {
                       self?.semaphore.signal() // Signal semaphore after task completion
                       self?.prefetchingStatus[mediaItemId] = false
                   }

                   do {
                       var saveFilePath = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                       saveFilePath.appendPathComponent(mediaItemId)
                       saveFilePath.appendPathExtension("mp4")

                       guard let coordinator = self?.preloadedPlayerItems.object(forKey: mediaItemId as NSString) else {
                           print("Coordinator not found for mediaItemId: \(mediaItemId)")
                           return
                       }

                       if FileManager.default.fileExists(atPath: saveFilePath.path) {
                           print("Using cached file for mediaItemId: \(mediaItemId)")
                           coordinator.prefetch(url: url, mediaItemId: mediaItemId) {
                               coordinator.configurePlayer()
                           }
                       } else {
                           print("Downloading file for mediaItemId: \(mediaItemId)")
                           coordinator.prefetch(url: url, mediaItemId: mediaItemId) {
                               coordinator.configurePlayer()
                           }
                       }

                   } catch {
                       print("File path error for mediaItemId \(mediaItemId): \(error)")
                   }
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
    private var currentMediaItemId: String?
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
    
    func prefetch(url: URL?, mediaItemId: String, completion: @escaping () -> Void) {
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
        currentMediaItemId = mediaItemId
        
        do {
            var saveFilePath = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            saveFilePath.appendPathComponent(mediaItemId)
            saveFilePath.appendPathExtension("mp4")
            
            if FileManager.default.fileExists(atPath: saveFilePath.path) {
                print("Using cached file for mediaItemId: \(mediaItemId)")
                playerItem = CachingPlayerItem(filePathURL: saveFilePath)
                playerItem?.delegate = self
                player.replaceCurrentItem(with: playerItem)
            } else {
                print("Downloading file for mediaItemId: \(mediaItemId)")
                playerItem = CachingPlayerItem(url: url, saveFilePath: saveFilePath.path, customFileExtension: "mp4")
                playerItem?.delegate = self
                playerItem?.download()
                player.replaceCurrentItem(with: playerItem)
            }
            configurePlayer()
            completion()
        } catch {
            print("File path error for mediaItemId \(mediaItemId): \(error)")
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
