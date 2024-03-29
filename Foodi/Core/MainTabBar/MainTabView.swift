//
//  MainTabView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
struct MainTabView: View {
    private let authService: AuthService
    private let userService: UserService
    @State private var selectedTab = 0
    @StateObject private var videoCoordinator = VideoPlayerCoordinator()
    @State private var playbackObserver: NSObjectProtocol?
    
    init(authService: AuthService, userService: UserService) {
        self.authService = authService
        self.userService = userService
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(videoCoordinator: videoCoordinator, userService: userService)
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                            .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                        
                        Text("Home")
                    }
                }
                .onAppear { selectedTab = 0 }
                .tag(0)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white.opacity(0.8), for: .tabBar)
            MapView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 1 ? "location.fill" : "location")
                            .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                        
                        Text("Map")
                    }
                }
                .onAppear { selectedTab = 1 }
                .tag(1)
            
            //RestaurantSelectorView(tabIndex: $selectedTab)
            CreatePostSelection(tabIndex: $selectedTab)
                .tabItem { Image(systemName: "plus") }
                .onAppear { selectedTab = 2 }
                .tag(2)
            
            ActivityView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 3 ? "bolt.fill" : "bolt")
                            .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                        
                        Text("Activity")
                    }
                }
                .onAppear { selectedTab = 3 }
                .tag(3)
            
            CurrentUserProfileView(authService: authService, userService: userService)
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                            .environment(\.symbolVariants, selectedTab == 4 ? .fill : .none)
                        
                        Text("Profile")
                    }
                }
                .onAppear { selectedTab = 4 }
                .tag(4)
        }
        .tint(.black)
        
    }
}
    
    /*func configurePlaybackObserver() {
        self.playbackObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification,
                                                                       object: nil,
                                                                       queue: .main) { _ in
            let player = videoCoordinator.videoPlayerManager.queuePlayer
            if player?.timeControlStatus == .playing {
                player?.seek(to: CMTime.zero)
                player?.play()
            }
        }
    }
    
    func removePlaybackObserver() {
        if let playbackObserver {
            NotificationCenter.default.removeObserver(playbackObserver,
                                                      name: AVPlayerItem.didPlayToEndTimeNotification,
                                                      object: nil)
        }
    } 
}*/

#Preview {
    MainTabView(authService: AuthService(), userService: UserService())
}
