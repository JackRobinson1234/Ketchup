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
    private let collectionsService = CollectionService()
    private let postService = PostService()
    @ObservedObject var profileViewModel: ProfileViewModel
    @Published var needsReauth: Bool = false
    @Published var privateMode: Bool
    
    init( profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        self.privateMode = profileViewModel.user.privateMode
    }
    
    //MARK: checkAuthStatusForDeletion
    /// Checks if a sign in was done in the past 5 minutes. If so, it deletes the account and sets the usersession to nil. Otherwise, it sets up the reauth screen.
    func checkAuthStatusForDeletion() async throws -> Bool {
        guard let user = Auth.auth().currentUser else {return false}
        guard let lastSignInDate = user.metadata.lastSignInDate else {
        return false}
        let readyForDelete = lastSignInDate.isWithinPast(minutes: 5)
        if !readyForDelete {
            return true
        } else {
            try await AuthService.shared.deleteAccount()
            return false
        }
    }
    //MARK: updatePrivateMode
    /// Changes the user to new private setting, the collections to the new private setting, and the posts to the new private setting. COLLECTIONS/ POSTS UPDATED IN CLOUD FUNCTION
    func updatePrivateMode() async throws {
        if self.privateMode != profileViewModel.user.privateMode {
            profileViewModel.user.privateMode = privateMode
            try await UserService.shared.updatePrivateMode(newValue: self.privateMode)
        }
    }
}


extension Date {
    //MARK: isWithinPast
    /// Checks to see if the time is within the past number of minutes
    /// - Parameter minutes: datetime to be checked
    /// - Returns: boolean if the time is within the past minutes
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
