//
//  RegistrationViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import Foundation
import Firebase
import SwiftUI
@MainActor
class RegistrationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullname = ""
    @Published var username = ""
    @Published var isAuthenticating = false
    @Published var showAlert = false
    @Published var authError: AuthError?
    
    @Published var validRegistrationEmail = false
    @Published var validPassword = false
    @Published var validUsername: Bool? = nil
    
    private let service: AuthService
    
    init(service: AuthService) {
        self.service = service
    }
    
    @MainActor
    func createUser() async throws {
        isAuthenticating = true
        do {
            try await service.createUser(
                email: email,
                password: password,
                username: username,
                fullname: fullname
            )
            isAuthenticating = false
        } catch {
            let authErrorCode = AuthErrorCode.Code(rawValue: (error as NSError).code)
            showAlert = true
            isAuthenticating = false
            authError = AuthError(authErrorCode: authErrorCode ?? .userNotFound)
        }
    }
    func isValidEmail(){
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        self.validRegistrationEmail = emailPredicate.evaluate(with: self.email)
    }
    func isValidPassword() {
        validPassword = password.count > 5
    }
    func checkIfUsernameAvailable() async throws {
        let query = FirestoreConstants.UserCollection.whereField("username", isEqualTo: self.username)
        let querySnapshot = try await query.getDocuments()
        if querySnapshot.documents.isEmpty {
           validUsername = true
        } else {
            validUsername = false
        }
    }
}
