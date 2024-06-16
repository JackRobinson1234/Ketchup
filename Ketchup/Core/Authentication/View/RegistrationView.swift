//
//  RegistrationView.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI

struct RegistrationView: View {
    @StateObject var viewModel = RegistrationViewModel()
    @Environment(\.dismiss) var dismiss
    var passwordDebouncer = Debouncer(delay: 1.0)
    var usernameDebouncer = Debouncer(delay: 2.0)
    var emailDebouncer = Debouncer(delay: 1.0)
    var maxRegistrationDebouncer = Debouncer(delay: 20.0)
    var maxRegistrationAttempts = 5
    
//    init(service: AuthService) {
//        self.service = service
//        //self._viewModel = StateObject(wrappedValue: RegistrationViewModel(service: service))
//    }
//    
    var body: some View {
        VStack {
            Spacer()
            
            // logo image
            Text("Foodi Sign Up")
            
            // MARK: Email
            VStack {
                
                TextField("Enter your email", text: $viewModel.email)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .modifier(StandardTextFieldModifier())
                    .onChange(of: viewModel.email){
                        emailDebouncer.schedule{
                            viewModel.isValidEmail()
                        }
                    }
                //MARK: Email Checkmark
                    .overlay(alignment: .trailing){
                        if let validEmail = viewModel.validRegistrationEmail, validEmail == true {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                                .padding(.trailing, 30)
                        }
                    }
                if let validEmail = viewModel.validRegistrationEmail, !viewModel.email.isEmpty && !validEmail {
                    Text("Please enter a valid email address")
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .font(.caption)
                }
                // MARK: Password
                
                SecureField("Enter your password", text: $viewModel.password)
                    .modifier(StandardTextFieldModifier())
                    .onChange(of: viewModel.password) {
                        passwordDebouncer.schedule{
                            viewModel.isValidPassword()
                        }
                    }
                //MARK: Password checkmark
                    .overlay(alignment: .trailing){
                        if let validPassword = viewModel.validPassword, validPassword == true {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                                .padding(.trailing, 30)
                        }
                        
                    }
                
                if let validPassword = viewModel.validPassword, !viewModel.password.isEmpty && !validPassword {
                    Text("Password must be at least 6 characters")
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .font(.caption)
                }
                // MARK: Full Name
                
                TextField("Enter your name", text: $viewModel.fullname)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .modifier(StandardTextFieldModifier())
                    .onChange(of: viewModel.fullname) {oldValue, newValue in
                        if newValue.count > 64 {
                            viewModel.fullname = String(newValue.prefix(64))
                        }
                    }
                
                //MARK: fullname check mark
                    .overlay(alignment: .trailing){
                        if !viewModel.fullname.isEmpty {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                                .padding(.trailing, 30)
                        }
                    }
                if viewModel.fullname.count == 64 {
                    Text("Max 64 Characters")
                        .font(.caption)
                }
                
                
                // MARK: Username
                
                TextField("Create a username", text: $viewModel.username)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                    .modifier(StandardTextFieldModifier())
                    .onChange(of: viewModel.username) {oldValue, newValue in
                        //lowercase and no space
                        viewModel.username = viewModel.username.trimmingCharacters(in: .whitespaces).lowercased()
                        //limits characters
                        if newValue.count > 30 {
                            viewModel.username = String(newValue.prefix(30))
                        }
                        //for the debouncer to wait
                        viewModel.validUsername = nil
                        if !viewModel.username.isEmpty{
                            usernameDebouncer.schedule{
                                Task{
                                    try await viewModel.checkIfUsernameAvailable()
                                }
                            }
                        }
                    }
                //MARK: Username CheckMark
                    .overlay(alignment: .trailing){
                        if let validUsername = viewModel.validUsername, validUsername == true {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                                .padding(.trailing, 30)
                        }
                    }
                
                //MARK: Username availability
                if viewModel.username.count == 30 {
                    Text("Max 30 Characters")
                        .font(.caption)
                }
                if viewModel.validUsername == nil && !viewModel.username.isEmpty{
                    Text("Checking if username is available...")
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
                else if let validUsername = viewModel.validUsername, validUsername && !viewModel.username.isEmpty{
                    Text("Username Available!")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if let validUsername = viewModel.validUsername, !validUsername && !viewModel.username.isEmpty{
                    Text("Username is already taken. Please try a different username")
                        .font(.caption)
                        .foregroundStyle(Color("Colors/AccentColor"))
                }
            }
            // MARK: Sign up button
            Button {
                Task { 
                    //checks if username got taken in last few seconds
                    try await viewModel.checkIfUsernameAvailable()
                    if let validUsername = viewModel.validUsername, validUsername {
                        try await viewModel.createUser() }
                }
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
            .disabled(viewModel.registrationAttempts >= maxRegistrationAttempts)
            .opacity(formIsValid && viewModel.registrationAttempts < maxRegistrationAttempts ? 1 : 0.7)
            .padding(.vertical)
            if viewModel.registrationAttempts >= maxRegistrationAttempts{
                Text("Please wait 20 seconds before attempting to register again")
                    .font(.caption)
                    .foregroundStyle(Color("Colors/AccentColor"))
            }
            if viewModel.showAlert {
                Text("An account with that email already exists, please try another email")
                    .font(.caption)
                    .foregroundStyle(Color("Colors/AccentColor"))
            }
            Divider()
            Text("Or")
                .font(.caption)
            //MARK: Google Sign Up Button
            Button{
                Task{
                    try await AuthService.shared.signInWithGoogle()
                }
            } label: {
                Image("Google-SignUp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
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
//        .alert(isPresented: $viewModel.showAlert) {
//            Alert(title: Text("Error"),
//                  message: Text(viewModel.authError?.description ?? ""))
//        }
        .modifier(BackButtonModifier())
        .onChange(of: viewModel.registrationAttempts) {
            if viewModel.registrationAttempts >= maxRegistrationAttempts{
                maxRegistrationDebouncer.schedule{
                    viewModel.registrationAttempts = 0
                }
            }
        }
    }
}

// MARK: - Form Validation

extension RegistrationView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        if let validUsername = viewModel.validUsername, let validEmail = viewModel.validRegistrationEmail, let validPassword = viewModel.validPassword{
            return !viewModel.email.isEmpty
            && validEmail
            && !viewModel.password.isEmpty
            && validPassword
            && !viewModel.fullname.isEmpty
            && validUsername
        }
        else{
            return false
        }
    }
}
#Preview {
    RegistrationView()
}
