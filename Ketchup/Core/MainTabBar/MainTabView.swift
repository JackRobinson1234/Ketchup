//
//  MainTabView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
import FirebaseAnalytics
import FirebaseAuth

struct MainTabView: View {
    @EnvironmentObject var tabBarController: TabBarController
    @StateObject var feedViewModel = FeedViewModel()
    
    @State private var sessionStartTime: Date = Date()
    @State private var tabStartTime: Date?
    @State private var sessionTimeSpent: [Int: TimeInterval] = [:]
    
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $tabBarController.selectedTab) {
            PrimaryFeedView(viewModel: feedViewModel)
                .tabItem {
                    Image(systemName: tabBarController.selectedTab == 0 ? "house.fill" : "house")
                        .resizable()
                        .foregroundStyle(.primary)
                        .environment(\.symbolVariants, tabBarController.selectedTab == 0 ? .none : .none)
                        .padding()
                }
                .tag(0)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)

            MapView()
                .tabItem {
                    Image(systemName: tabBarController.selectedTab == 1 ? "location.fill" : "location")
                        .foregroundStyle(.primary)
                        .environment(\.symbolVariants, tabBarController.selectedTab == 1 ? .none : .none)
                        .padding()
                }
                .tag(1)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)

            CameraView(feedViewModel: feedViewModel)
                .tabItem {
                    Image(systemName: "plus.app")
                        .foregroundStyle(.primary)
                        .padding()
                }
                .onAppear {
                                    tabBarController.selectedTab = 2
                                    tabBarController.visibility = .hidden
                                }
                .tag(2)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)

            ActivityView()
                .tabItem {
                    Image(systemName: tabBarController.selectedTab == 3 ? "flame.fill" : "flame")
                        .foregroundStyle(.primary)
                        .environment(\.symbolVariants, tabBarController.selectedTab == 3 ? .none : .none)
                        .padding()
                }
                .tag(3)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)

            CurrentUserProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: tabBarController.selectedTab == 4 ? "person.fill" : "person")
                    }
                    .environment(\.symbolVariants, tabBarController.selectedTab == 4 ? .none : .none)
                    .foregroundStyle(.primary)
                }
                .badge(AuthService.shared.userSession?.notificationAlert ?? 0)
                .tag(4)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)
        }
        .foregroundStyle(.primary)
        .tint(Color("Colors/AccentColor"))
        .onAppear {
            sessionStartTime = Date()
            startTracking(tab: tabBarController.selectedTab)
        }
        .onDisappear {
            stopTracking(tab: tabBarController.selectedTab)
            sendSessionAnalytics()
        }
        .onChange(of: tabBarController.selectedTab) {oldPhase,  newTab in
            stopTracking(tab: tabBarController.selectedTab)
            startTracking(tab: newTab)
        }
        .onChange(of: scenePhase) {oldPhase, newPhase in
            if newPhase == .background {
                stopTracking(tab: tabBarController.selectedTab)
                sendSessionAnalytics()
            } else if newPhase == .active {
                sessionStartTime = Date()
                startTracking(tab: tabBarController.selectedTab)
            }
        }
    }
    
    private func startTracking(tab: Int) {
        print("Starting Tracking")
        tabStartTime = Date()
    }

    private func stopTracking(tab: Int) {
        print("Stopping Tracking")
        guard let startTime = tabStartTime else { return }
        let timeSpent = Date().timeIntervalSince(startTime)
        sessionTimeSpent[tab, default: 0] += timeSpent
    }

    private func sendSessionAnalytics() {
        if Auth.auth().currentUser?.uid != "yO2MWjMCZ1MsBsuVE9h8M5BTlpj2" || AuthService.shared.userSession?.username != "joe"{
            let totalSessionTime = Date().timeIntervalSince(sessionStartTime)
            
            Analytics.logEvent("session_time", parameters: [
                "total_time": totalSessionTime as NSObject
            ])
            
            for (tab, time) in sessionTimeSpent {
                print("tab: \(tab), time: \(time)")
                Analytics.logEvent("tab_time_in_session", parameters: [
                    "tab": tab as NSObject,
                    "time": time as NSObject
                ])
            }
        }
        // Reset session data
        sessionTimeSpent.removeAll()
    }
}
