//
//  UserRegistrtationViewModel.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/14/24.
//

import Foundation
import Firebase
import FirebaseFirestore
class UserRegistrationViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var username: String = ""
    @Published var birthday: Date?
    @Published var location: Location?
    @Published var fullname: String = ""
    func updateLocation(_ location: Location?) {
            self.location = location
        }
        
    func createUser() async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "UserRegistration", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        
        let userData: [String: Any] = [
            "phoneNumber": phoneNumber,
            "username": username,
            "birthday": birthday ?? Date(),
            "location": [
                "city": location?.city ?? "",
                "state": location?.state ?? "",
                "geoPoint": location?.geoPoint ?? GeoPoint(latitude: 0, longitude: 0)
            ]
        ]
        
        try await FirestoreConstants.UserCollection.document(userID).setData(userData)
    }
}
