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
    
    init(service: AuthService) {
        self.service = service
        self._viewModel = StateObject(wrappedValue: LoginViewModel(service: service))
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
                        .modifier(StandardTextFieldModifier())
                        .onChange(of: viewModel.email) {
                            viewModel.isValidLoginEmail()
                        }
                    if !viewModel.email.isEmpty && !viewModel.validLoginEmail {
                        Text("Please Enter a Valid Email Address")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                    //MARK: Enter Password
                    SecureField("Enter your password", text: $viewModel.password)
                        .modifier(StandardTextFieldModifier())
                        .onChange(of: viewModel.password) {
                            viewModel.isValidPassword()
                        }
                    if !viewModel.password.isEmpty && !viewModel.validPassword {
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
                
                Button {
                    Task {
                        await viewModel.login()
                    }
                } label: {
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
                .disabled(viewModel.isAuthenticating || !formIsValid)
                .opacity(formIsValid ? 1 : 0.7)
                .padding(.vertical)
                

                Button{
                    Task{
                        try await service.signInWithGoogle()
                    }
                } label: {
                    Image("Google-SignIn")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 50, alignment: .center)
                }
                Spacer()
                
                Divider()
                
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
            /// Keeps the UI Timer running on the forgot password
            .onReceive(viewModel.timer){time in
                if !viewModel.canResetEmail {
                    if viewModel.timeRemaining > 0 {
                        viewModel.timeRemaining -= 1
                    }
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Error"),
                      message: Text(viewModel.authError?.description ?? "Please try again.."))
            }
        }
    }
}

extension LoginView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !viewModel.email.isEmpty
        && viewModel.validLoginEmail
        && !viewModel.password.isEmpty
        && viewModel.validPassword
    }
}

#Preview {
    LoginView(service: AuthService())
}
