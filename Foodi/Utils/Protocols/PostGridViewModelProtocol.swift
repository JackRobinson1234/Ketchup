//
//  PostGridViewModelProtocol.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//
import SwiftUI

protocol PostGridViewModelProtocol: ObservableObject {
    nonisolated var posts: [Post] { get set }
    func fetchPosts() async throws
}
