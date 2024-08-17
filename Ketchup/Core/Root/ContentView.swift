//
//  ContentView.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI
import FirebaseAuth
import SwiftUI
import FirebaseAuth
struct ContentView: View {
    @EnvironmentObject var tabBarController: TabBarController
    @StateObject var viewModel: ContentViewModel = ContentViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ZStack{
                    FallingFoodView(isStatic: true)
                    VStack(spacing: 10) {
                        Spacer()
                        Image("SkipFill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                        
                        Image("KetchupTextRed")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                        FastCrossfadeFoodImageView()
                            .foregroundStyle(Color("Colors/AccentColor"))
                        Spacer()
                        Spacer()
                    }
                }
            } else if let user = viewModel.userSession {
                if viewModel.isProfileComplete {
                    MainTabView()
                        .environmentObject(viewModel)
                        .environmentObject(tabBarController)
                        .customFont()
                        .onAppear {
                            checkInitialNavigation()
                        }
                } else if user.phoneNumber != nil{
                    UsernameSelectionView()
                } else {
                    PhoneAuthView()
                }
            } else {
                WelcomeView()
                    .customFont()
            }
        }
    }
    private func checkInitialNavigation() {
        if let initialTab = UserDefaults.standard.object(forKey: "initialTab") as? Int {
            NotificationCenter.default.post(name: .navigateToProfile, object: nil, userInfo: ["tab": 4])
            UserDefaults.standard.removeObject(forKey: "initialTab")
        }
    }
}


