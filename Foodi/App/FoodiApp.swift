//
//  FoodiApp.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI
import FirebaseCore
import GooglePlaces

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    GMSPlacesClient.provideAPIKey("AIzaSyCIC32gKi0m6ErD_XWNw9K1oqLv5EpCCBU")

    return true
  }
}
@main
struct foodiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    private let authService = AuthService()
    private let userService = UserService()
    var body: some Scene {
        WindowGroup {
            ContentView(authService: authService, userService: userService)
        }
    }
}
