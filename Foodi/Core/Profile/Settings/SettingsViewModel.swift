//
//  SettingsViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/25/24.
//

import Foundation
import FirebaseAuth
import AuthenticationServices
import SwiftUI
import Firebase

class SettingsViewModel: ObservableObject{
    private let userService: UserService
    private let authService: AuthService
    private let collectionsService = CollectionService()
    private let postService = PostService()
    @ObservedObject var profileViewModel: ProfileViewModel
    @Published var needsReauth: Bool = false
    @Published var privateMode: Bool
    
    init(userService: UserService, authService: AuthService, profileViewModel: ProfileViewModel) {
        self.userService = userService
        self.authService = authService
        self.profileViewModel = profileViewModel
        self.privateMode = profileViewModel.user.privateMode
    }
    
    
    func checkAuthStatusForDeletion() async throws -> Bool {
        guard let user = Auth.auth().currentUser else {return false}
        guard let lastSignInDate = user.metadata.lastSignInDate else {
        return false}
        let readyForDelete = lastSignInDate.isWithinPast(minutes:1)
        if !readyForDelete {
            return true
        } else {
            try await authService.deleteAccount()
            return false
        }
    }
    func updatePrivateMode() async throws {
        if self.privateMode != profileViewModel.user.privateMode {
            try await userService.updatePrivateMode(newValue: self.privateMode)
            profileViewModel.user.privateMode = privateMode
        }
    }
}


extension Date {
    func isWithinPast(minutes: Int) -> Bool {
        let now = Date.now
        let timeAgo = Date.now.addingTimeInterval(-1 * TimeInterval(60 * minutes))
        let range = timeAgo...now
        return range.contains(self)
    }
}

enum AuthenticationError: Error {
    case tokenError(message: String)
}
