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
    
    //MARK: updateUserSession
    /// Updates the user session based on the current authentication status.
    /// This method first checks if there is a user session stored in UserDefaults. If found and the stored user ID matches the currently authenticated user ID, it sets the user session to the stored user data. If not found or the IDs don't match, it fetches the user data from Firestore and updates the user session accordingly.
    /// - Throws: An error if there's a problem decoding user data from UserDefaults or fetching user data from Firestore.
    func updateUserSession() async throws {
        guard let authUser = Auth.auth().currentUser?.uid else {
            self.userSession = nil
            return
        }
        do {
            let userDocument = try await FirestoreConstants.UserCollection.document(authUser).getDocument(as: User.self)
            self.userSession = userDocument
        } catch {
            print("Error updating user session:", error.localizedDescription)
            throw error
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
            print("DEBUG: Login failed \(error.localizedDescription)")
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
            print("DEBUG: Failed to create user with error: \(error.localizedDescription)")
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
            print("There is no root view controller")
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
            print("User \(firebaseUser.uid) signed in with email \(firebaseUser.email ?? "unknown")")
            
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
              print("Error getting document: \(error)")
            }
        } catch {
            print(error.localizedDescription)
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
            print("There is no root view controller")
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
                print("Reauthentication with Google failed: \(error.localizedDescription)")
                return false
                // Handle reauthentication failure here, such as showing an alert to the user
               
                
            }
//        } catch {
//            print(error.localizedDescription)
//            //self.authError = AuthError(authErrorCode: error.localizedDescription)
//        }
        //try await deleteAccount()
    }
    //MARK: reAuth
    func reAuth(withEmail email: String, password: String) async throws {
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await Auth.auth().currentUser?.reauthenticate(with: credential)
            try await deleteAccount()
        } catch {
            print("DEBUG: reauth failed \(error.localizedDescription)")
            throw error
        }
    }
    func deleteAccount() async throws{
        try await Auth.auth().currentUser?.delete()
        self.userSession = nil
    }
}
