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
    @Published var userSession: User?
    
    private var cancellables = Set<AnyCancellable>()
    private let userService: UserService
    
    init(userService: UserService) {
        self.userService = userService
        Task {
            try await AuthService.shared.updateUserSession()
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
}
