//
//  ContentView.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI

struct ContentView: View {
    private let authService: AuthService
    private let userService: UserService
    
    var tabBarController = TabBarController()
    
    @StateObject var viewModel: ContentViewModel
    
    init(authService: AuthService, userService: UserService) {
        self.authService = authService
        self.userService = userService
        
        let contentViewModel = ContentViewModel(authService: authService, userService: userService)
        self._viewModel = StateObject(wrappedValue: contentViewModel)
    }
    
    var body: some View {
        Group {
            if viewModel.userSession != nil {
                    MainTabView(authService: authService, userService: userService)
                        .environmentObject(viewModel)
                        .environmentObject(tabBarController)
                } else {
                LoginView(service: authService)
            }
        }
    }
}

#Preview {
    ContentView(authService: AuthService(), userService: UserService())
}
