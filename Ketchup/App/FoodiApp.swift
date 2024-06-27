//
//  FoodiApp.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI
import FirebaseCore
import AVFAudio
import Kingfisher

class AppDelegate: NSObject, UIApplicationDelegate {
    
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
      let audioSession = AVAudioSession.sharedInstance()
          do {
              try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
              try audioSession.setActive(true)
          } catch let error as NSError {
              print("Failed to set the audio session category and mode: \(error.localizedDescription)")
          }
      configureKingfisherCache()
    return true
  }
}
@main
struct foodiApp: App {
    init() {
        let appear = UINavigationBarAppearance()

        let atters: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "MuseoSansRounded-1000", size: 30)!
        ]
        let inlineTitleAttributes: [NSAttributedString.Key: Any] = [
                   .font: UIFont(name: "MuseoSansRounded-1000", size: 20)! // Smaller size for inline title
               ]

        appear.largeTitleTextAttributes = atters
        appear.titleTextAttributes = inlineTitleAttributes
        appear.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appear
        UINavigationBar.appearance().compactAppearance = appear
        UINavigationBar.appearance().scrollEdgeAppearance = appear
     }
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
func configureKingfisherCache() {
    // Get the default cache
    let cache = ImageCache.default
    
    // Set maximum disk cache size to 500 MB (500 * 1024 * 1024 bytes)
    cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024
    
    // Optionally set maximum memory cache size to 100 MB (100 * 1024 * 1024 bytes)
    cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
    
    // Set the expiration for cached images (e.g., 7 days)
    cache.diskStorage.config.expiration = .days(7)
    
    // Optionally clear the cache if needed
    // cache.clearDiskCache()
    // cache.clearMemoryCache()
}

// Call this function early in your app lifecycle, such as in AppDelegate or SceneDelegate

