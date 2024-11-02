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
    
  
    var body: some View {
        TabView(selection: $tabBarController.selectedTab) {
            LazyView(PrimaryFeedView(viewModel: feedViewModel))
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
            LazyView(SearchView(initialSearchConfig: .restaurants))
                .tabItem {
                    VStack(spacing:1){
                        Image(systemName: tabBarController.selectedTab == 1 ? "magnifyingglass" : "magnifyingglass")
                            .foregroundStyle(.black)
                            .environment(\.symbolVariants, tabBarController.selectedTab == 1 ? .none : .none)
                            .padding()
                        Text("Search")
                            .font(.custom("MuseoSansRounded-500", size: 8))
                            .foregroundStyle(.gray)
                    }
                }
                .tag(1)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)
                .onAppear {
                    tabBarController.selectedTab = 1
                    tabBarController.visibility = .visible
                }
            
            LazyView(UploadFlowRestaurantSelector(uploadViewModel: UploadViewModel(feedViewModel: feedViewModel, currentUserFeedViewModel: currentUserFeedViewModel), cameraViewModel: CameraViewModel(), isEditingRestaurant: false))
                .tabItem {
                    Image(systemName: "plus.rectangle")
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

           
            if #available(iOS 17, *) {
                LazyView(MapView())
                    .tabItem {
                        VStack(spacing:1){
                            Image(systemName: tabBarController.selectedTab == 3 ? "location.fill" : "location")
                                .foregroundStyle(.black)
                                .environment(\.symbolVariants, tabBarController.selectedTab == 3 ? .none : .none)
                                .padding()
                            Text("Restaurants")
                                .font(.custom("MuseoSansRounded-500", size: 8))
                                .foregroundStyle(.gray)
                        }
                    }
                
                    .onAppear {
                        tabBarController.selectedTab = 3
                        tabBarController.visibility = .visible
                    }
                    .tag(3)
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbar(tabBarController.visibility, for: .tabBar)
            } else {
                LazyView(Ios16MapView())
                    .tabItem {
                        VStack(spacing:1){
                            Image(systemName: tabBarController.selectedTab == 3 ? "location.fill" : "location")
                                .foregroundStyle(.black)
                                .environment(\.symbolVariants, tabBarController.selectedTab == 3 ? .none : .none)
                                .padding()
                            Text("Map")
                                .font(.custom("MuseoSansRounded-500", size: 8))
                                .foregroundStyle(.gray)
                        }
                    }
                
                    .onAppear {
                        tabBarController.selectedTab = 3
                        tabBarController.visibility = .visible
                    }
                    .tag(3)
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbar(tabBarController.visibility, for: .tabBar)
            }
            LazyView(CurrentUserProfileView( feedViewModel: currentUserFeedViewModel))
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
    private var badgeValue: Int? {
        guard let lastVotedDate = AuthService.shared.userSession?.lastVotedPoll else {
            return 1 // Show badge if user has never voted
        }
        
        let calendar = Calendar.current
        let losAngelesTimeZone = TimeZone(identifier: "America/Los_Angeles")!
        
        let lastVotedDateLA = calendar.date(byAdding: .hour, value: losAngelesTimeZone.secondsFromGMT() / 3600, to: lastVotedDate)!
        let nowLA = calendar.date(byAdding: .hour, value: losAngelesTimeZone.secondsFromGMT() / 3600, to: Date())!
        
        let lastVotedDay = calendar.startOfDay(for: lastVotedDateLA)
        let todayLA = calendar.startOfDay(for: nowLA)
        
        return calendar.isDate(lastVotedDay, inSameDayAs: todayLA) ? nil : 1
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
struct LazyView<Content: View>: View {
    private let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: some View {
        build()
    }
}
