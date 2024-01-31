//
//  AuthServiceProtocol.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import Foundation

protocol AuthServiceProtocol {
    func login(withEmail email: String, password: String) async throws
    func createUser(withEmail email: String, password: String, username: String) async throws
    func signout()
}
