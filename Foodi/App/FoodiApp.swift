//
//  FoodiApp.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}
@main
struct foodiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    private let userService = UserService()
    var body: some Scene {
        WindowGroup {
            ContentView(userService: userService)
        }
    }
}
