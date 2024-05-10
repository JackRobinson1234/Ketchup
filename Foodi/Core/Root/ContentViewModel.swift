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
    private var cancellables = Set<AnyCancellable>()
    @State var isLoading = true
    
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
}
