//
//  PhoneAuthView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/12/24.
//

import Foundation
import SwiftUI
import PhoneNumberKit
import Combine
import FirebaseAuth
struct PhoneAuthView: View {
    @StateObject private var viewModel: PhoneAuthViewModel
    @Environment(\.dismiss) var dismiss
    var isDelete: Bool = false
    init(isDelete: Bool = false) {
            _viewModel = StateObject(wrappedValue: PhoneAuthViewModel(isDelete: isDelete))
        }
    //@StateObject var registrationViewModel = UserRegistrationViewModel()
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Image("KetchupTextRed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                if isDelete {
                    deleteAccountMessage
                } else if let userSession = AuthService.shared.userSession {
                    Text("Hey @\(userSession.username), we're updating our sign in flow! Don't worry- this will be linked to your existing account")
                        .font(.custom("MuseoSansRounded-500", size: 20))
                }
                    
                
                Text("First, What's your phone number?")
                    .font(.custom("MuseoSansRounded-700", size: 26))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
                   

                
                HStack {
                    TextField("Phone number", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .onChange(of: viewModel.phoneNumber) { newValue in
                            viewModel.phoneNumberChanged(newValue)
                        }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                if viewModel.showInvalidPhoneNumberError {
                    Text("Please enter a valid phone number")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Text("By submitting your phone number, you consent to receive informational messages at that number from Ketchup. Message and data rates may apply. See our Privacy Policy and Terms of Service for more information.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    if viewModel.isPhoneNumberValid {
                        viewModel.startPhoneVerification()
                    } else {
                        viewModel.showInvalidPhoneNumberAlert()
                    }
                }) {
                    HStack {
                        Text(viewModel.isAuthenticating ? "Sending..." : "Submit")
                            .font(.custom("MuseoSansRounded-500", size: 20))
                            .foregroundStyle(viewModel.isPhoneNumberValid ? .white : .black)

                        if viewModel.isAuthenticating {
                           ProgressView()
                                
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isPhoneNumberValid ? Color("Colors/AccentColor") : Color.gray.opacity(0.5))
                    .foregroundColor(.black)
                    .cornerRadius(25)
                }
                .disabled(viewModel.isAuthenticating)
            }
            .padding()
            .navigationBarItems(leading: Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
            })
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $viewModel.isShowingVerificationView) {
                PhoneVerificationView(viewModel: viewModel)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    private var deleteAccountMessage: some View {
           VStack(alignment: .leading, spacing: 10) {
               Text("Account Deletion Confirmation")
                   .font(.custom("MuseoSansRounded-700", size: 22))
                   .foregroundColor(.red)
               
               Text("For your security, we need to re-authenticate your account before proceeding with deletion. Please enter your phone number to receive a verification code.")
                   .font(.custom("MuseoSansRounded-500", size: 16))
                   .foregroundColor(.gray)
           }
           .padding()
           .background(Color.red.opacity(0.1))
           .cornerRadius(10)
       }
}
