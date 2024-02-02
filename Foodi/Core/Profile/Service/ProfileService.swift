//
//  ProfileService.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation

class ProfileService {
    
    private let userService: UserService
    private let postService: PostService
    
    init(userService: UserService, postService: PostService) {
        self.userService = userService
        self.postService = postService
    }
}
