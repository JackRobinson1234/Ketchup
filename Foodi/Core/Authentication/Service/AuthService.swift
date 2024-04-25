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
    @Published var userSession: FirebaseAuth.User?
//MARK: updateUserSession
    func updateUserSession() {
        self.userSession = Auth.auth().currentUser
    }
    //MARK: Login
    func login(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
        } catch {
            print("DEBUG: Login failed \(error.localizedDescription)")
            throw error
        }
    }
    //MARK: Create User (With Email)
    func createUser(email: String, password: String, username: String, fullname: String) async throws {
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            
            let user = User(id: result.user.uid, username: username, email: email, fullname: fullname)
            let userData = try Firestore.Encoder().encode(user)
            
            try await FirestoreConstants.UserCollection.document(result.user.uid).setData(userData)
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
            let emailAddress = user.profile?.email
            let fullName = user.profile?.name
            let givenName = user.profile?.givenName
            let familyName = user.profile?.familyName
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
                  updateUserSession()
                  return
              } else {
                  let randomUsername = try await generateRandomUsername(prefix: givenName)
                  let user = User(id: firebaseUser.uid, username: randomUsername, email: emailAddress ?? "", fullname: fullName ?? "")
                  let userData = try Firestore.Encoder().encode(user)
                  try await FirestoreConstants.UserCollection.document(result.user.uid).setData(userData)
                  updateUserSession()
              }
            } catch {
              print("Error getting document: \(error)")
            }

            
            updateUserSession()
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
            usernameToCheck = "\(prefix ?? "user")\(randomDigits)"
            
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
}
