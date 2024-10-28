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
import CryptoKit

class ContactsViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var hasMoreContacts = true
    @Published var isShowingMessageComposer = false
    @Published var isLoadingExistingUsers = false
    @Published var messageRecipient: String?
    
    private let userService = UserService.shared
    private let pageSize = 30
    private var lastDocument: DocumentSnapshot?
    private var lastNewDocument: DocumentSnapshot?
    private var lastExistingDocument: DocumentSnapshot?

    private let phoneNumberKit = PhoneNumberUtility()
    private let contactStore = CNContactStore()
    private var deviceContacts: [String: (name: String, realPhoneNumber: String)] = [:] // [Hashed PhoneNumber: (Name, Real PhoneNumber)]
    private var currentPage = 0
    private var existingAccountContactsFetched = false
    private var shouldFetchExistingUsers: Bool
    private var existingContacts: [Contact] = []
       private var newContacts: [Contact] = []
    private var currentExistingPage = 0
       private var currentNewPage = 0
       private var hasMoreExistingContacts = true
       private var hasMoreNewContacts = true
    init(shouldFetchExistingUsers: Bool = true) {
        self.shouldFetchExistingUsers = shouldFetchExistingUsers
    }
    @MainActor
    var inviteMessage: String {
        let appStoreLink = "https://apps.apple.com/us/app/ketchup/id6503178927"
        if let username = AuthService.shared.userSession?.username {
            return """
            Hey! I'm inviting you to Ketchup — not the condiment, it's a restaurant reviewing app that's basically Instagram + Yelp combined. Check it out on the App Store:

            \(appStoreLink)

            (P.S. Follow me @\(username))
            """
        } else {
            return """
            Hey! I'm inviting you to Ketchup — not the condiment, it's a restaurant reviewing app that's basically Instagram + Yelp combined. Check it out on the App Store:

            \(appStoreLink)
            """
        }
    }

    func fetchContacts() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                if deviceContacts.isEmpty {
                    try await loadDeviceContacts()
                }
                
                let (contacts, lastDoc) = try await fetchAllContacts()
                let updatedContacts = try await fetchUserDetailsForContacts(contacts)
                let matchedContacts = matchWithDeviceContacts(updatedContacts)
                
                await MainActor.run {
                    self.contacts.append(contentsOf: matchedContacts)
                    self.lastDocument = lastDoc
                    self.hasMoreContacts = contacts.count == self.pageSize
                    self.currentPage += 1
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
        
        private func fetchExistingUsers() async {
            await MainActor.run { self.isLoadingExistingUsers = true }
            
            do {
                let (existingContacts, lastDoc) = try await fetchExistingAccountContacts()
                let updatedExistingContacts = try await fetchUserDetailsForContacts(existingContacts)
                let matchedExistingContacts = matchWithDeviceContacts(updatedExistingContacts)
                
                await MainActor.run {
                    self.contacts.append(contentsOf: matchedExistingContacts)
                    self.lastExistingDocument = lastDoc
                    self.hasMoreContacts = existingContacts.count == self.pageSize
                    self.currentExistingPage += 1
                    self.isLoadingExistingUsers = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoadingExistingUsers = false
                }
            }
        }
        
        private func fetchInviteList() async {
            do {
                let (newContacts, lastDoc) = try await fetchContactsToInvite()
                let matchedNewContacts = matchWithDeviceContacts(newContacts)
                
                await MainActor.run {
                    self.contacts.append(contentsOf: matchedNewContacts)
                    self.lastNewDocument = lastDoc
                    self.hasMoreContacts = newContacts.count == self.pageSize
                    self.currentNewPage += 1
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
       
       private func fetchExistingAccountContacts() async throws -> ([Contact], DocumentSnapshot?) {
           guard let userId = Auth.auth().currentUser?.uid else {
               throw NSError(domain: "ContactsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
           }
           
           let db = Firestore.firestore()
           var query = db.collection("users").document(userId).collection("contacts")
               .whereField("hasExistingAccount", isEqualTo: true)
               .limit(to: pageSize)
           
           if let lastExistingDocument = lastExistingDocument {
               query = query.start(afterDocument: lastExistingDocument)
           }
           
           let snapshot = try await query.getDocuments()
           
           let contacts = snapshot.documents.compactMap { document -> Contact? in
               try? document.data(as: Contact.self)
           }
           
           return (contacts, snapshot.documents.last)
       }
    private func fetchAllContacts() async throws -> ([Contact], DocumentSnapshot?) {
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
        
        let contacts = snapshot.documents.compactMap { document -> Contact? in
            try? document.data(as: Contact.self)
        }
        
        return (contacts, snapshot.documents.last)
    }
       private func fetchContactsToInvite() async throws -> ([Contact], DocumentSnapshot?) {
           guard let userId = Auth.auth().currentUser?.uid else {
               throw NSError(domain: "ContactsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
           }
           
           let db = Firestore.firestore()
           var query = db.collection("users").document(userId).collection("contacts")
               .whereField("hasExistingAccount", isEqualTo: false)
               .order(by: "userCount", descending: true)
               .limit(to: pageSize)
           
           if let lastNewDocument = lastNewDocument {
               query = query.start(afterDocument: lastNewDocument)
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
                    let hashedNumber = hashPhoneNumber(formattedNumber) // Hash the formatted number
                    let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
                    self.deviceContacts[hashedNumber] = (name: name, realPhoneNumber: formattedNumber) // Store the real number with the hash
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
            ////print("Error parsing phone number: \(error.localizedDescription)")
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
            if let deviceContactInfo = deviceContacts[contact.phoneNumber] {
                updatedContact.deviceContactName = deviceContactInfo.name
                updatedContact.deviceContactNumber = deviceContactInfo.realPhoneNumber // Store the real phone number
            }
            return updatedContact
        }
    }

    private func getRealPhoneNumber(for hashedPhoneNumber: String) -> String? {
        for (realPhoneNumber, hashedNumber) in deviceContacts {
            if hashPhoneNumber(realPhoneNumber) == hashedPhoneNumber {
                return realPhoneNumber
            }
        }
        return nil
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
    private func hashPhoneNumber(_ phoneNumber: String) -> String {
           let inputData = Data(phoneNumber.utf8)
           let hashed = SHA256.hash(data: inputData)
           return hashed.compactMap { String(format: "%02x", $0) }.joined()
       }
}


struct ContactMessageComposeView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    var recipient: String
    var body: String
    
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
