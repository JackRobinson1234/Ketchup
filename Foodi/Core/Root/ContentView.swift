//
//  ContentView.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI

struct ContentView: View {
    var tabBarController = TabBarController()
    @StateObject var viewModel: ContentViewModel = ContentViewModel()
    
    
    var body: some View {
        Group {
            if viewModel.userSession != nil {
                    MainTabView()
                        .environmentObject(viewModel)
                        .environmentObject(tabBarController)
                    
                } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
}
