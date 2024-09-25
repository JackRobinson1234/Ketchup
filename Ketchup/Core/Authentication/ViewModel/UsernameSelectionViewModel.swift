//
//  UsernameSelectionViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/14/24.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestoreInternal
class UsernameSelectionViewModel: ObservableObject {
    @Published var username = ""
    @Published var fullName = ""
    @Published var isUsernameAvailable: Bool?
    @Published var isChecking = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var shouldDismiss = false
    @Published var isUsernameValid = false
    @Published var isFullNameValid = false
    @Published var showInvalidCharWarning = false
    @Published var showFullNameWarning = false
    @Published var fullNameWarningMessage = ""
    @Published var navigateToBirthdaySelection = false
    @Published var selectedBirthday: Date?
    @Published var selectedLocation: Location?
    @Published var showMaxCharReachedWarning = false
    private var usernameCheckWorkItem: DispatchWorkItem?

    
    var canSave: Bool {
        return isUsernameAvailable == true && !username.isEmpty && isUsernameValid && !isChecking && isFullNameValid
    }
    
    func validateAndCheckUsername(_ newValue: String) {
        // Check for invalid characters
        let invalidChars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._").inverted
        showInvalidCharWarning = newValue.rangeOfCharacter(from: invalidChars) != nil
        
        // Remove any characters that aren't allowed
        var filteredUsername = newValue.filter { char in
            char.isLetter || char.isNumber || char == "." || char == "_"
        }
        filteredUsername = filteredUsername.lowercased()
        
        // Check if max character limit is reached
        showMaxCharReachedWarning = filteredUsername.count >= 25
        
        if filteredUsername.count > 25 {
            filteredUsername = String(filteredUsername.prefix(25))
        }
        
        // Update the username with the filtered value
        if username != filteredUsername {
            username = filteredUsername
        }
        
        // Check if the username is valid
        isUsernameValid = isValidUsername(username)
        
        // If valid and not empty, check availability
        if isUsernameValid && !username.isEmpty {
            checkUsernameAvailability()
        } else {
            isUsernameAvailable = false
        }
    }
    func validateFullName(_ newValue: String) {
            let trimmedName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedName.isEmpty {
                showFullNameWarning = true
                fullNameWarningMessage = "Full name cannot be empty"
                isFullNameValid = false
            }  else if trimmedName.count > 50 {
                showFullNameWarning = true
                fullNameWarningMessage = "Full name cannot exceed 50 characters"
                isFullNameValid = false
            } else {
                showFullNameWarning = false
                fullNameWarningMessage = ""
                isFullNameValid = true
            }
        }
    private func isValidUsername(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9._]{1,30}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    func checkUsernameAvailability() {
        usernameCheckWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isChecking = true
            
            Task {
                do {
                    let query = Firestore.firestore().collection("users").whereField("username", isEqualTo: self.username)
                    let querySnapshot = try await query.getDocuments()
                    
                    DispatchQueue.main.async {
                        self.isChecking = false
                        self.isUsernameAvailable = querySnapshot.documents.isEmpty
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isChecking = false
                        self.isUsernameAvailable = false
                        self.showAlert(title: "Error", message: "Failed to check username availability. Please try again.")
                    }
                }
            }
        }
        
        usernameCheckWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    func saveUsernameAndFullName() {
            guard let currentUser = Auth.auth().currentUser else {
                showAlert(title: "Error", message: "No authenticated user found.")
                return
            }
            
            Task {
                do {
//                    try await Firestore.firestore().collection("users").document(currentUser.uid).setData([
//                        "username": username,
//                        "fullName": fullName
//                    ], merge: true)
                    
                    DispatchQueue.main.async {
                        self.navigateToBirthdaySelection = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Error", message: "Failed to save username and full name. Please try again.")
                    }
                }
            }
        }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
