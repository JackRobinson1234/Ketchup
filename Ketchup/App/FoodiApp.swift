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
import Firebase
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.Message_ID"
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        application.registerForRemoteNotifications()
        Messaging.messaging().token { token, error in
                    if let error {
                        print("Error fetching FCM registration token: \(error)")
                    } else if let token {
                        print("FCM registration token: \(token)")
                    }
                }
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("Error setting badge count: \(error)")
                }
            }
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
    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
            print("Oh no! Failed to register for remote notifications with error \(error)")
        }
    
}
extension AppDelegate: MessagingDelegate {
    @objc func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase token: \(String(describing: fcmToken))")
        if let token = fcmToken {
                    saveTokenToFirestore(token: token)
                }
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

extension AppDelegate: UNUserNotificationCenterDelegate {
  // Receive displayed notifications for iOS 10 devices.
 
    func application(_ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
      Messaging.messaging().apnsToken = deviceToken;
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      let userInfo = notification.request.content.userInfo

      Messaging.messaging().appDidReceiveMessage(userInfo)

      // Change this to your preferred presentation option
        if #available(iOS 14.0, *) {
              completionHandler([.banner, .sound, .badge])
          } else {
              completionHandler([.alert, .sound, .badge])
          }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
      let userInfo = response.notification.request.content.userInfo

      Messaging.messaging().appDidReceiveMessage(userInfo)

      completionHandler()
    }

    func application(_ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
       fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      Messaging.messaging().appDidReceiveMessage(userInfo)
      completionHandler(.noData)
    }
    func saveTokenToFirestore(token: String) {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            
            let db = Firestore.firestore()
            db.collection("users").document(userId).collection("devices").document(deviceId).setData([
                "fcmToken": token,
                "lastUpdated": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("Error saving token: \(error)")
                } else {
                    print("Token saved successfully")
                }
            }
        }
    
}
