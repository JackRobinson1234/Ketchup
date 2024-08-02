//
//  ContentView.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI
import FirebaseAuth
import SwiftUI
import FirebaseAuth
struct ContentView: View {
    @EnvironmentObject var tabBarController: TabBarController
    @StateObject var viewModel: ContentViewModel = ContentViewModel()
    var body: some View {
        Group {
            if Auth.auth().currentUser != nil {
                MainTabView()
                    .environmentObject(viewModel)
                    .environmentObject(tabBarController)
                    .customFont()
                    .onAppear {
                        checkInitialNavigation()
                    }

            } else if viewModel.userSession == nil {
                LoginView()
                    .customFont()
            }
        }
    }

    private func checkInitialNavigation() {
        if let initialTab = UserDefaults.standard.object(forKey: "initialTab") as? Int {
            NotificationCenter.default.post(name: .navigateToProfile, object: nil, userInfo: ["tab": 4])
            UserDefaults.standard.removeObject(forKey: "initialTab")
// If you want to change tabs
//            print("Found initial tab: \(initialTab)")
//            DispatchQueue.main.async {
//                self.tabBarController.selectedTab = initialTab
//                print("Tab set to: \(self.tabBarController.selectedTab)")
//                showNotifications = true
//                UserDefaults.standard.removeObject(forKey: "initialTab")
//            }
        }
    }
}

