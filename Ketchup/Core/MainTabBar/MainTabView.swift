//
//  MainTabView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
struct MainTabView: View {
    @StateObject private var videoCoordinator = VideoPlayerCoordinator()
    @State private var playbackObserver: NSObjectProtocol?
    @EnvironmentObject var tabBarController: TabBarController
        
    var body: some View {
        TabView(selection: $tabBarController.selectedTab) {
            FeedView(videoCoordinator: videoCoordinator)
                .tabItem {
                    VStack {
                        Image(systemName: tabBarController.selectedTab == 0 ? "house.fill" : "house")
                            .foregroundStyle(.black)
                            .environment(\.symbolVariants, tabBarController.selectedTab == 0 ? .none : .none)
                        
                    }.padding()
                }
                .onAppear { 
                    tabBarController.selectedTab = 0
                    tabBarController.visibility = .visible
                }
                .tag(0)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white.opacity(0.8), for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)
            
            MapView()
                .tabItem {
                    VStack {
                        Image(systemName: tabBarController.selectedTab == 1 ? "location.fill" : "location")
                            .foregroundStyle(.black)
                            .environment(\.symbolVariants, tabBarController.selectedTab == 1 ? .none : .none)
                        
                    }
                    .padding()
                }
                .onAppear {
                    tabBarController.selectedTab = 1
                    tabBarController.visibility = .visible
                }
                .tag(1)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white.opacity(0.8), for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)
      
            CameraView()
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
                .toolbarBackground(Color.white.opacity(0.8), for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)
            
            ActivityView()
                .tabItem {
                    VStack {
                        Image(systemName: tabBarController.selectedTab == 3 ? "bolt.fill" : "bolt")
                            .foregroundStyle(.black)
                            .environment(\.symbolVariants, tabBarController.selectedTab == 3 ? .none : .none)
                            
                        
                    }
                    .padding()
                }
                .onAppear {
                    tabBarController.selectedTab = 3
                    tabBarController.visibility = .visible
                }
                .tag(3)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.white.opacity(0.8), for: .tabBar)
                .toolbar(tabBarController.visibility, for: .tabBar)
            
            CurrentUserProfileView()
                .tabItem {
                    VStack {
                        Image(systemName: tabBarController.selectedTab == 4 ? "person.fill" : "person")
                            .environment(\.symbolVariants, tabBarController.selectedTab == 4 ? .none : .none)
                            .foregroundStyle(.black)
                        
                    }
                    .padding()
                }
                .onAppear {
                    tabBarController.selectedTab = 4
                    tabBarController.visibility = .visible
                }
                .tag(4)
                .toolbar(tabBarController.visibility, for: .tabBar)
        }
        .foregroundStyle(.black)
        .tint(Color("Colors/AccentColor"))
        
    }
}
    
#Preview {
    MainTabView()
}
