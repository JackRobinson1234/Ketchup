//
//  SettingsView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/25/24.
//

import SwiftUI
import FirebaseFirestoreInternal

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: SettingsViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    @State var needsReauth = false
    @State private var showPrivateModeDropdown = false
    @State var showDeleteAccountAlert: Bool = false
    @State var showOptOutAlert: Bool = false
    @State private var toggleEnabled = true
    var privateRateDebouncer = Debouncer(delay: 1.0)

    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(profileViewModel: profileViewModel))
    }

   
    var body: some View {
        NavigationStack {
            List {
                // Privacy Policy
                Button(action: {
                    if let url = URL(string: "https://ketchup-app.com/privacy-policy/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Privacy Policy", systemImage: "lock.shield")
                        .foregroundColor(.black)
                }

                // Terms of Service
                Button(action: {
                    if let url = URL(string: "https://ketchup-app.com/terms-of-service/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Terms of Service", systemImage: "doc.text")
                        .foregroundColor(.black)
                }

                // End User License Agreement
                Button(action: {
                    if let url = URL(string: "https://ketchup-app.com/end-user-license-agreement/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("End User License Agreement", systemImage: "signature")
                        .foregroundColor(.black)
                }

                // Private Mode
                Button {
                    showPrivateModeDropdown.toggle()
                } label: {
                    HStack {
                        Label("Private Mode", systemImage: "eye.slash")
                        Spacer()
                        Text(viewModel.privateMode ? "On" : "Off")
                            .foregroundColor(.gray)
                        Image(systemName: showPrivateModeDropdown ? "chevron.down" : "chevron.right")
                    }
                }

                if showPrivateModeDropdown {
                    HStack {
                        Text("When in private mode, ALL users will not be able to see any of your posts, collections, or liked posts.")
                            .foregroundColor(.gray)
                            .font(.footnote)
                        Spacer()
                        Toggle("", isOn: $viewModel.privateMode)
                            .labelsHidden()
                            .disabled(!toggleEnabled)
                            .onChange(of: viewModel.privateMode) { newValue in
                                Task {
                                    toggleEnabled = false
                                    try await viewModel.updatePrivateMode()
                                }
                                privateRateDebouncer.schedule {
                                    toggleEnabled = true
                                }
                            }
                    }
                }

                // Opt Out
                Button {
                    showOptOutAlert = true
                } label: {
                    Label("Opt out of data storage", systemImage: "trash")
                        .foregroundColor(.black)
                }
                .alert("Opt out of data storage", isPresented: $showOptOutAlert) {
                    Button("Confirm", role: .destructive) {
                        Task {
                            await viewModel.createOptOutDocument()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to opt out of your personal data being stored on Ketchup's servers?")
                }

                // Sign Out
                Button {
                    AuthService.shared.signout()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.black)
                }

                // Delete Account
                Button {
                    showDeleteAccountAlert = true
                } label: {
                    Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                        .foregroundColor(.red)
                }
                .alert("Delete account", isPresented: $showDeleteAccountAlert, presenting: profileViewModel.user) { user in
                    Button("Delete Account", role: .destructive) {
                        Task {
                            needsReauth = try await viewModel.checkAuthStatusForDeletion()
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: { user in
                    Text("Confirm account deletion for \(user.username). This action cannot be undone.")
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 30, height: 30)
                            )
                            .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $needsReauth) {
            PhoneAuthView(isDelete: true)
        }
    }
}
extension SettingsViewModel {
    // Firestore logic for creating an opt-out document
    func createOptOutDocument() async {
        let db = Firestore.firestore()
        let userId = profileViewModel.user.id
        
        let data = [
            "userId": userId,
            "optOut": true,
            "timestamp": FieldValue.serverTimestamp()
        ] as [String : Any]
        
        do {
            try await db.collection("optOuts").document(userId).setData(data)
        } catch {
            print("Error creating opt-out document: \(error.localizedDescription)")
        }
    }
}
