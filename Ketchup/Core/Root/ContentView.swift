//
//  ContentView.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI
import FirebaseAuth
struct ContentView: View {
    var tabBarController = TabBarController()
    @StateObject var viewModel: ContentViewModel = ContentViewModel()
    
    
    var body: some View {
        Group {
            if Auth.auth().currentUser != nil {
                MainTabView()
                    .environmentObject(viewModel)
                    .environmentObject(tabBarController)
                    .customFont()
                
            } else if viewModel.userSession == nil {
                LoginView()
                    .customFont()
            }
        }   
    }
}

#Preview {
    ContentView()
}
