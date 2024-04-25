//
//  SettingsView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/25/24.
//

import SwiftUI

struct SettingsView: View {
    private let userService: UserService
    @StateObject var viewModel: SettingsViewModel
    private let authService: AuthService
    @State var showDeleteAccountAlert: Bool = false
    private let user: User
    init(userService: UserService, authService: AuthService, user: User) {
        self.user = user
        self.authService = authService
        self.userService = userService
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(userService: userService, authService: authService, user: user))
    }
    var body: some View {
        Button{
            showDeleteAccountAlert = true
        } label: {
            Text("Delete Account")
                .font(.caption)
                .foregroundStyle(.red)
        }
        .alert("Delete account", isPresented: $showDeleteAccountAlert, presenting: user) { user in
            Button("Delete Account", role: .destructive) {
                Task{
                    try await viewModel.deleteAccount()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { user in
            Text("Confirm account deletion for \(user.username). This action can not be undone.")
        }
    }
}
#Preview {
    SettingsView(userService: UserService(), authService: AuthService(), user: DeveloperPreview.users[0])
}
