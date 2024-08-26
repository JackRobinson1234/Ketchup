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
import FirebaseFirestoreInternal
@MainActor
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
    @Published var isDelete: Bool = false
    private var cancellables = Set<AnyCancellable>()
    private let phoneNumberKit = PhoneNumberKit()
    private let debounceDuration: TimeInterval = 0.5
    @Published var deletionSuccessful: Bool = false
    
    init(isDelete: Bool = false) {
        self.isDelete = isDelete
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
        let verificationID = self.verificationID ?? UserDefaults.standard.string(forKey: "authVerificationID")
        
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
        
        if isDelete {
            reauthenticateAndDelete(with: credential)
        } else {
            authenticateOrLinkPhone(with: credential)
        }
    }
    
    private func reauthenticateAndDelete(with credential: AuthCredential) {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "No user is currently signed in.")
            return
        }
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                self?.handleError(error)
            } else {
                self?.deleteAccount()
            }
        }
    }
    
    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        user.delete { [weak self] error in
            if let error = error {
                self?.handleError(error)
            } else {
                DispatchQueue.main.async {
                    self?.deletionSuccessful = true
                    self?.showAlert(title: "Account Deleted", message: "Your account has been successfully deleted.")
                }
            }
        }
        Task{
            try await AuthService.shared.updateUserSession()
        }
    }
    
    private func authenticateOrLinkPhone(with credential: AuthCredential) {
        if let currentUser = Auth.auth().currentUser {
            currentUser.link(with: credential) { [weak self] (authResult, error) in
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                    if let error = error {
                        self?.handleError(error)
                        self?.clearVerificationCode()
                    } else {
                        Task {
                            if let isAccountComplete = try await self?.isAccountComplete() {
                                if !isAccountComplete {
                                    await self?.updateUserWithPhoneNumber()
                                } else {
                                    self?.shouldNavigateToUsernameSelection = true
                                }
                            }
                        }
                    }
                }
            }
        } else {
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                DispatchQueue.main.async {
                    self?.isAuthenticating = false
                    if let error = error {
                        self?.handleError(error)
                        self?.clearVerificationCode()
                    } else {
                        Task {
                            try await AuthService.shared.updateUserSession()
                            if AuthService.shared.userSession == nil {
                                await self?.createBasicUser()
                            } else {
                                if let isAccountComplete = try await self?.isAccountComplete() {
                                    if !isAccountComplete {
                                        await self?.updateUserWithPhoneNumber()
                                    } else {
                                        self?.shouldNavigateToUsernameSelection = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    private func isAccountComplete() async throws -> Bool {
        guard let userID = Auth.auth().currentUser?.uid else { return false }
        let db = Firestore.firestore()
        let userDocument = try await db.collection("users").document(userID).getDocument()
        
        if let hasCompletedSetup = userDocument.data()?["hasCompletedSetup"] as? Bool {
            return hasCompletedSetup
        }
        return false
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
            case .requiresRecentLogin:
                showAlert(title: "Re-authentication Required", message: "Please sign in again to delete your account.")
            default:
                showAlert(title: "Authentication Error", message: "An error occurred: \(error.localizedDescription)")
            }
        } else {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    func clearVerificationCode() {
        verificationCode = ""
    }
    func showInvalidPhoneNumberAlert() {
        showAlert(title: "Invalid Phone Number", message: "Please enter a valid phone number before submitting.")
    }
    
    
    
    private func createBasicUser() async {
        guard let user = Auth.auth().currentUser else { return }
        
        do {
            let randomUsername = try await AuthService.shared.generateRandomUsername(prefix: "user")
            print("PHONE NUMBER 1:", self.phoneNumber)
            let newUser = try await AuthService.shared.createFirestoreUser(
                id: user.uid,
                username: randomUsername,
                fullname: "",
                birthday: Date(),
                phoneNumber: self.phoneNumber,
                privateMode: false
            )
            Task{
                try await AuthService.shared.updateUserSession()
            }
            if let token = UserDefaults.standard.string(forKey: "fcmToken") {
                await updateFCMTokenForUser(userId: user.uid, token: token)
            }
            self.shouldNavigateToUsernameSelection = true
        } catch {
            print("Error creating basic user: \(error.localizedDescription)")
            showAlert(title: "Error", message: "Failed to create user. Please try again.")
        }
    }
    private func updateUserWithPhoneNumber() async {
        do {
            guard let userID = Auth.auth().currentUser?.uid else { return }
            
            // Update the user's phone number in Firestore
            print("PHONE NUMBER 2:", self.phoneNumber)
            try await AuthService.shared.updateFirestoreUser(
                id: userID,
                phoneNumber: self.phoneNumber,
                hasCompletedSetup: false
            )
            
            Task {
                try await AuthService.shared.updateUserSession()
            }
            
            // Navigate to the next step or show a success message
            self.shouldNavigateToUsernameSelection = true
            guard let userId = Auth.auth().currentUser?.uid else { return }
            if let token = UserDefaults.standard.string(forKey: "fcmToken") {
                        await updateFCMTokenForUser(userId: userID, token: token)
                    }
        } catch {
            print("Error updating user with phone number: \(error.localizedDescription)")
            showAlert(title: "Error", message: "Failed to update user. Please try again.")
        }
    }
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    private func updateFCMTokenForUser(userId: String, token: String) async {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let db = Firestore.firestore()
        
        do {
            try await db.collection("users").document(userId).collection("devices").document(deviceId).setData([
                "fcmToken": token,
                "lastUpdated": FieldValue.serverTimestamp()
            ])
            print("Token saved successfully after login")
            UserDefaults.standard.removeObject(forKey: "fcmToken")
        } catch {
            print("Error saving token: \(error)")
        }
    }
}
