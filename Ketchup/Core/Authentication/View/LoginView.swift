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
    @StateObject private var viewModel: LoginViewModel = LoginViewModel()
    @Environment(\.dismiss) var dismiss
    var emailDebouncer = Debouncer(delay: 0.7)
    var passwordDebouncer = Debouncer(delay: 0.7)
    var loginRateDebouncer = Debouncer(delay: 10.0)
    var maxLoginAttempts = 6
    var reAuthDelete: Bool?
    init(reAuthDelete: Bool? = false) {
        self.reAuthDelete = reAuthDelete
    }
    var body: some View {
      
            VStack {
                Spacer()
                // logo image
                if let reAuthDelete, reAuthDelete{
                    Text("Please log in again to confirm account deletion")
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .font(.custom("MuseoSansRounded-300", size: 30))
                } else {
                    Image("Skip")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                    Image("KetchupTextRed")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                    
                }
                    
                //MARK: Enter Email
                VStack {
                    TextField("Enter your email", text: $viewModel.email)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .modifier(StandardTextFieldModifier())
                        .onChange(of: viewModel.email) {newValue in
                            emailDebouncer.schedule{
                                viewModel.isValidLoginEmail()
                            }
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    dismissKeyboard()
                                }
                            }
                        }
                    if let validEmail = viewModel.validLoginEmail, !viewModel.email.isEmpty && !validEmail {
                        Text("Please enter a valid email address")
                            .foregroundStyle(Color("Colors/AccentColor"))
                            .font(.custom("MuseoSansRounded-300", size: 10))
                    }
                    //MARK: Enter Password
                    SecureField("Enter your password", text: $viewModel.password)
                        .modifier(StandardTextFieldModifier())
                        .onChange(of: viewModel.password) {newValue in
                            passwordDebouncer.schedule{
                                viewModel.isValidPassword()
                            }
                        }
                    if let validPassword = viewModel.validPassword, !viewModel.password.isEmpty && !validPassword {
                        Text("Password is at least 6 characters")
                            .foregroundStyle(Color("Colors/AccentColor"))
                            .font(.custom("MuseoSansRounded-300", size: 10))
                    }
                }
                //MARK: ForgotPassword
                NavigationLink(destination: ForgotPasswordView(viewModel: viewModel)) {
                    Text("Forgot Password?")
                        .fontWeight(.semibold)
                        .padding(.top)
                        .padding(.trailing, 28)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .font(.custom("MuseoSansRounded-300", size: 10))
                    
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
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .font(.custom("MuseoSansRounded-300", size: 10))
                }
                if viewModel.showAlert {
                    Text("Wrong credentials, try again or press forgot password!")
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .font(.custom("MuseoSansRounded-300", size: 10))
                }
                if viewModel.showReAuthAlert {
                    Text("Different credentials than the current account, please try again!")
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .font(.custom("MuseoSansRounded-300", size: 10))
                }
                Divider()
                Text("or")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                Text("You should be able to log in with phone number.This is only accessible for early users.")
                    .foregroundStyle(Color("Colors/AccentColor"))
                    .font(.custom("MuseoSansRounded-300", size: 10))
                //MARK: Google Sign In
//                Button{
//                    Task{
//                        if let reAuthDelete = reAuthDelete {
//                            if !reAuthDelete{
//                                try await AuthService.shared.signInWithGoogle()
//                            } else if reAuthDelete{
//                                try await viewModel.reAuthDeleteWithGoogle()
//                            }
//                        }
//                    }
//                } label: {
//                    Image("Google-SignIn")
//                        .resizable()
//                            .scaledToFill()
//                            .frame(width: 100, height: 50) 
//                            .scaledToFit()
//                            .frame(width: 200)// Adjust these dimensions as needed
//                            //.clipped()
//                        
//                }
                Spacer()
                if let reAuthDelete = reAuthDelete, !reAuthDelete {
                    Divider()
                    //MARK: RegistrationView
//                    NavigationLink {
//                        RegistrationView()
//                            .navigationBarBackButtonHidden()
//                    } label: {
//                        HStack(spacing: 3) {
//                            Text("Don't have an account?")
//                            Text("Sign Up")
//                                .fontWeight(.semibold)
//                        }
//                        .foregroundStyle(Color("Colors/AccentColor"))
//                        .font(.custom("MuseoSansRounded-300", size: 16))
//                    }
//                    .padding(.vertical, 16)
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
            .onChange(of: viewModel.loginAttempts){newValue in
                if viewModel.loginAttempts >= maxLoginAttempts{
                    loginRateDebouncer.schedule{
                        viewModel.loginAttempts = 0
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
    LoginView()
}
