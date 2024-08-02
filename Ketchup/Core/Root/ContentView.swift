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
    @State var showNotifications = false
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
                    .onReceive(NotificationCenter.default.publisher(for: .navigateToProfile)) { _ in
                        print("Received navigate to profile notification")
                        DispatchQueue.main.async {
                            self.tabBarController.selectedTab = 4
                            showNotifications = true
                            print("Tab set to: \(self.tabBarController.selectedTab)")
                        }
                    }
            } else if viewModel.userSession == nil {
                LoginView()
                    .customFont()
            }
        }
    }

    private func checkInitialNavigation() {
        if let initialTab = UserDefaults.standard.object(forKey: "initialTab") as? Int {
            print("Found initial tab: \(initialTab)")
            DispatchQueue.main.async {
                self.tabBarController.selectedTab = initialTab
                print("Tab set to: \(self.tabBarController.selectedTab)")
                showNotifications = true
                UserDefaults.standard.removeObject(forKey: "initialTab")
            }
        }
    }
}

