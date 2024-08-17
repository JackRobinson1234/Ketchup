//
//  AuthCoordinator.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/14/24.
//

import SwiftUI
import Combine

@MainActor
class AuthCoordinator: ObservableObject {
    @Published var currentView: AuthView = .welcome
    
    enum AuthView {
        case welcome
        case phoneVerification
        case userDetails
        case mainFeed
    }
    
    init() {
        Task {
            await setupUserSessionObserver()
        }
    }
    
    private func setupUserSessionObserver() async {
        for await _ in AuthService.shared.$userSession.values {
            await handleUserSessionChange()
        }
    }
    
    private func handleUserSessionChange() async {
        if AuthService.shared.userSession != nil {
            // User is signed in and has a profile
            currentView = .mainFeed
        } else {
            // No user is signed in
            currentView = .welcome
        }
    }
    
    func moveToPhoneVerification() {
        currentView = .phoneVerification
    }
    
    func moveToUserDetails() {
        currentView = .userDetails
    }
    
    func moveToMainFeed() {
        currentView = .mainFeed
    }
}
