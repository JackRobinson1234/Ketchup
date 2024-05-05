//
//  LoginView.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI
import GoogleSignIn
import FirebaseAuth
import GoogleSignInSwift
struct LoginView: View {
    private let service: AuthService
    @StateObject private var viewModel: LoginViewModel
    @Environment(\.dismiss) var dismiss
    var emailDebouncer = Debouncer(delay: 0.7)
    var passwordDebouncer = Debouncer(delay: 0.7)
    var loginRateDebouncer = Debouncer(delay: 10.0)
    var maxLoginAttempts = 6
    var reAuthDelete: Bool?
    init(service: AuthService, reAuthDelete: Bool? = false) {
        self.service = service
        self._viewModel = StateObject(wrappedValue: LoginViewModel(service: service))
        self.reAuthDelete = reAuthDelete
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                // logo image
                Text("Foodi")
                
                //MARK: Enter Email
                VStack {
                    TextField("Enter your email", text: $viewModel.email)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .modifier(StandardTextFieldModifier())
                        .onChange(of: viewModel.email) {
                            emailDebouncer.schedule{
                                viewModel.isValidLoginEmail()
                            }
                        }
                    if let validEmail = viewModel.validLoginEmail, !viewModel.email.isEmpty && !validEmail {
                        Text("Please enter a valid email address")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                    //MARK: Enter Password
                    SecureField("Enter your password", text: $viewModel.password)
                        .modifier(StandardTextFieldModifier())
                        .onChange(of: viewModel.password) {
                            passwordDebouncer.schedule{
                                viewModel.isValidPassword()
                            }
                        }
                    if let validPassword = viewModel.validPassword, !viewModel.password.isEmpty && !validPassword {
                        Text("Password is at least 6 characters")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                //MARK: ForgotPassword
                NavigationLink(destination: ForgotPasswordView(viewModel: viewModel)) {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .padding(.top)
                        .padding(.trailing, 28)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                //MARK: Login Button
                Button {
                    Task {
                        if let reAuthDelete = reAuthDelete {
                            if !reAuthDelete{
                                await viewModel.login()
                            } else if reAuthDelete {
                                await viewModel.reAuthDelete()
                            }
                        }
                    }
                } label: {
                    if let reAuthDelete = reAuthDelete, reAuthDelete == true {
                        Text(viewModel.isAuthenticating ? "" : "Re-authenticate and Delete")
                            .foregroundColor(.white)
                            .modifier(StandardButtonModifier())
                            .overlay {
                                if viewModel.isAuthenticating {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                    } else {
                        Text(viewModel.isAuthenticating ? "" : "Login")
                            .foregroundColor(.white)
                            .modifier(StandardButtonModifier())
                            .overlay {
                                if viewModel.isAuthenticating {
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                    }
                }
                .disabled(viewModel.isAuthenticating || !formIsValid || viewModel.loginAttempts >= maxLoginAttempts )
                .opacity(formIsValid && viewModel.loginAttempts < maxLoginAttempts ? 1 : 0.3)
                .padding(.vertical)
                //MARK: Error Messages
                if viewModel.loginAttempts >= maxLoginAttempts{
                    Text("Please wait 10 seconds before logging in again")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                if viewModel.showAlert {
                    Text("Wrong credentials, try again or press forgot password!")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                if viewModel.showReAuthAlert {
                    Text("Different credentials than the current account, please try again!")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                Divider()
                Text("or")
                    .font(.caption)
                //MARK: Google Sign In
                Button{
                    Task{
                        if let reAuthDelete = reAuthDelete {
                            if !reAuthDelete{
                                try await service.signInWithGoogle()
                            } else if reAuthDelete{
                                try await viewModel.reAuthDeleteWithGoogle()
                            }
                        }
                    }
                } label: {
                    Image("Google-SignIn")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 50, alignment: .center)
                }
                Spacer()
                if let reAuthDelete = reAuthDelete, !reAuthDelete {
                    Divider()
                    //MARK: RegistrationView
                    NavigationLink {
                        RegistrationView(service: service)
                            .navigationBarBackButtonHidden()
                    } label: {
                        HStack(spacing: 3) {
                            Text("Don't have an account?")
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                        .font(.footnote)
                    }
                    .padding(.vertical, 16)
                }
            }
            /// Keeps the UI Timer running on the forgot password
            .onReceive(viewModel.timer){time in
                if !viewModel.canResetEmail {
                    if viewModel.timeRemaining > 0 {
                        viewModel.timeRemaining -= 1
                    }
                }
            }
            .onChange(of: viewModel.loginAttempts){
                if viewModel.loginAttempts >= maxLoginAttempts{
                    loginRateDebouncer.schedule{
                        viewModel.loginAttempts = 0
                    }
                }
            }
        }
    }
}

extension LoginView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        if let validPassword = viewModel.validPassword, let validEmail = viewModel.validLoginEmail {
            return !viewModel.email.isEmpty
            && validEmail
            && !viewModel.password.isEmpty
            && validPassword
        }
        return false
    }
}
#Preview {
    LoginView(service: AuthService())
}
