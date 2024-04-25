//
//  SettingsViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/25/24.
//

import Foundation
class SettingsViewModel: ObservableObject{
    private let userService: UserService
    private let authService: AuthService
    private let collectionsService = CollectionService()
    private let postService = PostService()
    private let user: User
    
    init(userService: UserService, authService: AuthService, user: User) {
        self.userService = userService
        self.authService = authService
        self.user = user
    }
    func deleteAccount() async throws {
        
    }
}
