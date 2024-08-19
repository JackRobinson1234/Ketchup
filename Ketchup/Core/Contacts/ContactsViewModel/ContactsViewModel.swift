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
    @Published var contacts: [Contact] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var hasMoreContacts = true
    
    private let userService = UserService.shared
    private let pageSize = 20
    private var lastDocument: DocumentSnapshot?
    private let phoneNumberKit = PhoneNumberKit()
    private let contactStore = CNContactStore()
    private var deviceContacts: [String: String] = [:] // [PhoneNumber: Name]
    
    private var existingAccountContactsFetched = false

    func fetchContacts() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                if deviceContacts.isEmpty {
                    try await loadDeviceContacts()
                }
                
                if !existingAccountContactsFetched {
                    let existingContacts = try await fetchExistingAccountContacts()
                    let updatedExistingContacts = try await fetchUserDetailsForContacts(existingContacts)
                    let matchedExistingContacts = matchWithDeviceContacts(updatedExistingContacts)
                    
                    DispatchQueue.main.async {
                        self.contacts = matchedExistingContacts
                        self.existingAccountContactsFetched = true
                        self.isLoading = false
                    }
                } else if hasMoreContacts {
                    let (newContacts, lastDoc) = try await fetchContactsToInvite()
                    let matchedNewContacts = matchWithDeviceContacts(newContacts)
                    
                    DispatchQueue.main.async {
                        self.contacts.append(contentsOf: matchedNewContacts)
                        self.lastDocument = lastDoc
                        self.hasMoreContacts = newContacts.count == self.pageSize
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchExistingAccountContacts() async throws -> [Contact] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ContactsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let db = Firestore.firestore()
        let query = db.collection("users").document(userId).collection("contacts")
            .whereField("hasExistingAccount", isEqualTo: true)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document -> Contact? in
            try? document.data(as: Contact.self)
        }
    }
    
    private func fetchContactsToInvite() async throws -> ([Contact], DocumentSnapshot?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ContactsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let db = Firestore.firestore()
        var query = db.collection("users").document(userId).collection("contacts")
            //.whereField("hasExistingAccount", isEqualTo: false)
            .order(by: "userCount", descending: true)
            .limit(to: pageSize)
        
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        let snapshot = try await query.getDocuments()
        
        let contacts = snapshot.documents.compactMap { document -> Contact? in
            try? document.data(as: Contact.self)
        }
        
        return (contacts, snapshot.documents.last)
    }
    
    private func loadDeviceContacts() async throws {
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
        try await contactStore.enumerateContacts(with: request) { contact, _ in
            for phoneNumber in contact.phoneNumbers {
                if let formattedNumber = formatPhoneNumber(phoneNumber.value.stringValue) {
                    let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
                    self.deviceContacts[formattedNumber] = name
                }
            }
        }
    }
    
    private func formatPhoneNumber(_ phoneNumber: String) -> String? {
        do {
            let parsedNumber = try phoneNumberKit.parse(phoneNumber)
            let number = phoneNumberKit.format(parsedNumber, toType: .international)
            return number
        } catch {
            print("Error parsing phone number: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func fetchUserDetailsForContacts(_ contacts: [Contact]) async throws -> [Contact] {
        var updatedContacts = contacts
        
        for i in 0..<updatedContacts.count {
            if let user = try await userService.fetchUser(withPhoneNumber: updatedContacts[i].phoneNumber) {
                updatedContacts[i].user = user
            }
        }
        
        return updatedContacts
    }
    
    private func matchWithDeviceContacts(_ contacts: [Contact]) -> [Contact] {
        return contacts.map { contact in
            var updatedContact = contact
            if let name = deviceContacts[contact.phoneNumber] {
                updatedContact.deviceContactName = name
            }
            return updatedContact
        }
    }
    func syncDeviceContacts() {
           Task {
               do {
                   let contacts = try await loadAllDeviceContacts()
                   await MainActor.run {
                       self.syncContacts(contacts)
                   }
               } catch {
                   await MainActor.run {
                       self.error = error
                       print("Failed to load device contacts: \(error.localizedDescription)")
                   }
               }
           }
       }

       private func loadAllDeviceContacts() async throws -> [CNContact] {
           let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
           let request = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
           var allContacts: [CNContact] = []
           try contactStore.enumerateContacts(with: request) { contact, _ in
               allContacts.append(contact)
           }
           return allContacts
       }
    func syncContacts(_ contacts: [CNContact]) {
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
           ContactService.shared.syncUserContacts(userId: userId, contacts: contactsToSync) { result in
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
    func follow(userId: String) async throws {
        try await userService.follow(uid: userId)
    }
    
    func unfollow(userId: String) async throws {
        try await userService.unfollow(uid: userId)
    }
    
    func checkIfUserIsFollowed(userId: String) async throws -> Bool {
        return try await userService.checkIfUserIsFollowed(uid: userId)
    }
    
    func inviteContact(_ contact: Contact) {
        let message = "Hey! Join me on our app. It's great!"
        let sms = "sms:\(contact.phoneNumber)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: sms) {
            UIApplication.shared.open(url)
        }
    }
}
//    private func syncContacts(_ contacts: [CNContact]) {
//            guard let userId = Auth.auth().currentUser?.uid else { return }
//            
//            let contactsToSync: [Contact] = contacts.compactMap { contact in
//                guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue,
//                      let formattedPhoneNumber = formatPhoneNumber(phoneNumber) else {
//                    return nil
//                }
//                
//                // Use the phoneNumber as the id to ensure uniqueness
//                return Contact(id: formattedPhoneNumber, phoneNumber: formattedPhoneNumber)
//            }
//            
//            let db = Firestore.firestore()
//            let batch = db.batch()
//            let userContactsRef = db.collection("users").document(userId).collection("contacts")
//            
//            for contact in contactsToSync {
//                let contactRef = userContactsRef.document(contact.id)
//                batch.setData([
//                    "id": contact.id,
//                    "phoneNumber": contact.phoneNumber,
//                    "userCount": contact.userCount,
//                    "hasExistingAccount": contact.hasExistingAccount ?? false,
//                    "isFollowed": contact.isFollowed ?? false
//                ], forDocument: contactRef, merge: true)
//            }
//            
//            batch.commit { error in
//                if let error = error {
//                    print("Failed to sync contacts: \(error.localizedDescription)")
//                } else {
//                    print("Contacts synced successfully.")
//                }
//            }
//        }

    
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
