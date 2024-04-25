//
//  LoginViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import Firebase
import GoogleSignIn
import FirebaseAuth
import GoogleSignInSwift
import SwiftUI
@MainActor
class LoginViewModel: ObservableObject {
    @Published var showAlert = false
    @Published var authError: AuthError?
    @Published var isAuthenticating = false
    @Published var email = ""
    @Published var password = ""
    @Published var resetEmailText = ""
    var debouncer = Debouncer(delay: 60.0)
    @Published var canResetEmail = true
    @Published var validLoginEmail = false
    @Published var validResetEmail = false
    @Published var validPassword = false
    
    //UI Timer
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @Published var timeRemaining = 60
    
    
    private let service: AuthService
    
    init(service: AuthService) {
        self.service = service
    }
    //MARK: login
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
    //MARK: sendResetEmail
    func SendResetEmail() async throws {
        if canResetEmail {
            timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            try await service.sendResetPasswordLink(toEmail: resetEmailText)
            canResetEmail = false
            debouncer.schedule {
                self.canResetEmail = true
                self.timeRemaining = 60
                self.timer.upstream.connect().cancel()
            }
        }
    }
    
    func isValidLoginEmail(){
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        self.validLoginEmail = emailPredicate.evaluate(with: self.email)
    }
    func isValidResetEmail() {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        self.validResetEmail = emailPredicate.evaluate(with: self.resetEmailText)
    }
    func isValidPassword() {
        validPassword = password.count > 5
    }
}
