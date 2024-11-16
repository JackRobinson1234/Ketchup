//
//  AuthService.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import GoogleSignIn
import FirebaseAuth
import GoogleSignInSwift

@MainActor
class AuthService {
    static let shared = AuthService()
    @Published var userSession: User?
    private init() {}
    
    func updateUserSession() async throws {
        guard let authUser = Auth.auth().currentUser?.uid else {
            self.userSession = nil
            return
        }
        do {
            let userDocument = try await FirestoreConstants.UserCollection.document(authUser).getDocument(as: User.self)
            self.userSession = userDocument
        } catch {
            ////print("Error updating user session:", error.localizedDescription)
            self.userSession = nil
            //throw error
            
        }
    }
    
    //MARK: Login
    /// Logins in the user then updates the user session
    /// - Parameters:
    ///   - email: email that the user types in
    ///   - password: password that the
    func login(withEmail email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            try await updateUserSession()
            
        } catch {
            ////print("DEBUG: Login failed \(error.localizedDescription)")
            throw error
        }
    }
    
    //MARK: Create User (With Email)
    func createUser(email: String, password: String, username: String, fullname: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = User(id: result.user.uid, username: username, fullname: fullname, privateMode: false)
            let userData = try Firestore.Encoder().encode(user)
            try await FirestoreConstants.UserCollection.document(result.user.uid).setData(userData)
            try await updateUserSession()
        } catch {
            ////print("DEBUG: Failed to create user with error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateFirestoreUser(
        id: String,
        username: String? = nil,
        fullname: String? = nil,
        birthday: Date? = nil,
        location: Location? = nil,
        phoneNumber: String? = nil,
        hasCompletedSetup: Bool,
        referrer: String? = nil,
        generateReferralCode: Bool = false  // New parameter with default value
    ) async throws -> User {
        let userRef = FirestoreConstants.UserCollection.document(id)
        
        var updatedUserData: [String: Any] = [:]
        
        if let username = username, !username.isEmpty {
            updatedUserData["username"] = username
            
            // Generate referral code if requested and username is available
            if generateReferralCode {
                let randomDigits = String(format: "%03d", Int.random(in: 0...999))
                let referralCode = "\(username)\(randomDigits)"
                updatedUserData["referralCode"] = referralCode
                updatedUserData["remainingReferrals"] = 3
            }
        }
        
        if let fullname = fullname, !fullname.isEmpty {
            updatedUserData["fullname"] = fullname
        }
        
        if let phoneNumber = phoneNumber, !phoneNumber.isEmpty {
            updatedUserData["phoneNumber"] = phoneNumber
        }
        
        if let birthday = birthday {
            updatedUserData["birthday"] = Timestamp(date: birthday)
        }
        
        if let location = location {
            updatedUserData["location"] = try Firestore.Encoder().encode(location)
        }
        
        if let referrer = referrer {
            updatedUserData["referredBy"] = referrer
        }
        
        updatedUserData["createdAt"] = Timestamp(date: Date())
        updatedUserData["lastActive"] = Timestamp(date: Date())
        updatedUserData["hasCompletedSetup"] = hasCompletedSetup
        
        do {
            try await userRef.setData(updatedUserData, merge: true)
            
            let updatedUser = try await userRef.getDocument(as: User.self)
            self.userSession = updatedUser
            
            return updatedUser
        } catch {
            throw error
        }
    }
    private func generateAlphanumericCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let allowedChars = Array(letters + numbers)
        var code = ""
        
        // Generate 7 random characters
        for _ in 0..<7 {
            if let randomChar = allowedChars.randomElement() {
                code.append(randomChar)
            }
        }
        return code
    }
    func createContactAlertUser(
        user: User
    ) async throws  {
        // Get the current date for createdAt and lastActive
        
        let userData = try Firestore.Encoder().encode(user)
        
        do {
            try await FirestoreConstants.alertCollection.document(user.id).setData(userData)
            ////print("DEBUG: Successfully created Contact user document in Firestore with ID: \(user.id)")
            
        } catch {
            ////print("DEBUG: Failed to create user document in Firestore with error: \(error.localizedDescription)")
            throw error
        }
    }
    func createFirestoreUser(
        id: String,
        username: String,
        fullname: String = "",
        birthday: Date? = nil,
        location: Location? = nil,
        phoneNumber: String? = nil,
        privateMode: Bool = false
    ) async throws -> User {
        let db = Firestore.firestore()
        let usersCollection = db.collection("users")
        
        // Fetch the user with the highest waitlistNumber
        let querySnapshot = try await usersCollection
            .order(by: "waitlistNumber", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        var highestWaitlistNumber = 0
        if let highestUserDoc = querySnapshot.documents.first,
           let waitlistNumber = highestUserDoc.data()["waitlistNumber"] as? Int {
            highestWaitlistNumber = waitlistNumber
        }
        let newWaitlistNumber = max(highestWaitlistNumber + 1, 537)
        // Get the current date for createdAt and lastActive
        let user = User(
            id: id,
            username: username,
            fullname: fullname,
            phoneNumber: phoneNumber,
            profileImageUrl: nil,
            privateMode: privateMode,
            notificationAlert: 0,
            location: location,
            birthday: birthday,
            hasCompletedSetup: false,
            waitlistNumber: newWaitlistNumber// Set this to false for incomplete profiles
            // Set the lastActive timestamp
        )
        
        let userData = try Firestore.Encoder().encode(user)
        
        do {
            try await FirestoreConstants.UserCollection.document(id).setData(userData)
            ////print("DEBUG: Successfully created user document in Firestore with ID: \(id)")
            return user
        } catch {
            ////print("DEBUG: Failed to create user document in Firestore with error: \(error.localizedDescription)")
            throw error
        }
    }
    //MARK: sendResetPasswordLink
    func sendResetPasswordLink(toEmail email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    //MARK: signout
    func signout() {
        self.userSession = nil
        try? Auth.auth().signOut()
    }
    //MARK: signInWithGoogle
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("No client ID found in Firebase Configuration")
        }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            ////print("There is no root view controller")
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        do {
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = userAuthentication.user
            guard let idToken = user.idToken else {
                throw AuthenticationError.tokenError(message: "ID token missing")
            }
            let fullName = user.profile?.name
            let givenName = user.profile?.givenName
            //let familyName = user.profile?.familyName
            let accessToken = user.accessToken
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString,
                                                           accessToken: accessToken.tokenString)
            let result = try await Auth.auth().signIn(with: credential)
            
            let firebaseUser = result.user
            ////print("User \(firebaseUser.uid) signed in with email \(firebaseUser.email ?? "unknown")")
            
            //Creates user in firestore if the user doesnt exist then updates the user session
            let userRef = FirestoreConstants.UserCollection.document(firebaseUser.uid)
            do {
                let document = try await userRef.getDocument()
                if document.exists {
                    try await updateUserSession()
                    return
                }
                else {
                    let randomUsername = try await generateRandomUsername(prefix: givenName)
                    let user = User(id: firebaseUser.uid, username: randomUsername, fullname: fullName ?? "", privateMode: false)
                    let userData = try Firestore.Encoder().encode(user)
                    try await FirestoreConstants.UserCollection.document(result.user.uid).setData(userData)
                    try await updateUserSession()
                }
            } catch {
                ////print("Error getting document: \(error)")
            }
        } catch {
            ////print(error.localizedDescription)
            //self.authError = AuthError(authErrorCode: error.localizedDescription)
        }
    }
    enum AuthenticationError: Error {
        case tokenError(message: String)
    }
    //MARK: generateRandomUsername
    func generateRandomUsername(prefix: String?) async throws -> String {
        var usernameExists = true
        var usernameToCheck = ""
        // Loop until a unique username is generated
        while usernameExists {
            // Generate 5 random digits for the username
            let randomDigits = String(format: "%05d", Int.random(in: 0..<10000000))
            usernameToCheck = "\(prefix?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? "user")\(randomDigits)"
            
            // Check if the username already exists in Firestore
            let query = FirestoreConstants.UserCollection.whereField("username", isEqualTo: usernameToCheck)
            let querySnapshot = try await query.getDocuments()
            if querySnapshot.documents.isEmpty {
                // Username is unique, exit the loop
                usernameExists = false
            }
        }
        return usernameToCheck
    }
    //MARK: reAuthWithGoogle
    func reAuthWithGoogle() async throws -> Bool {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("No client ID found in Firebase Configuration")
        }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            ////print("There is no root view controller")
            return false
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        // do {
        let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        let user = userAuthentication.user
        guard let idToken = user.idToken else {
            throw AuthenticationError.tokenError(message: "ID token missing")
        }
        let accessToken = user.accessToken
        let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString,
                                                       accessToken: accessToken.tokenString)
        ///Reauthenticates user if bool is true and exists function
        do {
            try await Auth.auth().currentUser?.reauthenticate(with: credential)
            // Reauthentication successful
            try await deleteAccount()
            return false
            
        } catch {
            ////print("Reauthentication with Google failed: \(error.localizedDescription)")
            return false
            // Handle reauthentication failure here, such as showing an alert to the user
            
        }
    }
    //MARK: reAuth
    func reAuth(withEmail email: String, password: String) async throws {
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await Auth.auth().currentUser?.reauthenticate(with: credential)
            try await deleteAccount()
        } catch {
            ////print("DEBUG: reauth failed \(error.localizedDescription)")
            throw error
        }
    }
    func deleteAccount() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "NoUser", code: 404, userInfo: [NSLocalizedDescriptionKey: "No current user found."])
        }
        
        let userId = currentUser.uid
        let db = Firestore.firestore()
        
        // Get user data to access collections array
        let userDoc = try await db.collection("users").document(userId).getDocument()
        if let userData = userDoc.data(),
           let collections = userData["collections"] as? [String] {
            
            // Delete each collection and its saved posts
            for collectionId in collections {
                let collectionRef = db.collection("collections").document(collectionId)
                
                // Delete all saved posts in the collection
                let savedPostsSnapshot = try await collectionRef.collection("saved-posts").getDocuments()
                for savedPost in savedPostsSnapshot.documents {
                    try await savedPost.reference.delete()
                }
                
                // Delete the collection document itself
                try await collectionRef.delete()
            }
        }
        
        // Delete the user's posts
        let postsQuery = db.collection("posts").whereField("user.id", isEqualTo: userId)
        let postsSnapshot = try await postsQuery.getDocuments()
        for document in postsSnapshot.documents {
            // Delete comments subcollection for each post
            let commentsSnapshot = try await document.reference.collection("post-comments").getDocuments()
            for comment in commentsSnapshot.documents {
                try await comment.reference.delete()
            }
            
            // Delete the post document
            try await document.reference.delete()
        }
        
        // Delete user's subcollections
        let userRef = db.collection("users").document(userId)
        let subcollections = ["user-badges"] // Add other subcollections if needed
        for subcollection in subcollections {
            let subcollectionSnapshot = try await userRef.collection(subcollection).getDocuments()
            for doc in subcollectionSnapshot.documents {
                try await doc.reference.delete()
            }
        }
        
        // Delete the user's data in the "users" collection
        try await userRef.delete()
        
        // Delete the user's authentication account
        try await currentUser.delete()
        
        // Clear the user session
        self.userSession = nil
    }
}
