//
//  UserListConfig.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import Foundation

enum UserListConfig: Hashable {
    case followers(uid: String)
    case following(uid: String)
    case likes(uid: String)
    case users
    
    
    var navigationTitle: String {
        switch self {
        case .followers: return "Followers"
        case .following: return "Following"
        case .likes: return "Likes"
        case .users: return "Explore"
        }
    }
}
