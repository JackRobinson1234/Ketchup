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
    private let user: User
    private let userService: UserService
    @State private var selectedTab = 0
    @State private var player = AVPlayer()
    @State private var playbackObserver: NSObjectProtocol?
    
    init(authService: AuthService, user: User, userService: UserService) {
        self.authService = authService
        self.user = user
        self.userService = userService
    }
        
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView(player: $player, userService: userService)
                .toolbarBackground(.black, for: .tabBar)
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                            .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                        
                        Text("Home")
                    }
                }
                .onAppear { selectedTab = 0 }
                .tag(0)
            
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
            
            /*MediaSelectorView(tabIndex: $selectedTab)
                .tabItem { Image(systemName: "plus") }
                .onAppear { selectedTab = 2 }
                .tag(2)*/
            PostSelectorView()
                .tabItem { Image(systemName: "star") }
                .onAppear { selectedTab = 6 }
                .tag(6)
            NotificationsView(userService: userService)
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 3 ? "heart.fill" : "heart")
                            .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                        
                        Text("Inbox")
                    }
                }
                .onAppear { selectedTab = 3 }
                .tag(3)

            CurrentUserProfileView(authService: authService, user: user, userService: userService)
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
        .onAppear { configurePlaybackObserver() }
        .onDisappear { removePlaybackObserver() }
        .tint(selectedTab == 0 ? .white : .black)
    }
    
    func configurePlaybackObserver() {
        self.playbackObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification,
                                                                       object: nil,
                                                                       queue: .main) { _ in
            if player.timeControlStatus == .playing {
                self.player.seek(to: CMTime.zero)
                self.player.play()
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
}

#Preview {
    MainTabView(authService: AuthService(), user: DeveloperPreview.user, userService: UserService())
}
