//
//  LikedVideosViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/9/24.
//

import Foundation
import AVFoundation
import SwiftUI

@MainActor
class LikedVideosViewModel: ObservableObject {
    @Published var posts = [Post]()
    @Published var user: User
    
    init(user: User) {
        self.user = user
    }
    
    func fetchUserLikedPosts() async {
        do {
            self.posts = try await PostService.shared.fetchUserLikedPosts(user: user)
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
    }
}

