//
//  PhoneAuthViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/12/24.
//

import SwiftUI
import Combine
import FirebaseAuth
import PhoneNumberKit
class PhoneAuthViewModel: ObservableObject {
    @Published var phoneNumber = ""
    @Published var verificationCode: String = ""
    @Published var verificationID: String?
    @Published var isShowingVerificationView = false
    @Published var isAuthenticating = false
    @Published var isVerified = false
    @Published var isPhoneNumberValid = false
    @Published var showInvalidPhoneNumberError = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showAlert = false
    @Published var shouldNavigateToUsernameSelection = false
    private var cancellables = Set<AnyCancellable>()
    private let phoneNumberKit = PhoneNumberKit()
    private let debounceDuration: TimeInterval = 0.5

    init() {
        setupPhoneNumberValidation()
    }

    private func setupPhoneNumberValidation() {
        $phoneNumber
            .debounce(for: .seconds(debounceDuration), scheduler: RunLoop.main)
            .sink { [weak self] number in
                self?.validatePhoneNumber(number)
            }
            .store(in: &cancellables)
    }

    func phoneNumberChanged(_ newValue: String) {
        phoneNumber = newValue
        showInvalidPhoneNumberError = false
    }

    private func validatePhoneNumber(_ number: String) {
        do {
            let parsedNumber = try phoneNumberKit.parse(number)
            phoneNumber = phoneNumberKit.format(parsedNumber, toType: .international)
            isPhoneNumberValid = true
            showInvalidPhoneNumberError = false
        } catch {
            isPhoneNumberValid = false
            showInvalidPhoneNumberError = !number.isEmpty
        }
    }

    func startPhoneVerification() {
        isAuthenticating = true
        ///DELETE BEFORE PRODUCTION
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            DispatchQueue.main.async {
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                self?.isAuthenticating = false
                if let error = error {
                    self?.handleError(error)
                } else if let verificationID = verificationID {
                    self?.verificationID = verificationID
                    self?.isShowingVerificationView = true
                }
            }
        }
    }

    func verifyCode() {
        if self.verificationID == nil{
            let verificationID = UserDefaults.standard.string(forKey: "authVerificationID")
        }
        guard let verificationID = verificationID else {
            showAlert(title: "Error", message: "Verification ID is missing. Please try again.")
            return
        }

        guard verificationCode.count == 6 else {
            showAlert(title: "Invalid Code", message: "Please enter a 6-digit verification code.")
            return
        }

        isAuthenticating = true
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )

        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
                if let error = error {
                    self?.handleError(error)
                    self?.clearVerificationCode()
                } else {
                    self?.shouldNavigateToUsernameSelection = true
                }
            }
        }
    }
    func clearVerificationCode() {
        verificationCode = ""
    }
    func showInvalidPhoneNumberAlert() {
        showAlert(title: "Invalid Phone Number", message: "Please enter a valid phone number before submitting.")
    }

    private func handleError(_ error: Error) {
        print("Detailed error: \(error)")
        if let errCode = AuthErrorCode(rawValue: error._code) {
            print("Firebase Auth Error Code: \(errCode.rawValue)")
            switch errCode {
            case .invalidVerificationCode:
                showAlert(title: "Invalid Code", message: "The verification code entered is incorrect.")
            case .invalidPhoneNumber:
                showAlert(title: "Invalid Phone Number", message: "The phone number is invalid. Please check and try again.")
            case .tooManyRequests:
                showAlert(title: "Too Many Attempts", message: "Too many unsuccessful attempts. Please try again later.")
            default:
                showAlert(title: "Authentication Error", message: "An error occurred: \(error.localizedDescription)")
            }
        } else {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
