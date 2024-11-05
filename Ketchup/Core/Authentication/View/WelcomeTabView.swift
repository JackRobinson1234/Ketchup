//
//  WelcomeTabView.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/2/24.
//

import SwiftUI

struct WelcomeTabView: View {
    @Binding var isPresented: Bool
    @State private var selectedTab = 0
    
    let tabs = [
        WelcomeTab(title: "Welcome", image: "hand.wave.fill", points: [
            "Discover new restaurants",
            "Share your dining experiences",
            "Connect with food-loving friends",
            "Stay up-to-date with food trends"
        ]),
        WelcomeTab(title: "Home", image: "house.fill", points: [
            "See posts from followed restaurants",
            "View friends' recent activities",
            "Interact with posts through likes and comments",
            "Get personalized restaurant recommendations"
        ]),
        WelcomeTab(title: "Map", image: "map.fill", points: [
            "Explore restaurants near you",
            "See where friends are posting from",
            "Find highly-rated spots in any area",
            "Get directions to your chosen restaurant"
        ]),
        WelcomeTab(title: "Post", image: "plus.app.fill", points: [
            "Share photos of your meals",
            "Rate restaurants on food, atmosphere, and service",
            "Write detailed reviews of your experience",
            "Tag friends and locations in your posts"
        ]),
        WelcomeTab(title: "Discover", image: "flame.fill", points: [
            "Participate in daily food polls",
            "Find trending restaurants and dishes",
            "Explore curated lists and collections",
            "Discover new cuisines and food experiences"
        ]),
        WelcomeTab(title: "Profile", image: "person.fill", points: [
            "View your post history",
            "Track your restaurant visits",
            "Manage your account settings",
            "See your impact and engagement stats"
        ])
    ]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(0..<tabs.count, id: \.self) { index in
                VStack(spacing: 20) {
                    Image(systemName: tabs[index].image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(Color("Colors/AccentColor"))
                    
                    Text(tabs[index].title)
                        .font(.custom("MuseoSansRounded-700", size: 24))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(tabs[index].points, id: \.self) { point in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .padding(.top, 6)
                                Text(point)
                                    .font(.custom("MuseoSansRounded-500", size: 16))
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if index == tabs.count - 1 {
                        Button("Get Started") {
                            isPresented = false
                        }
                        .font(.custom("MuseoSansRounded-700", size: 18))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("Colors/AccentColor"))
                        .cornerRadius(10)
                        .padding(.top)
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

struct WelcomeTab {
    let title: String
    let image: String
    let points: [String]
}

