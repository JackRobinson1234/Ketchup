//
//  ContentVIewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Combine
import Firebase

@MainActor
class ContentViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    
    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthService
    private let userService: UserService
    
    init(authService: AuthService, userService: UserService) {
        self.authService = authService
        self.userService = userService
        authService.updateUserSession()
        setupSubscribers()
    }
    @MainActor
    func setupSubscribers() {
        print("Debug1: SetupSubscribers is running")
            authService.$userSession.sink { [weak self] session in
                self?.userSession = session
               
            }
            .store(in: &cancellables)
        
        
        }
}
