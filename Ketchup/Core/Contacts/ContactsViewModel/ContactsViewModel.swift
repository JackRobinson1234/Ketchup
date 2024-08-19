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
import FirebaseFirestoreInternal

class ContactsViewModel: ObservableObject {
    @Published var contacts: [MergedContact] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var hasMoreContacts = true
    
    private let userService = UserService.shared
    private let contactStore = CNContactStore()
    private let pageSize = 20
    private var lastDocument: DocumentSnapshot?
    private var deviceContacts: [String: CNContact] = [:] // Phone number to CNContact
    
    func fetchContacts() {
        guard !isLoading && hasMoreContacts else { return }
        isLoading = true
        
        Task {
            do {
                if deviceContacts.isEmpty {
                    try await loadDeviceContacts()
                }
                let (newContacts, lastDoc) = try await fetchContactsFromFirebase()
                let mergedContacts = newContacts.map { firebaseContact in
                    MergedContact(
                        firebaseContact: firebaseContact,
                        deviceContact: deviceContacts[firebaseContact.phoneNumber]
                    )
                }
                DispatchQueue.main.async {
                    self.contacts.append(contentsOf: mergedContacts)
                    self.lastDocument = lastDoc
                    self.hasMoreContacts = newContacts.count == self.pageSize
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadDeviceContacts() async throws {
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        try contactStore.enumerateContacts(with: request) { contact, _ in
            for phoneNumber in contact.phoneNumbers {
                if let formattedNumber = formatPhoneNumber(phoneNumber.value.stringValue) {
                    self.deviceContacts[formattedNumber] = contact
                }
            }
        }
    }
    
    private func fetchContactsFromFirebase() async throws -> ([FirebaseContact], DocumentSnapshot?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ContactsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let db = Firestore.firestore()
        var query = db.collection("users").document(userId).collection("contacts")
            .order(by: "userCount", descending: true)
            .limit(to: pageSize)
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        let snapshot = try await query.getDocuments()
        
        let contacts = snapshot.documents.compactMap { document -> FirebaseContact? in
            try? document.data(as: FirebaseContact.self)
        }
        
        return (contacts, snapshot.documents.last)
    }
    
    private func formatPhoneNumber(_ phoneNumber: String) -> String? {
        // Implement phone number formatting logic here
        // This should match the format used in Firebase
        return phoneNumber // Placeholder implementation
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
    
    func inviteContact(_ contact: MergedContact) {
        let message = "Hey! Join me on our app. It's great!"
        let sms = "sms:\(contact.phoneNumber)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: sms) {
            UIApplication.shared.open(url)
        }
    }
}

struct FirebaseContact: Codable, Identifiable {
    let id: String
    let phoneNumber: String
    let userCount: Int
    let hasExistingAccount: Bool
    var user: User?
}

struct MergedContact: Identifiable {
    let id: String
    let phoneNumber: String
    let userCount: Int
    let hasExistingAccount: Bool
    var user: User?
    let deviceContact: CNContact?
    
    init(firebaseContact: FirebaseContact, deviceContact: CNContact?) {
        self.id = firebaseContact.id
        self.phoneNumber = firebaseContact.phoneNumber
        self.userCount = firebaseContact.userCount
        self.hasExistingAccount = firebaseContact.hasExistingAccount
        self.user = firebaseContact.user
        self.deviceContact = deviceContact
    }
    
    var displayName: String {
        if let deviceContact = deviceContact {
            return "\(deviceContact.givenName) \(deviceContact.familyName)".trimmingCharacters(in: .whitespaces)
        } else if let username = user?.username {
            return username
        } else {
            return phoneNumber
        }
    }
}
    
//    private func syncContacts(_ contacts: [CNContact]) {
//        guard let userId = Auth.auth().currentUser?.uid else { return }
//        
//        // Prepare Contact objects to sync
//        let contactsToSync: [Contact] = contacts.compactMap { contact in
//            guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue,
//                  let formattedPhoneNumber = formatPhoneNumber(phoneNumber) else {
//                return nil
//            }
//            
//            return Contact(phoneNumber: formattedPhoneNumber)
//        }
//        
//        // Use ContactService to sync contacts
//        contactService.syncUserContacts(userId: userId, contacts: contactsToSync) { result in
//            switch result {
//            case .success():
//                print("Contacts synced successfully.")
//            case .failure(let error):
//                DispatchQueue.main.async {
//                    self.error = error
//                    print("Failed to sync contacts: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//    
//    func checkFirebaseUsers(for contacts: [CNContact]) {
//        let phoneNumbers = contacts.flatMap { contact in
//            contact.phoneNumbers.compactMap { phoneNumber in
//                formatPhoneNumber(phoneNumber.value.stringValue)
//            }
//        }
//        
//        Task {
//            do {
//                let users = try await userService.fetchUsers(byPhoneNumbers: phoneNumbers)
//                DispatchQueue.main.async {
//                    self.updateFirebaseUsers(users)
//                    self.sortContacts()
//                    self.isLoading = false
//                    self.showEmptyView = self.contacts.isEmpty
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.isLoading = false
//                    self.error = error
//                    print("Failed to fetch Firebase users: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//    
//    private func updateFirebaseUsers(_ users: [User]) {
//        for user in users {
//            if let contact = contacts.first(where: { contact in
//                contact.phoneNumbers.contains { phoneNumber in
//                    formatPhoneNumber(phoneNumber.value.stringValue) == user.phoneNumber
//                }
//            }) {
//                firebaseUsers[contact.identifier] = user
//            }
//        }
//    }
//    
//    private func formatPhoneNumber(_ phoneNumber: String) -> String? {
//        do {
//            let parsedNumber = try phoneNumberKit.parse(phoneNumber)
//            let number = phoneNumberKit.format(parsedNumber, toType: .international)
//            // Format to match Firebase storage format
//            return number
//        } catch {
//            print("Error parsing phone number: \(error.localizedDescription)")
//            return nil
//        }
//    }
//    
//    private func sortContacts() {
//        contacts.sort { contact1, contact2 in
//            let isUser1 = firebaseUsers[contact1.identifier] != nil
//            let isUser2 = firebaseUsers[contact2.identifier] != nil
//            
//            if isUser1 && !isUser2 {
//                return true
//            } else if !isUser1 && isUser2 {
//                return false
//            } else {
//                return contact1.givenName.lowercased() < contact2.givenName.lowercased()
//            }
//        }
//        
//        objectWillChange.send()
//    }
//    
//    func follow(userId: String) async throws {
//        try await userService.follow(uid: userId)
//    }
//    
//    func unfollow(userId: String) async throws {
//        try await userService.unfollow(uid: userId)
//    }
//    
//    func checkIfUserIsFollowed(userId: String) async throws -> Bool {
//        return try await userService.checkIfUserIsFollowed(uid: userId)
//    }
//    
//    func inviteContact(_ contact: CNContact) {
//        if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
//            let message = "Hey! Join me on our app. It's great!"
//            let sms = "sms:\(phoneNumber)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
//            if let url = URL(string: sms) {
//                UIApplication.shared.open(url)
//            }
//        }
//    }
//}
