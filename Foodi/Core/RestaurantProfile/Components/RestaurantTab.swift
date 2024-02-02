//
//  RestaurantTab.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//
import SwiftUI
struct RestaurantTab: View {
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            Text("Posts")
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "square.grid.2x2.fill" : "square.grid.2x2")
                        .environment(\.symbolVariants, selectedTab == 1 ? .fill : .none)
                    
                    Text("Posts")
                }
            
                .onAppear { selectedTab = 1 }
                .tag(1)
            
            Text("Menu")
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "menucard.fill" : "menucard")
                        .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                    
                    Text("Menu")
                }
                .onAppear { selectedTab = 2 }
                .tag(2)
            Text("Map")
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "location.fill" : "location")
                        .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                    
                    Text("Map")
                }
            
                .onAppear { selectedTab = 3 }
                .tag(3)
            
            Text("Reviews")
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "message.fill" : "message")
                        .environment(\.symbolVariants, selectedTab == 4 ? .fill : .none)
                    
                    Text("Reviews")
                }
            
                .onAppear { selectedTab = 4 }
                .tag(4)
        }
        .tint(.black)
    }
}

#Preview {
    RestaurantTab()
}
