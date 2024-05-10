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
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerVC = AVPlayerViewController()
        playerVC.player = coordinator.player
        playerVC.delegate = context.coordinator
        playerVC.showsPlaybackControls = false
        playerVC.exitsFullScreenWhenPlaybackEnds = true
        playerVC.allowsPictureInPicturePlayback = true
        playerVC.videoGravity = .resizeAspectFill
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
    @Published var player = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    var filePath: String?
    var playerItem: CachingPlayerItem?
    private var configured = false
    private var prefetched = false
    private var currentUrl: URL?
    private var currentPostId: String?
    
    func configurePlayer(url: URL?, postId: String)  {
        if !player.items().isEmpty {
            player.removeAllItems()
            print("removed all items")
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
            print("Item exists")
        } else {
            print("Creating Item")
            playerItem = CachingPlayerItem(url: url, saveFilePath: saveFilePath.path, customFileExtension: "mp4")
        }
        if let playerItem = self.playerItem {
                // Check if the player already has an item
                if player.items().isEmpty {
                    // If the player has no item, set the new item
                    player.replaceCurrentItem(with: playerItem)
                }
               
               //playerItem.delegate = self
                player.automaticallyWaitsToMinimizeStalling = false
                if let playerItem = player.currentItem {
                    looper = AVPlayerLooper(player: player, templateItem: playerItem)
                }
           }
    }
    //MARK: Prefetch
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
            print("Item exists")
            return
        }
        if !player.items().isEmpty {
            print("player isnt empty")
            print(player.items().isEmpty)
            player.removeAllItems()
            print(player.items().isEmpty)
        }
        
        currentUrl = url
        currentPostId = postId
        //print("prefetching file path", saveFilePath.path)
        let prefetchedPlayerItem = CachingPlayerItem(url: url, saveFilePath: saveFilePath.path, customFileExtension: "mp4")
            prefetchedPlayerItem.delegate = self
            // If the player has no item, set the new item
            print("replacing player with current item")
            AVQueuePlayer().replaceCurrentItem(with: prefetchedPlayerItem)
            prefetchedPlayerItem.download()
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
        print("Caching player item ready to play.")
    }
    
    func playerItemDidFailToPlay(_ playerItem: CachingPlayerItem, withError error: Error?) {
        print(error?.localizedDescription ?? "")
    }
    
    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
        print("Not enough data for playback. Probably because of the poor network. Wait a bit and try to play later.")
    }
    
    
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingFileAt filePath: String) {
        print("Caching player item file downloaded.", filePath)
        if let postId = currentPostId {
            //configurePlayer(url: currentUrl, postId: postId)
        }
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
        
        print("Caching player item file download failed with error: \(error.localizedDescription).")
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
        let downloadProgress = Float(bytesDownloaded) / Float(bytesExpected)
        //print("Download Progress: \(downloadProgress * 100)%")
    }
}




































// MARK: - AVPlayerViewControllerDelegate
















//struct VideoPlayerView: UIViewControllerRepresentable {
//    @StateObject var coordinator: VideoPlayerCoordinator
//    
//    func makeUIViewController(context: Context) -> AVPlayerViewController {
//        let playerVC = AVPlayerViewController()
//        playerVC.player = coordinator.videoPlayerManager.queuePlayer
//        playerVC.delegate = context.coordinator
//        playerVC.showsPlaybackControls = false
//        playerVC.exitsFullScreenWhenPlaybackEnds = true
//        playerVC.allowsPictureInPicturePlayback = true
//        playerVC.videoGravity = .resizeAspectFill
//        playerVC.allowsVideoFrameAnalysis = false
//        
//        return playerVC
//    }
//    
//    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
//        // Update logic here if needed
//    }
//    
//    func makeCoordinator() -> VideoPlayerCoordinator {
//        return coordinator
//    }
//   
//}
//
//class VideoPlayerCoordinator: NSObject, AVPlayerViewControllerDelegate, ObservableObject {
//    var videoPlayerManager = VideoPlayerManager()
//    @Published var shouldReplay = false
//    
//    func downloadToCache(url: URL?, fileExtension: String?) async {
//        await videoPlayerManager.downloadToCache(url: url, fileExtension: fileExtension)
//    }
//    
//    func configurePlayer(url: URL?, fileExtension: String?) async {
//        await videoPlayerManager.configure(url: url, fileExtension: fileExtension)
//    }
//    
//    func play() async {
//        await videoPlayerManager.play()
//    }
//    
//    func pause() async {
//        await videoPlayerManager.pause()
//    }
//    
//    func replay() async {
//        await videoPlayerManager.replay()
//    }
//    
//    func cancelLoading() async {
//        videoPlayerManager.cancelAllLoadingRequest()
//    }
//    
//}
//
//class VideoPlayerManager: NSObject {
//    // MARK: - Variables
//    var videoURL: URL?
//    var originalURL: URL?
//    var asset: AVURLAsset?
//    var playerItem: AVPlayerItem?
//    var queuePlayer: AVQueuePlayer?
//    var observer: NSKeyValueObservation?
//    var playerLooper: AVPlayerLooper!
//    private var session: URLSession?
//    private var loadingRequests = [AVAssetResourceLoadingRequest]()
//    private var task: URLSessionDataTask?
//    private var infoResponse: URLResponse?
//    private var cancelLoadingQueue: DispatchQueue?
//    private var videoData: Data?
//    private var fileExtension: String?
//    
//    // MARK: - Initializers
//    override init() {
//            super.init()
//            setupView()
//        }
//    
//    deinit {
//        removeObserver()
//    }
//    
//    
//    
//    func setupView(){
//        let operationQueue = OperationQueue()
//        operationQueue.name = "com.VideoPlayer.URLSession"
//        operationQueue.maxConcurrentOperationCount = 1
//        session = URLSession.init(configuration: .default, delegate: self, delegateQueue: operationQueue)
//        cancelLoadingQueue = DispatchQueue.init(label: "com.cancelLoadingQueue")
//        videoData = Data()
//    }
//    
//    func downloadToCache(url: URL?, fileExtension: String?) async {
//        guard let url = url else {
//            print("URL Error from Cell")
//            return
//        }
//        VideoCacheManager.shared.queryURLFromCache(key: url.absoluteString, fileExtension: fileExtension, completion: {[weak self] (data) in
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                if let path = data as? String {
//                    self.videoURL = URL(fileURLWithPath: path)
//                } else {
//                    // Adding Redirect URL(customized prefix schema) to trigger AVAssetResourceLoaderDelegate
//                    let downloadTask = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
//                           // Handle download completion
//                           guard let data = data, error == nil else {
//                               print("Error downloading video:", error?.localizedDescription ?? "Unknown error")
//                               return
//                           }
//                           // Save the downloaded data to cache
//                           VideoCacheManager.shared.storeDataToCache(data: data, key: url.absoluteString, fileExtension: fileExtension)
//                           // Update videoURL and asset properties
//                           self?.videoURL = url
//                           self?.asset = AVURLAsset(url: url)
//                           // Handle asset setup after download
//                       }
//                       downloadTask.resume()
//                   }
//                
//            }
//        }
//        )
//    }
//
//    func configure(url: URL?, fileExtension: String?) async {
//        guard let url = url else {
//            print("URL Error from Tableview Cell")
//            return
//        }
//        self.fileExtension = fileExtension
//        VideoCacheManager.shared.queryURLFromCache(key: url.absoluteString, fileExtension: fileExtension, completion: {[weak self] (data) in
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                if let path = data as? String {
//                    self.videoURL = URL(fileURLWithPath: path)
//                    self.asset = AVURLAsset(url: self.videoURL!)
//                } else {
//                    // Adding Redirect URL(customized prefix schema) to trigger AVAssetResourceLoaderDelegate
//                    self.asset = AVURLAsset(url: url)
//                    }
//                self.playerItem = AVPlayerItem(asset: self.asset!)
//                self.addObserverToPlayerItem()
//                
//                if let queuePlayer = self.queuePlayer {
//                    queuePlayer.replaceCurrentItem(with: self.playerItem)
//                } else {
//                    self.queuePlayer = AVQueuePlayer(playerItem: self.playerItem)
//                }
//                self.playerLooper = AVPlayerLooper(player: self.queuePlayer!, templateItem: self.queuePlayer!.currentItem!)
//            }
//        })
//    }
//                                                   
//    
//    /// Clear all remote or local request
//    func cancelAllLoadingRequest(){
//        removeObserver()
//        playerLooper = nil
//        videoURL = nil
//        originalURL = nil
//        asset = nil
//        playerItem = nil
//        
//        
//        cancelLoadingQueue?.async { [weak self] in
//            self?.session?.invalidateAndCancel()
//            self?.session = nil
//            
//            self?.asset?.cancelLoading()
//            self?.task?.cancel()
//            self?.task = nil
//            self?.videoData = nil
//            
//            self?.loadingRequests.forEach { $0.finishLoading() }
//            self?.loadingRequests.removeAll()
//        }
//
//    }
//    
//    
//    func replay() async {
//        await self.queuePlayer?.seek(to: .zero)
//        await play()
//    }
//    
//    func play() async {
//        self.queuePlayer?.play()
//    }
//    
//    func pause() async {
//        self.queuePlayer?.pause()
//    }
//    
//}
//
//// MARK: - KVO
//extension VideoPlayerManager {
//    func removeObserver() {
//        if let observer = observer {
//            observer.invalidate()
//        }
//    }
//    
//    fileprivate func addObserverToPlayerItem() {
//        // Register as an observer of the player item's status property
//        self.observer = self.playerItem!.observe(\.status, options: [.initial, .new], changeHandler: { item, _ in
//            /*let status = item.status
//            // Switch over the status
//            switch status {
//            case .readyToPlay:
//                // Player item is ready to play.
//                print("Status: readyToPlay")
//            case .failed:
//                // Player item failed. See error.
//                print("Status: failed Error: " + item.error!.localizedDescription )
//            case .unknown:
//                // Player item is not yet ready
//                print("Status: unknown")
//            @unknown default:
//                fatalError("Status is not yet ready to present")
//            }*/
//        })
//    }
//
//    
//    
//}
//
//// MARK: - URL Session Delegate
//extension VideoPlayerManager: URLSessionTaskDelegate, URLSessionDataDelegate {
//    // Get Responses From URL Request
//    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
//        print("firebase Received response:", response)
//        self.infoResponse = response
//        self.processLoadingRequest()
//        completionHandler(.allow)
//    }
//    
//    // Receive Data From Responses and Download
//    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
//        print("firebase Received data of size:", data.count)
//        self.videoData?.append(data)
//        self.processLoadingRequest()
//    }
//    
//    // Responses Download Completed
//    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        if let error = error {
//            print("AVURLAsset Download Data Error: " + error.localizedDescription)
//        } else {
//            //print("firebase Task completed successfully.")
//            VideoCacheManager.shared.storeDataToCache(data: self.videoData, key: self.originalURL!.absoluteString, fileExtension: self.fileExtension)
//        }
//    }
//    
//    private func processLoadingRequest(){
//        //print("firebase Should wait for loading request:", self.loadingRequests)
//        var finishedRequests = Set<AVAssetResourceLoadingRequest>()
//        self.loadingRequests.forEach {
//            var request = $0
//            if self.isInfo(request: request), let response = self.infoResponse {
//                self.fillInfoRequest(request: &request, response: response)
//            }
//            if let dataRequest = request.dataRequest, self.checkAndRespond(forRequest: dataRequest) {
//                finishedRequests.insert(request)
//                request.finishLoading()
//            }
//        }
//        self.loadingRequests = self.loadingRequests.filter { !finishedRequests.contains($0) }
//    }
//    
//    private func fillInfoRequest(request: inout AVAssetResourceLoadingRequest, response: URLResponse) {
//        request.contentInformationRequest?.isByteRangeAccessSupported = true
//        request.contentInformationRequest?.contentType = response.mimeType
//        request.contentInformationRequest?.contentLength = response.expectedContentLength
//    }
//    
//    private func isInfo(request: AVAssetResourceLoadingRequest) -> Bool {
//         return request.contentInformationRequest != nil
//     }
//    
//    private func checkAndRespond(forRequest dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
//        guard let videoData = videoData else { return false }
//        let downloadedData = videoData
//        let downloadedDataLength = Int64(downloadedData.count)
//
//        let requestRequestedOffset = dataRequest.requestedOffset
//        let requestRequestedLength = Int64(dataRequest.requestedLength)
//        let requestCurrentOffset = dataRequest.currentOffset
//
//        if downloadedDataLength < requestCurrentOffset {
//            return false
//        }
//
//        let downloadedUnreadDataLength = downloadedDataLength - requestCurrentOffset
//        let requestUnreadDataLength = requestRequestedOffset + requestRequestedLength - requestCurrentOffset
//        let respondDataLength = min(requestUnreadDataLength, downloadedUnreadDataLength)
//
//        dataRequest.respond(with: downloadedData.subdata(in: Range(NSMakeRange(Int(requestCurrentOffset), Int(respondDataLength)))!))
//
//        let requestEndOffset = requestRequestedOffset + requestRequestedLength
//
//        return requestCurrentOffset >= requestEndOffset
//
//    }
//}
//
//// MARK: - AVAssetResourceLoader Delegate
//extension VideoPlayerManager: AVAssetResourceLoaderDelegate {
//    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
//        print("Should wait for loading of requested resource:", loadingRequest)
//        if task == nil, let url = originalURL {
//            print("Creating data task for URL:", url)
//            let request = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
//            task = session?.dataTask(with: request)
//            task?.resume()
//        }
//        self.loadingRequests.append(loadingRequest)
//        return true
//    }
//
//    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
//        if let index = self.loadingRequests.firstIndex(of: loadingRequest) {
//            self.loadingRequests.remove(at: index)
//        }
//    }
//}
//
//extension URL {
//    /// Adds the scheme prefix to a copy of the receiver.
//    func convertToRedirectURL(scheme: String) -> URL? {
//        var components = URLComponents.init(url: self, resolvingAgainstBaseURL: false)
//        let schemeCopy = components?.scheme ?? ""
//        components?.scheme = schemeCopy + scheme
//        return components?.url
//    }
//    
//    /// Removes the scheme prefix from a copy of the receiver.
//    func convertFromRedirectURL(prefix: String) -> URL? {
//        guard var comps = URLComponents(url: self, resolvingAgainstBaseURL: false) else {return nil}
//        guard let scheme = comps.scheme else {return nil}
//        comps.scheme = scheme.replacingOccurrences(of: prefix, with: "")
//        return comps.url
//    }
//}
