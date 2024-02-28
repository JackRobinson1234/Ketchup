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
    
    private let userService: UserService
    private let postService: PostService
    
    init(user: User, userService: UserService, postService: PostService) {
        self.user = user
        self.userService = userService
        self.postService = postService
    }
    
    func fetchUserLikedPosts() async {
        do {
            self.posts = try await postService.fetchUserLikedPosts(user: user)
        } catch {
            print("DEBUG: Failed to fetch posts with error: \(error.localizedDescription)")
        }
    }
}

