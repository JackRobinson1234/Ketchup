//
//  MainTabView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var videoCoordinator = VideoPlayerCoordinator()
    @State private var playbackObserver: NSObjectProtocol?
    @EnvironmentObject var tabBarController: TabBarController
        
    var body: some View {
        TabView(selection: $tabBarController.selectedTab) {
            FeedView(videoCoordinator: videoCoordinator)
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                            .environment(\.symbolVariants, selectedTab == 0 ? .fill : .none)
                        
                    }
                }
                .onAppear { tabBarController.selectedTab = 0 }
                .tag(0)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white.opacity(0.8), for: .tabBar)
            MapView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 1 ? "location.fill" : "location")
                            .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                        
                    }
                }
                .onAppear { tabBarController.selectedTab = 1 }
                .tag(1)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white.opacity(0.8), for: .tabBar)
      
            CameraView()
                .tabItem { Image(systemName: "plus") }
                .onAppear { tabBarController.selectedTab = 2 }
                .tag(2)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white.opacity(0.8), for: .tabBar)
                .toolbar(.hidden, for: .tabBar)
            
            ActivityView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 3 ? "bolt.fill" : "bolt")
                            .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                        
                    }
                }
                .onAppear { tabBarController.selectedTab = 3 }
                .tag(3)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white.opacity(0.8), for: .tabBar)
            
            CurrentUserProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                            .environment(\.symbolVariants, selectedTab == 4 ? .fill : .none)
                        
                    }
                }
                .onAppear { tabBarController.selectedTab = 4 }
                .tag(4)
        }
        .tint(.black)
        
    }
}
    
#Preview {
    MainTabView()
}
