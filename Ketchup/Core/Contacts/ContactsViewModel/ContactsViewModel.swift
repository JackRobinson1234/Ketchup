//
//  ContactsViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/17/24.
//

import SwiftUI
import Contacts
import ContactsUI
import PhoneNumberKit
import FirebaseAuth

class ContactsViewModel: ObservableObject {
    @Published var contacts: [CNContact] = []
    @Published var firebaseUsers: [String: User] = [:]
    @Published var isLoading = false
    @Published var showEmptyView = false
    @Published var error: Error?
    
    private let userService = UserService.shared
    private let contactStore = CNContactStore()
    private let phoneNumberKit = PhoneNumberKit()
    private let contactService = ContactService()  // Add ContactService
    
    func fetchContacts() {
        guard !isLoading else { return }
        isLoading = true
        
        contactStore.requestAccess(for: .contacts) { [weak self] granted, error in
            guard let self = self else { return }
            if granted {
                self.loadContacts()
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showEmptyView = true
                    self.error = error ?? NSError(domain: "ContactsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Permission denied to access contacts."])
                }
            }
        }
    }
    
    private func loadContacts() {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault
        do {
            var allContacts: [CNContact] = []
            try contactStore.enumerateContacts(with: request) { contact, _ in
                allContacts.append(contact)
            }
            self.contacts = allContacts
            self.syncContacts(allContacts)  // Sync contacts after loading
            //self.checkFirebaseUsers(for: allContacts)
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = error
                print("Failed to fetch contacts: \(error.localizedDescription)")
            }
        }
    }
    
    private func syncContacts(_ contacts: [CNContact]) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Prepare Contact objects to sync
        let contactsToSync: [Contact] = contacts.compactMap { contact in
            guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue,
                  let formattedPhoneNumber = formatPhoneNumber(phoneNumber) else {
                return nil
            }
            
            return Contact(phoneNumber: formattedPhoneNumber)
        }
        
        // Use ContactService to sync contacts
        contactService.syncUserContacts(userId: userId, contacts: contactsToSync) { result in
            switch result {
            case .success():
                print("Contacts synced successfully.")
            case .failure(let error):
                DispatchQueue.main.async {
                    self.error = error
                    print("Failed to sync contacts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func checkFirebaseUsers(for contacts: [CNContact]) {
        let phoneNumbers = contacts.flatMap { contact in
            contact.phoneNumbers.compactMap { phoneNumber in
                formatPhoneNumber(phoneNumber.value.stringValue)
            }
        }
        
        Task {
            do {
                let users = try await userService.fetchUsers(byPhoneNumbers: phoneNumbers)
                DispatchQueue.main.async {
                    self.updateFirebaseUsers(users)
                    self.sortContacts()
                    self.isLoading = false
                    self.showEmptyView = self.contacts.isEmpty
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = error
                    print("Failed to fetch Firebase users: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateFirebaseUsers(_ users: [User]) {
        for user in users {
            if let contact = contacts.first(where: { contact in
                contact.phoneNumbers.contains { phoneNumber in
                    formatPhoneNumber(phoneNumber.value.stringValue) == user.phoneNumber
                }
            }) {
                firebaseUsers[contact.identifier] = user
            }
        }
    }
    
    private func formatPhoneNumber(_ phoneNumber: String) -> String? {
        do {
            let parsedNumber = try phoneNumberKit.parse(phoneNumber)
            let number = phoneNumberKit.format(parsedNumber, toType: .international)
            // Format to match Firebase storage format
            return number
        } catch {
            print("Error parsing phone number: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func sortContacts() {
        contacts.sort { contact1, contact2 in
            let isUser1 = firebaseUsers[contact1.identifier] != nil
            let isUser2 = firebaseUsers[contact2.identifier] != nil
            
            if isUser1 && !isUser2 {
                return true
            } else if !isUser1 && isUser2 {
                return false
            } else {
                return contact1.givenName.lowercased() < contact2.givenName.lowercased()
            }
        }
        
        objectWillChange.send()
    }
    
    func follow(userId: String) async throws {
        try await userService.follow(uid: userId)
    }
    
    func unfollow(userId: String) async throws {
        try await userService.unfollow(uid: userId)
    }
    
    func checkIfUserIsFollowed(userId: String) async throws -> Bool {
        return try await userService.checkIfUserIsFollowed(uid: userId)
    }
    
    func inviteContact(_ contact: CNContact) {
        if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
            let message = "Hey! Join me on our app. It's great!"
            let sms = "sms:\(phoneNumber)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            if let url = URL(string: sms) {
                UIApplication.shared.open(url)
            }
        }
    }
}
