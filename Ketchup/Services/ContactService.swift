//
//  ContactService.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/18/24.
//

import FirebaseFirestore
import FirebaseAuth
import Contacts
import PhoneNumberKit
import SwiftUI
class ContactService {
    static let shared = ContactService()
    private let db = Firestore.firestore()
    private let contactStore = CNContactStore()
    private let phoneNumberKit = PhoneNumberKit()
    private let batchSize = 50
    
    @Published var error: Error?
    @Published var isSyncing: Bool = false
    @Published var syncProgress: Float = 0.0
    @Published var hasSynced: Bool = false

    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private init() {
        checkSyncStatus()
    }
    
    private func checkSyncStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                self?.hasSynced = document.data()?["hasContactsSynced"] as? Bool ?? false
            }
        }
    }
    
    func syncDeviceContacts() {
        guard !isSyncing && !hasSynced else {
            print("Sync is not needed or is already in progress.")
            return
        }
        
        isSyncing = true
        syncProgress = 0.0
        
        startBackgroundTask()
        
        Task {
            do {
                let contacts = try await loadDeviceContacts()
                await syncContactsBatched(contacts)
                
                await MainActor.run {
                    self.isSyncing = false
                    self.syncProgress = 1.0
                    self.hasSynced = true
                    print("Contact sync completed")
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isSyncing = false
                    print("Failed to sync contacts: \(error.localizedDescription)")
                }
            }
            
            endBackgroundTask()
        }
    }
    
    private func loadDeviceContacts() async throws -> [CNContact] {
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
        var allContacts: [CNContact] = []
        try contactStore.enumerateContacts(with: request) { contact, _ in
            allContacts.append(contact)
        }
        return allContacts
    }
    
    private func syncContactsBatched(_ contacts: [CNContact]) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let totalBatches = Int(ceil(Double(contacts.count) / Double(batchSize)))
        
        for batchIndex in 0..<totalBatches {
            let start = batchIndex * batchSize
            let end = min(start + batchSize, contacts.count)
            let contactsBatch = Array(contacts[start..<end])
            
            let contactsToSync: [Contact] = contactsBatch.compactMap { contact in
                guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue,
                      let formattedPhoneNumber = formatPhoneNumber(phoneNumber) else {
                    return nil
                }
                return Contact(phoneNumber: formattedPhoneNumber)
            }
            
            do {
                try await syncUserContacts(userId: userId, contacts: contactsToSync)
                await MainActor.run {
                    self.syncProgress = Float(batchIndex + 1) / Float(totalBatches)
                }
            } catch {
                print("Error syncing batch \(batchIndex + 1): \(error.localizedDescription)")
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds delay between batches
        }
    }
    
    private func syncUserContacts(userId: String, contacts: [Contact]) async throws {
        let userContactsRef = db.collection("users").document(userId).collection("contacts")
        let batch = db.batch()
        
        for contact in contacts {
            let userContactRef = userContactsRef.document(contact.phoneNumber)
            batch.setData([
                "phoneNumber": contact.phoneNumber,
                "userCount": contact.userCount
            ], forDocument: userContactRef)
        }
        
        try await batch.commit()
        
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "hasExistingAccount": false,
            "hasContactsSynced": true,
            "contactsSyncedOn": Timestamp(date: Date())
        ])
    }
    
    private func formatPhoneNumber(_ phoneNumber: String) -> String? {
        do { 
            let parsedNumber = try phoneNumberKit.parse(phoneNumber)
            return phoneNumberKit.format(parsedNumber, toType: .international)
        } catch {
            print("Error parsing phone number: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
