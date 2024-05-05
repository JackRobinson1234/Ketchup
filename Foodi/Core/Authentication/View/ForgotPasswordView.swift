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
                .font(.title)
                .fontWeight(.semibold)
            //MARK: Enter Email
            TextField("Enter your email", text: $viewModel.resetEmailText)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .modifier(StandardTextFieldModifier())
                .onChange(of: viewModel.resetEmailText) {
                    debouncer.schedule{
                        viewModel.isValidResetEmail()
                    }
                }
            //MARK: Email format warning
            if let validEmail = viewModel.validResetEmail, !viewModel.resetEmailText.isEmpty && !validEmail {
                Text("Please Enter a Valid Email Address")
                    .foregroundStyle(.red)
                    .font(.caption)
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
                    .font(.caption)
                Button {
                    dismiss()
                } label: {
                    Text("Back to Sign in")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                        .font(.footnote)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationBarBackButtonHidden()
        .modifier(BackButtonModifier())
    }
}

#Preview {
    ForgotPasswordView(viewModel: LoginViewModel(service: AuthService()))
}
