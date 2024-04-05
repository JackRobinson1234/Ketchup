//
//  LoginViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import Firebase

@MainActor
class LoginViewModel: ObservableObject {
    @Published var showAlert = false
    @Published var authError: AuthError?
    @Published var isAuthenticating = false
    @Published var email = ""
    @Published var password = ""
    
    private let service: AuthService
    
    init(service: AuthService) {
        self.service = service
    }
    
    func login() async {
        isAuthenticating = true
        
        do {
            try await service.login(withEmail: email, password: password)
            isAuthenticating = false
        } catch {
            let authError = AuthErrorCode.Code(rawValue: (error as NSError).code)
            self.showAlert = true
            isAuthenticating = false
            self.authError = AuthError(authErrorCode: authError ?? .userNotFound)
        }
    }
}
