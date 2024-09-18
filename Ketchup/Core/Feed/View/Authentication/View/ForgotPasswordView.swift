//
//  ForgotPasswordView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/24/24.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LoginViewModel
    var debouncer = Debouncer(delay: 1.0)
    var body: some View {
        VStack{
            Text("Foodi")
            Text("Reset your Password")
                .font(.custom("MuseoSansRounded-300", size: 20))
                .fontWeight(.semibold)
            //MARK: Enter Email
            TextField("Enter your email", text: $viewModel.resetEmailText)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .modifier(StandardTextFieldModifier())
                .onChange(of: viewModel.resetEmailText) {newValue in
                    debouncer.schedule{
                        viewModel.isValidResetEmail()
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
            //MARK: Email format warning
            if let validEmail = viewModel.validResetEmail, !viewModel.resetEmailText.isEmpty && !validEmail {
                Text("Please Enter a Valid Email Address")
                    .foregroundStyle(Color("Colors/AccentColor"))
                    .font(.custom("MuseoSansRounded-300", size: 10))
            }
            //MARK: Reset Button
            Button {
                Task {
                    try await viewModel.SendResetEmail()
                }
            } label: {
                Text(viewModel.isAuthenticating ? "" : "Send Reset Email")
                    .foregroundColor(.white)
                    .modifier(StandardButtonModifier())
                    .overlay {
                        if viewModel.isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        }
                    }
            }
            .disabled(!viewModel.canResetEmail || !(viewModel.validResetEmail ?? false))
            .opacity(viewModel.canResetEmail && (viewModel.validResetEmail ?? false) ? 1 : 0.3)
            .padding(.vertical)
            //MARK: Confirmation/ Time Remaining
            if !viewModel.canResetEmail {
                Text("Reset Password email Sent! Please wait \(viewModel.timeRemaining) seconds to try again")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                Button {
                    dismiss()
                } label: {
                    Text("Back to Sign in")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                }
                .padding(.vertical, 16)
            }
        }
        .navigationBarBackButtonHidden()
        .modifier(BackButtonModifier())
    }
}

#Preview {
    ForgotPasswordView(viewModel: LoginViewModel())
}
