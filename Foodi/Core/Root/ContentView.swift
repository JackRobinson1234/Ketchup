//
//  ContentView.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI

struct ContentView: View {
    private let userService: UserService
    
    var tabBarController = TabBarController()
    
    @StateObject var viewModel: ContentViewModel
    
    init(userService: UserService) {
        self.userService = userService
        
        let contentViewModel = ContentViewModel(userService: userService)
        self._viewModel = StateObject(wrappedValue: contentViewModel)
    }
    
    var body: some View {
        Group {
            if viewModel.userSession != nil {
                    MainTabView(userService: userService)
                        .environmentObject(viewModel)
                        .environmentObject(tabBarController)
                    
                } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView(userService: UserService())
}
