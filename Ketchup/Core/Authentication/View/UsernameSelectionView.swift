//
//  UsernameSelectionView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/13/24.
//

import SwiftUI
import FirebaseFirestoreInternal
import FirebaseAuth
import Contacts

struct UsernameSelectionView: View {
    @StateObject private var viewModel = UsernameSelectionViewModel()
    @Environment(\.dismiss) private var dismiss
    @StateObject var registrationViewModel: UserRegistrationViewModel = UserRegistrationViewModel()
    @State private var isContactsPermissionDenied = false
    
    var body: some View {
        NavigationStack{
            VStack(alignment: .leading, spacing: 20) {
                Image("KetchupTextRed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                
                Text("Hey! Welcome to Ketchup, please enter your name and choose a username")
                    .font(.custom("MuseoSansRounded-700", size: 26))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
//                Color.clear
//                    .onAppear{
//                        Task{
//                            AuthService.shared.userSession = nil
//                            try Auth.auth().signOut()
//                        }
//                    }
                
                // Full Name TextField
                TextField("Name", text: $viewModel.fullName)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .onChange(of: viewModel.fullName) { newValue in
                        viewModel.validateFullName(newValue)
                    }
                
                if viewModel.showFullNameWarning {
                    Text(viewModel.fullNameWarningMessage)
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                
                // Username TextField
                HStack {
                    Text("@")
                        .foregroundColor(.gray)
                    TextField("Username", text: $viewModel.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: viewModel.username) { newValue in
                            viewModel.validateAndCheckUsername(newValue)
                        }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                if viewModel.isChecking {
                    Text("Checking availability...")
                        .foregroundColor(.gray)
                } else if !viewModel.username.isEmpty {
                    if let isAvailable = viewModel.isUsernameAvailable {
                        Text(isAvailable ? "Username is available!" : "Username is already taken")
                            .foregroundColor(isAvailable ? .green : .red)
                    }
                }
                
                if viewModel.showInvalidCharWarning {
                    Text("Username can only contain letters, numbers, periods, and underscores")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if viewModel.showMaxCharReachedWarning {
                    Text("Maximum character limit reached (25)")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.saveUsernameAndFullName()
                }) {
                    Text("Save")
                        .font(.custom("MuseoSansRounded-500", size: 20))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canSave ? Color("Colors/AccentColor") : Color.gray)
                        .cornerRadius(25)
                }
                .disabled(!viewModel.canSave)
            }
            .padding(.horizontal)
           
            .padding(.top, 10)
          
            .onChange(of: viewModel.username) { newValue in
                registrationViewModel.username = newValue
            }
            .onChange(of: viewModel.fullName) { newValue in
                registrationViewModel.fullname = newValue
            }
            .padding()
            .navigationBarBackButtonHidden(true)
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text(viewModel.alertTitle),
                      message: Text(viewModel.alertMessage),
                      dismissButton: .default(Text("OK")) {
                    if viewModel.shouldDismiss {
                        dismiss()
                    }
                })
            }
            .navigationDestination(isPresented: $viewModel.navigateToBirthdaySelection) {
                BirthdaySelectorView(selectedBirthday: $viewModel.selectedBirthday, registrationViewModel:registrationViewModel)
            }
            .onAppear{
                if let userSession = AuthService.shared.userSession{
                    if userSession.birthday == nil {
                        registrationViewModel.username = nil
                        registrationViewModel.fullname = nil
                        viewModel.navigateToBirthdaySelection = true
                    }
                }
            }

        }
    }
    private func checkContactsPermissionAndSync() {
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            isContactsPermissionDenied = true
        } else if authorizationStatus == .notDetermined {
            CNContactStore().requestAccess(for: .contacts) { granted, _ in
                DispatchQueue.main.async {
                    isContactsPermissionDenied = !granted
                    if granted {
                        startContactSync()
                    }
                }
            }
        } else if authorizationStatus == .authorized {
            startContactSync()
        }
    }
    
    private func startContactSync() {
        if AuthService.shared.userSession?.contactsSynced == false {
            Task {
                try await ContactService.shared.syncDeviceContacts()
            }
        }
    }
}


