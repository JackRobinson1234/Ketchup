//
//  VideoOptimizeTest.swift
//  Foodi
//
//  Created by Jack Robinson on 5/8/24.
//

import Foundation
import Kingfisher
import AVFoundation
import CachingPlayerItem

class ViewController: UIViewController {
    // You need to keep a strong reference to your player.
    var player: AVPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "https://random-url.com/video.mp4")!
        let playerItem = CachingPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false
        player.play()
        
    }
    func prefetch(urlToPrefetch: URL) {
        // Previous image thumbnail caching logic here
        let key = urlToPrefetch.absoluteString
        if YourAppMediaCache.sharedInstance.getItem(forKey: key) == nil {
            let playerItem = CachingPlayerItem(url: urlToPrefetch)
            playerItem.download()
        }
    }
}

public class YourAppMediaCache: NSObject {
  static let sharedInstance = YourAppMediaCache()
  let memCache = NSCache<NSString, NSData>()
  public func cacheItem(_ mediaItem: Data, forKey key: String) {
    memCache.setObject(mediaItem as NSData, forKey: key as NSString)
  }
  
  public func getItem(forKey key: String) -> Data? {
    return memCache.object(forKey: key as NSString) as Data?
  }
}
