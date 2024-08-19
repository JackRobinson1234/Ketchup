//
//  ContactService.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/18/24.
//

import FirebaseFirestore
import FirebaseAuth

class ContactService {
    
    private let db = Firestore.firestore()
    static let shared = ContactService() // Singleton instance
    private init() {}
    /// Syncs the user's contacts with the backend and updates the global contacts list.
    func syncUserContacts(userId: String, contacts: [Contact], completion: @escaping (Result<Void, Error>) -> Void) {
        let userContactsRef = db.collection("users").document(userId).collection("contacts")
        let batch = db.batch()
        
        contacts.forEach { contact in
            // Update or add the contact in the user's contact subcollection
            let userContactRef = userContactsRef.document(contact.phoneNumber)
            batch.setData([
                "phoneNumber": contact.phoneNumber,
                "userCount": contact.userCount
            ], forDocument: userContactRef)
            
           
        }
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Optionally update the `hasContactsSynced` and `contactsSyncedOn` fields in the user's document
                let userRef = self.db.collection("users").document(userId)
                userRef.updateData([
                    "hasContactsSynced": true,
                    "contactsSyncedOn": Timestamp(date: Date())
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    /// Fetches the contacts from the user's subcollection.
    func fetchUserContacts(userId: String, completion: @escaping (Result<[Contact], Error>) -> Void) {
        let userContactsRef = db.collection("users").document(userId).collection("contacts")
        
        userContactsRef.getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                var contacts: [Contact] = []
                snapshot?.documents.forEach { document in
                    if let contact = try? document.data(as: Contact.self) {
                        contacts.append(contact)
                    }
                }
                completion(.success(contacts))
            }
        }
    }
    
    /// Fetches all users who have a specific contact by phone number.
    func fetchUsersForContact(phoneNumber: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let globalContactUserIdsRef = db.collection("globalContacts").document(phoneNumber).collection("userIds")
        
        globalContactUserIdsRef.getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                var userIds: [String] = []
                snapshot?.documents.forEach { document in
                    let userId = document.documentID
                    userIds.append(userId)
                }
                completion(.success(userIds))
            }
        }
    }
}
