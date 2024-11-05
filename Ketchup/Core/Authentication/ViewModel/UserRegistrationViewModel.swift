//
//  UserRegistrtationViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/14/24.
//

import Foundation
import Firebase
import FirebaseFirestore
class UserRegistrationViewModel: ObservableObject {
    @Published var username: String?
    @Published var birthday: Date?
    @Published var location: Location?
    @Published var fullname: String?
    @Published var referrer: User?

    func updateUser() async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "UserRegistration", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        do {
            let updatedUser = try await AuthService.shared.updateFirestoreUser(
                id: userID,
                username: username,
                fullname: fullname,
                birthday: birthday,
                location: location,
                hasCompletedSetup: true,
                referrer: referrer?.id,
                generateReferralCode: true
            )
            
            Task{
                ////print("Successfully updated user: \(updatedUser)")
                try await AuthService.shared.createContactAlertUser(user: updatedUser)
                // Update the user session
                try await AuthService.shared.updateUserSession()
            }
        } catch {
            ////print("Failed to update user: \(error.localizedDescription)")
            throw error
        }
    }
}
