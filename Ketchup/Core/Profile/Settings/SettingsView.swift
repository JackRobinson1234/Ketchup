//
//  SettingsView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/25/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: SettingsViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    @State var needsReauth = false
    @State private var showPrivateModeDropdown = false
    @State var showDeleteAccountAlert: Bool = false
    @State private var toggleEnabled = true
    var privateRateDebouncer = Debouncer(delay: 1.0)

    
    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(profileViewModel: profileViewModel))
    }
    
    var body: some View {
        NavigationStack{
            VStack{
                //MARK: Private Mode
                Button{
                    showPrivateModeDropdown.toggle()
                } label: {
                    HStack {
                        Text("Private Mode")
                            .foregroundStyle(.black)
                        Spacer()
                        Text(viewModel.privateMode ? "On" : "Off")
                               .foregroundColor(.gray)
                        if showPrivateModeDropdown == false {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.black)
                        } else {
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.black)
                        }
                    }
                    .padding()
                }
                
                //MARK: Private Mode Dropdown
                if showPrivateModeDropdown {
                        HStack {
                            Text("When in private mode, ALL users will not be able to see any of your posts, collections, or liked posts")
                                .foregroundColor(.gray)
                                .font(.custom("MuseoSansRounded-300", size: 10))
                            Spacer()
                            Toggle("", isOn: $viewModel.privateMode)
                                .labelsHidden()
                                .disabled(!toggleEnabled) // Disable the toggle based on the toggleEnabled state
                                .onChange(of: viewModel.privateMode) {
                                    Task {
                                        // Disable the toggle for 20 seconds
                                        toggleEnabled = false
                                        try await viewModel.updatePrivateMode()
                                    }
                                    privateRateDebouncer.schedule{
                                        toggleEnabled = true
                                    }
                                }
                        }
                        .padding()
                    }
                
                
                
                Divider()
                Spacer()
                //MARK: Sign Out
                Button{
                    AuthService.shared.signout()
                } label: {
                    Text("Sign Out")
                        .foregroundStyle(.black)
                        .padding()
                }
                .font(.custom("MuseoSansRounded-300", size: 16))
                .fontWeight(.semibold)
                .padding()
                Divider()
                
                //MARK: Delete Account
                Button{
                    showDeleteAccountAlert = true
                } label: {
                    Text("Delete Account")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundStyle(Color("Colors/AccentColor"))
                }
                //MARK: Delete Account Alert
                .alert("Delete account", isPresented: $showDeleteAccountAlert, presenting: profileViewModel.user) { user in
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
                PhoneAuthView(isDelete: true)
            }
           
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
    SettingsView(profileViewModel: ProfileViewModel(uid: ""))
}
