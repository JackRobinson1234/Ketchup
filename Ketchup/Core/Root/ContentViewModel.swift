//
//  ContentVIewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Combine
import Firebase
import SwiftUI
@MainActor
class ContentViewModel: ObservableObject {
    @Published var userSession: User?
    @Published var isLoading = true
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        Task {
            try await AuthService.shared.updateUserSession()
            isLoading = false
        }
        setupSubscribers()
    }

    @MainActor
    func setupSubscribers() {
        AuthService.shared.$userSession.sink { [weak self] session in
            self?.userSession = session
        }
        .store(in: &cancellables)
    }

    var isProfileComplete: Bool {
        // Check if userSession is complete. Here we assume `hasCompletedProfile` is part of the User model.
        return userSession?.hasCompletedSetup ?? false
    }
    
    var isOnWaitlist: Bool {
       
        return (userSession?.waitlistNumber ?? 0 > 0)
    }
}
