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
import MessageUI

class ContactsViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var hasMoreContacts = true
    @Published var isShowingMessageComposer = false
    @Published var messageRecipient: String?
    
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
  

  
    func checkIfUserIsFollowed(contact: Contact) async throws -> Bool {
           guard let userId = contact.user?.id else { return false }
           
           // If we've already checked the follow status, return the stored value
           if let isFollowed = contact.isFollowed {
               return isFollowed
           }
           
           // If we haven't checked yet, fetch the status from the server
           let isFollowed = try await userService.checkIfUserIsFollowed(uid: userId)
           
           // Update the contact in the contacts array
           if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
               DispatchQueue.main.async {
                   self.contacts[index].isFollowed = isFollowed
               }
           }
           
           return isFollowed
       }

       func updateContactFollowStatus(contact: Contact, isFollowed: Bool) {
           if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
               DispatchQueue.main.async {
                   self.contacts[index].isFollowed = isFollowed
               }
           }
       }

       func follow(userId: String) async throws {
           try await userService.follow(uid: userId)
           updateFollowStatus(for: userId, isFollowed: true)
       }
       
       func unfollow(userId: String) async throws {
           try await userService.unfollow(uid: userId)
           updateFollowStatus(for: userId, isFollowed: false)
       }
       
       private func updateFollowStatus(for userId: String, isFollowed: Bool) {
           if let index = contacts.firstIndex(where: { $0.user?.id == userId }) {
               DispatchQueue.main.async {
                   self.contacts[index].isFollowed = isFollowed
               }
           }
       }
    func inviteContact(_ contact: Contact) {
            self.messageRecipient = contact.phoneNumber
            self.isShowingMessageComposer = true
        }
}
struct ContactMessageComposeView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    let recipient: String
    let body: String
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = [recipient]
        controller.body = body
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: ContactMessageComposeView
        
        init(_ parent: ContactMessageComposeView) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.isShowing = false
        }
    }
}
