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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
