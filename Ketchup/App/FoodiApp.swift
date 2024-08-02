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
struct KetchupApp: App {
    @StateObject private var tabBarController = TabBarController()
    @State private var showNotifications = false
    
    init() {
        let appear = UINavigationBarAppearance()
        
        let atters: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "MuseoSansRounded-1000", size: 20)!
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
                .environmentObject(tabBarController)
            
        }
    }
}


func configureKingfisherCache() {
    // Get the default cache
    let cache = ImageCache.default
    
    // Set maximum disk cache size to 500 MB (500 * 1024 * 1024 bytes)
    cache.diskStorage.config.sizeLimit = 100 * 1024 * 1024
    
    // Optionally set maximum memory cache size to 100 MB (100 * 1024 * 1024 bytes)
    cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
    
    // Set the expiration for cached images (e.g., 7 days)
    cache.diskStorage.config.expiration = .days(1)
    
    // Optionally clear the cache if needed
    // cache.clearDiskCache()
    // cache.clearMemoryCache()
}

// Call this function early in your app lifecycle, such as in AppDelegate or SceneDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.


    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                    options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        if connectingSceneSession.role == .windowApplication {
            configuration.delegateClass = SceneDelegate.self
        }
        return configuration
    }
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
        
        // Handle the notification action
        handleNotificationAction(userInfo: userInfo)
        
        completionHandler()
    }
    
    func handleNotificationAction(userInfo: [AnyHashable: Any]) {
            // Store the navigation info in UserDefaults
            UserDefaults.standard.set(4, forKey: "initialTab")
            UserDefaults.standard.synchronize()

            // Post a notification to navigate to the profile tab
            NotificationCenter.default.post(name: .navigateToProfile, object: nil, userInfo: ["tab": 4])
        }
    func application(_ application: UIApplication,
                        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
           Messaging.messaging().appDidReceiveMessage(userInfo)
           handleNotificationAction(userInfo: userInfo)
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
final class SceneDelegate: NSObject, UIWindowSceneDelegate {

  var secondaryWindow: UIWindow?

  func scene(_ scene: UIScene,
             willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
      if let windowScene = scene as? UIWindowScene {
          setupSecondaryOverlayWindow(in: windowScene)
      }
  }

  func setupSecondaryOverlayWindow(in scene: UIWindowScene) {
      let secondaryViewController = UIHostingController(
          rootView:
              EmptyView()
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
                  .modifier(InAppNotificationViewModifier())
      )
    secondaryViewController.view.backgroundColor = .clear
    let secondaryWindow = PassThroughWindow(windowScene: scene)
    secondaryWindow.rootViewController = secondaryViewController
    secondaryWindow.isHidden = false
    self.secondaryWindow = secondaryWindow
  }
}
class PassThroughWindow: UIWindow {
  override func hitTest(_ point: CGPoint,
                        with event: UIEvent?) -> UIView? {
    guard let hitView = super.hitTest(point, with: event)
    else { return nil }

    return rootViewController?.view == hitView ? nil : hitView
  }
}
struct InAppNotificationViewModifier: ViewModifier {
func body(content: Content) -> some View {
  content
    .overlay {
      VStack {
        Text("Notification Example")
          .frame(maxWidth: .infinity)
          .padding()
          .background(.background)
          .clipShape(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
          )
          .overlay(
            RoundedRectangle(cornerRadius: 25)
              .strokeBorder(.tertiary, lineWidth: 1)
          )
          .shadow(color: .black.opacity(0.15), radius: 10, y: 3)
          .padding(.horizontal)
        Spacer()
      }
    }
  }
}
