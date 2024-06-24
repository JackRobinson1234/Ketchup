//
//  FoodiApp.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI
import FirebaseCore
import AVFAudio

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
