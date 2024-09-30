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
    @StateObject var currentUserFeedViewModel = FeedViewModel()
    @State private var sessionStartTime: Date = Date()
    @State private var tabStartTime: Date?
    @State private var sessionTimeSpent: [Int: TimeInterval] = [:]
    @Environment(\.scenePhase) private var scenePhase
    @State private var testString: String?
    
  
    var body: some View {
        TabView(selection: $tabBarController.selectedTab) {
            PrimaryFeedView(viewModel: feedViewModel)
                .tabItem {
                    VStack(spacing:1){
                        Image(systemName: tabBarController.selectedTab == 0 ? "house.fill" : "house")
                            .resizable()
                            .foregroundStyle(.black)
                            .environment(\.symbolVariants, tabBarController.selectedTab == 0 ? .none : .none)
                            .padding()
                        Text("Home")
                            .font(.custom("MuseoSansRounded-500", size: 8))
                            .foregroundStyle(.gray)
                    }
                }
                .onAppear{ 
                    tabBarController.selectedTab = 0
                    tabBarController.visibility = .visible
                }
                .badge(AuthService.shared.userSession?.followingPosts ?? 0)
                .tag(0)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)
                
            if #available(iOS 17, *) {
                MapView()
                    .tabItem {
                        VStack(spacing:1){
                            Image(systemName: tabBarController.selectedTab == 1 ? "location.fill" : "location")
                                .foregroundStyle(.black)
                                .environment(\.symbolVariants, tabBarController.selectedTab == 1 ? .none : .none)
                                .padding()
                            Text("Map")
                                .font(.custom("MuseoSansRounded-500", size: 8))
                                .foregroundStyle(.gray)
                        }
                    }
                
                    .onAppear {
                        tabBarController.selectedTab = 1
                        tabBarController.visibility = .visible
                    }
                    .tag(1)
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbar(tabBarController.visibility, for: .tabBar)
            } else {
                Ios16MapView()
                    .tabItem {
                        VStack(spacing:1){
                            Image(systemName: tabBarController.selectedTab == 1 ? "location.fill" : "location")
                                .foregroundStyle(.black)
                                .environment(\.symbolVariants, tabBarController.selectedTab == 1 ? .none : .none)
                                .padding()
                            Text("Map")
                                .font(.custom("MuseoSansRounded-500", size: 8))
                                .foregroundStyle(.gray)
                        }
                    }
                
                    .onAppear {
                        tabBarController.selectedTab = 1
                        tabBarController.visibility = .visible
                    }
                    .tag(1)
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbar(tabBarController.visibility, for: .tabBar)
            }
            UploadFlowRestaurantSelector(uploadViewModel: UploadViewModel(feedViewModel: feedViewModel, currentUserFeedViewModel: currentUserFeedViewModel), cameraViewModel: CameraViewModel(), isEditingRestaurant: false)
                .tabItem {
                    Image(systemName: "plus.app")
                        .foregroundStyle(.black)
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
                    VStack(spacing:1){
                        Image(systemName: tabBarController.selectedTab == 3 ? "flame.fill" : "flame")
                            .foregroundStyle(.black)
                            .environment(\.symbolVariants, tabBarController.selectedTab == 3 ? .none : .none)
                            .padding()
                        Text("Discover")
                            .font(.custom("MuseoSansRounded-500", size: 8))
                            .foregroundStyle(.gray)
                    }
                }
                .tag(3)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)
                .onAppear {
                    tabBarController.selectedTab = 3
                    tabBarController.visibility = .visible
                }

            CurrentUserProfileView( feedViewModel: currentUserFeedViewModel)
                .tabItem {
                    
                        VStack(spacing:1){
                            Image(systemName: tabBarController.selectedTab == 4 ? "person.fill" : "person")
                            Text("Profile")
                                .font(.custom("MuseoSansRounded-500", size: 8))
                                .foregroundStyle(.gray)
                        }
                    
                    .environment(\.symbolVariants, tabBarController.selectedTab == 4 ? .none : .none)
                    .foregroundStyle(.black)
                }
                .onAppear {
                    tabBarController.selectedTab = 4
                    tabBarController.visibility = .visible
                }
                .badge(AuthService.shared.userSession?.notificationAlert ?? 0)
                .tag(4)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)
        }
        .foregroundStyle(.black)
        .tint(Color("Colors/AccentColor"))
        .onAppear {
            sessionStartTime = Date()
            startTracking(tab: tabBarController.selectedTab)

            // Check for initial tab navigation
            if let initialTab = UserDefaults.standard.object(forKey: "initialTab") as? Int {
                DispatchQueue.main.async {
                    self.tabBarController.selectedTab = initialTab
                    UserDefaults.standard.removeObject(forKey: "initialTab")
                }
            }
        }
        .onDisappear {
            stopTracking(tab: tabBarController.selectedTab)
            sendSessionAnalytics()
        }
//        .onChange(of: tabBarController.selectedTab) { oldTab, newTab in
//            stopTracking(tab: oldTab)
//            startTracking(tab: newTab)
//        }
//        .onChange(of: scenePhase) { oldPhase, newPhase in
//            if newPhase == .background {
//                stopTracking(tab: tabBarController.selectedTab)
//                sendSessionAnalytics()
//            } else if newPhase == .active {
//                sessionStartTime = Date()
//                startTracking(tab: tabBarController.selectedTab)
//            }
//        }
        .sheet(isPresented: $tabBarController.showContacts){
            ContactsView()
        }
        
    }
    
    private func startTracking(tab: Int) {
        tabStartTime = Date()
    }

    private func stopTracking(tab: Int) {
        guard let startTime = tabStartTime else { return }
        let timeSpent = Date().timeIntervalSince(startTime)
        sessionTimeSpent[tab, default: 0] += timeSpent
    }

    private func sendSessionAnalytics() {
        let totalSessionTime = Date().timeIntervalSince(sessionStartTime)
        Analytics.logEvent("session_time", parameters: [
            "total_time": totalSessionTime as NSObject
        ])
        for (tab, time) in sessionTimeSpent {
            Analytics.logEvent("tab_time_in_session", parameters: [
                "tab": tab as NSObject,
                "time": time as NSObject
            ])
        }

        sessionTimeSpent.removeAll()
    }
}


extension Foundation.Notification.Name {
    static let navigateToProfile = Foundation.Notification.Name("navigateToProfile")
}
