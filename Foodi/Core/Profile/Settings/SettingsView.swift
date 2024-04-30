//
//  SettingsView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/25/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    private let userService: UserService
    @StateObject var viewModel: SettingsViewModel
    private let authService: AuthService
    @State var showDeleteAccountAlert: Bool = false
    private let user: User
    @State var needsReauth = false
    
    init(userService: UserService, authService: AuthService, user: User) {
        self.user = user
        self.authService = authService
        self.userService = userService
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(userService: userService, authService: authService, user: user))
    }
    var body: some View {
        NavigationStack{
            VStack{
                Button("Sign Out") {
                    authService.signout()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding()
                Divider()
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
                            needsReauth = try await viewModel.checkAuthStatusForDeletion()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: { user in
                    Text("Confirm account deletion for \(user.username). This action can not be undone.")
                }
            }
            .sheet(isPresented: $needsReauth) {
                LoginView(service: authService, reAuthDelete: true)
            }
            //        .onChange(of: viewModel.confirmDeleteAccount()) {
            //            if confirmDeleteAccount{
            //                viewModel.deleteAccount()
            //            }
            //        }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.5)) // Adjust the opacity as needed
                                    .frame(width: 30, height: 30) // Adjust the size as needed
                            )
                            .padding()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


#Preview {
    SettingsView(userService: UserService(), authService: AuthService(), user: DeveloperPreview.users[0])
}
