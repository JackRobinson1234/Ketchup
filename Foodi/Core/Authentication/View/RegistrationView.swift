//
//  RegistrationView.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI

struct RegistrationView: View {
    @StateObject var viewModel: RegistrationViewModel
    @Environment(\.dismiss) var dismiss
    var debouncer = Debouncer(delay: 2.0)
    private let service: AuthService
    
    init(service: AuthService) {
        self.service = service
        self._viewModel = StateObject(wrappedValue: RegistrationViewModel(service: service))
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            // logo image
            Text("Foodi Login")
            
            // MARK: Email
            VStack {
                TextField("Enter your email", text: $viewModel.email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .modifier(StandardTextFieldModifier())
                    .onChange(of: viewModel.email){
                        viewModel.isValidEmail()
                    }
                if !viewModel.email.isEmpty && !viewModel.validRegistrationEmail {
                    Text("Please enter a valid email address")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                // MARK: Password
                SecureField("Enter your password", text: $viewModel.password)
                    .modifier(StandardTextFieldModifier())
                    .onChange(of: viewModel.password) {
                        viewModel.isValidPassword()
                    }
                
                if !viewModel.password.isEmpty && !viewModel.validPassword {
                    Text("Password must be at least 6 characters")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                // MARK: Full Name
                TextField("Enter your full name", text: $viewModel.fullname)
                    .autocapitalization(.none)
                    .modifier(StandardTextFieldModifier())
                
                
                // MARK: Username
                TextField("Create a username", text: $viewModel.username)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                    .modifier(StandardTextFieldModifier())
                    .onChange(of: viewModel.username) {
                        viewModel.validUsername = nil
                        if !viewModel.username.isEmpty{
                        debouncer.schedule{
                            Task{
                                try await viewModel.checkIfUsernameAvailable()
                            }
                        }
                    }
                }
                if let validUsername = viewModel.validUsername, validUsername && !viewModel.username.isEmpty{
                    Text("Username Available!")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if let validUsername = viewModel.validUsername, !validUsername && !viewModel.username.isEmpty{
                    Text("Username is already taken. Please Try another")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            // MARK: Sign up button
            Button {
                Task { try await viewModel.createUser() }
            } label: {
                Text(viewModel.isAuthenticating ? "" : "Sign up")
                    .modifier(StandardButtonModifier())
                    .overlay {
                        if viewModel.isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    
            }
            .disabled(viewModel.isAuthenticating || !formIsValid)
            .opacity(formIsValid ? 1 : 0.7)
            .padding(.vertical)
            Divider()
            Text("Or")
                .font(.caption)
            Button{
                Task{
                    try await service.signInWithGoogle()
                }
            } label: {
                Image("Google-SignUp")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 50, alignment: .center)
            }
            Spacer()
            
            Divider()
            
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Text("Already have an account?")
                    
                    Text("Sign in")
                        .fontWeight(.semibold)
                }
                .font(.footnote)
            }
            .padding(.vertical, 16)
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error"),
                  message: Text(viewModel.authError?.description ?? ""))
        }
        .modifier(BackButtonModifier())
    }
}

// MARK: - Form Validation

extension RegistrationView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !viewModel.email.isEmpty
        && viewModel.email.contains("@")
        && !viewModel.password.isEmpty
        && !viewModel.fullname.isEmpty
        && viewModel.password.count > 5
    }
}

#Preview {
    RegistrationView(service: AuthService())
}
