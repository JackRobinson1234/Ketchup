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
import FirebaseAuth
import FirebaseFirestoreInternal

class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.Message_ID"
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        setupFirebase()
        setupNotifications(application)
        setupAudioSession()
        configureKingfisherCache()
        return true
    }
    
    private func setupFirebase() {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
            if Auth.auth().canHandle(url) {
                return true
            }
            // Here you can handle other custom URL schemes if needed
            return false
        }
    private func setupNotifications(_ application: UIApplication) {
//        //print("Setting up notifications...")
//        UNUserNotificationCenter.current().delegate = self
//        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
//            if granted {
//                //print("Notification authorization granted")
//                DispatchQueue.main.async {
//                    //print("Registering for remote notifications...")
//                    application.registerForRemoteNotifications()
//                }
//            } else {
//                //print("Notification authorization denied")
//                if let error = error {
//                    //print("Authorization error: \(error.localizedDescription)")
//                }
//            }
//        }
        resetBadgeCount()
    }
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
      for urlContext in URLContexts {
          let url = urlContext.url
          _ = Auth.auth().canHandle(url)
      }
      // URL not auth related; it should be handled separately.
    }
    private func fetchFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                //print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
            }
        }
    }
    
    private func resetBadgeCount() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                //print("Error setting badge count: \(error)")
            }
        }
    }
    func updateUserLastActive() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let lastActive = Date()
        let userRef = FirestoreConstants.UserCollection.document(userId)
        do {
            try await userRef.updateData(["lastActive": Timestamp(date: lastActive)])
            //print("DEBUG: Successfully updated lastActive timestamp.")
        } catch {
            //print("DEBUG: Failed to update lastActive timestamp with error: \(error.localizedDescription)")
        }
    }
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            //print("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }
    }
    
    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        //print("Failed to register for remote notifications: \(error)")
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //print("Successfully registered for remote notifications with token:")
        Messaging.messaging().apnsToken = deviceToken
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
        //print("FETCHING FCM TOKEN")
        fetchFCMToken()
    }
    
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
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        Messaging.messaging().appDidReceiveMessage(userInfo)
        handleNotificationAction(userInfo: userInfo)
        completionHandler(.noData)
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        //print("Firebase token: \(String(describing: fcmToken))")
        if let token = fcmToken {
            saveTokenToFirestore(token: token)
        }
    }
    
    private func saveTokenToFirestore(token: String) {
        if let userId = Auth.auth().currentUser?.uid {
            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            let db = Firestore.firestore()
            db.collection("users").document(userId).collection("devices").document(deviceId).setData([
                "fcmToken": token,
                "lastUpdated": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    //print("Error saving token: \(error)")
                } else {
                    //print("Token saved successfully")
                }
            }
        } else {
            // Save the token locally until the user signs in
            UserDefaults.standard.set(token, forKey: "fcmToken")
            //print("Token saved locally")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        handleNotificationAction(userInfo: userInfo)
        completionHandler()
    }
    
    private func handleNotificationAction(userInfo: [AnyHashable: Any]) {
        UserDefaults.standard.set(4, forKey: "initialTab")
        NotificationCenter.default.post(name: .navigateToProfile, object: nil, userInfo: ["tab": 4])
    }
}

@main
struct KetchupApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var tabBarController = TabBarController()
    
    init() {
        configureNavigationBarAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tabBarController)
        }
    }
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "MuseoSansRounded-900", size: 20)!
        ]
        appearance.largeTitleTextAttributes = attributes
        appearance.titleTextAttributes = attributes
        appearance.backgroundColor = UIColor.white
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

func configureKingfisherCache() {
    let cache = ImageCache.default
    cache.diskStorage.config.sizeLimit = 100 * 1024 * 1024 // 100 MB
    cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    cache.diskStorage.config.expiration = .days(1)
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
    
    private func setupSecondaryOverlayWindow(in scene: UIWindowScene) {
        let secondaryViewController = UIHostingController(
            rootView: EmptyView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(InAppNotificationViewModifier())
                .modifier(UploadViewModifier()) // Apply the new modifier
        )
        secondaryViewController.view.backgroundColor = .clear
        let secondaryWindow = PassThroughWindow(windowScene: scene)
        secondaryWindow.rootViewController = secondaryViewController
        secondaryWindow.isHidden = false
        self.secondaryWindow = secondaryWindow
    }
}

class PassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        return rootViewController?.view == hitView ? nil : hitView
    }
}

struct InAppNotificationViewModifier: ViewModifier {
    @State private var showNotifications = false
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if showNotifications {
                    NotificationsView(isPresented: $showNotifications)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToProfile)) { _ in
                //print("Received navigate to profile notification")
                DispatchQueue.main.async {
                    showNotifications = true
                }
            }
    }
}
struct UploadViewModifier: ViewModifier {
    @State private var showUploadView = false
    @StateObject var feedViewModel = FeedViewModel()
    @StateObject var currentUserFeedViewModel = FeedViewModel()

    func body(content: Content) -> some View {
        content
            .overlay {
                if showUploadView {
                    NewPostCongratulations(isShown: $showUploadView)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .presentUploadView)) { _ in
                DispatchQueue.main.async {
                    showUploadView = true
                }
            }
    }
}



extension Foundation.Notification.Name {
    static let presentUploadView = Foundation.Notification.Name("presentUploadView")
}

