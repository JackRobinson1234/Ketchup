//
//  RegistrationViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import Foundation
import FirebaseAuth

class RegistrationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullname = ""
    @Published var username = ""
    @Published var isAuthenticating = false
    @Published var showAlert = false
    @Published var authError: AuthError?
    
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
}
