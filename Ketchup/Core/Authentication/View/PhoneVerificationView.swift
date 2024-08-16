//
//  PhoneVerificationView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/13/24.
//

import SwiftUI

struct PhoneVerificationView: View {
    @ObservedObject var viewModel: PhoneAuthViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var isInputFocused: Bool
    //@ObservedObject var registrationViewModel: UserRegistrationViewModel
    
    @State private var timeRemaining = 60
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image("KetchupTextRed")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
            
            Text("Enter the verification code")
                .font(.custom("MuseoSansRounded-700", size: 26))
                .foregroundStyle(.black)
            
            ZStack(alignment: .leading) {
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 40, height: 50)
                            
                            if index < viewModel.verificationCode.count {
                                Text(String(viewModel.verificationCode[viewModel.verificationCode.index(viewModel.verificationCode.startIndex, offsetBy: index)]))
                                    .font(.title2)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                
                TextField("", text: $viewModel.verificationCode)
                    .keyboardType(.numberPad)
                    .foregroundColor(.clear)
                    .accentColor(.clear)
                    .focused($isInputFocused)
                    .onChange(of: viewModel.verificationCode) { newValue in
                        if newValue.count > 6 {
                            viewModel.verificationCode = String(newValue.prefix(6))
                        }
                        if newValue.count == 6 {
                            isInputFocused = false  // Dismiss keyboard
                            viewModel.verifyCode()
                        }
                    }
            }
            .frame(height: 50)
            
            Text("We've sent a 6-digit verification code to \(viewModel.phoneNumber)")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Text("Resend code in \(timeRemaining)s")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    if timeRemaining == 0 {
                        resendCode()
                    }
                }) {
                    Text("Resend")
                        .foregroundColor(timeRemaining == 0 ? .blue : .gray)
                }
                .disabled(timeRemaining > 0)
            }
            
            Spacer()
        }
        .padding()
        .navigationBarItems(leading: Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
        })
       
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            isInputFocused = true
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resendCode() {
        viewModel.startPhoneVerification()
        timeRemaining = 60
        startTimer()
    }
}
