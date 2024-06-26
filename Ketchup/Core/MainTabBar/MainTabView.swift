//
//  MainTabView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import AVKit
struct MainTabView: View {
    @State private var playbackObserver: NSObjectProtocol?
    @EnvironmentObject var tabBarController: TabBarController
    @StateObject var feedViewModel = FeedViewModel()

    var body: some View {
        TabView(selection: $tabBarController.selectedTab) {
            FeedView(viewModel: feedViewModel)
                .tabItem {
                    
                        Image(systemName: tabBarController.selectedTab == 0 ? "house.fill" : "house")
                        .resizable()
                            .foregroundStyle(.primary)
                            .environment(\.symbolVariants, tabBarController.selectedTab == 0 ? .none : .none)
                        
                    .padding()
                }
                .onAppear { 
                    tabBarController.selectedTab = 0
                    tabBarController.visibility = .visible
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
                .onAppear {
                    tabBarController.selectedTab = 1
                    tabBarController.visibility = .visible
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
                    
                        Image(systemName: tabBarController.selectedTab == 3 ? "bolt.fill" : "bolt")
                            .foregroundStyle(.primary)
                            .environment(\.symbolVariants, tabBarController.selectedTab == 3 ? .none : .none)
                            
                        
                    
                    .padding()
                }
                .onAppear {
                    tabBarController.selectedTab = 3
                    tabBarController.visibility = .visible
                }
                .tag(3)
                .toolbarBackground(.visible, for: .tabBar)
               
                .toolbar(tabBarController.visibility, for: .tabBar)
            
            CurrentUserProfileView()
                .tabItem {
                    VStack(){
                        Image(systemName: tabBarController.selectedTab == 4 ? "person.fill" : "person")
                    
                    }
                    .environment(\.symbolVariants, tabBarController.selectedTab == 4 ? .none : .none)
                    .foregroundStyle(.primary)
                    
                }
                .badge(AuthService.shared.userSession?.notificationAlert ?? 0)
                .onAppear {
                    tabBarController.selectedTab = 4
                    tabBarController.visibility = .visible
                }
                .tag(4)
                .toolbar(tabBarController.visibility, for: .tabBar)
        }
        .foregroundStyle(.primary)
        .tint(Color("Colors/AccentColor"))
        
    }
}
    
#Preview {
    MainTabView()
}
