//
//  Contact.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/18/24.
//

import Foundation

struct Contact: Codable, Identifiable, Hashable {
    let id: String
    var phoneNumber: String
    var userCount: Int
    var hasExistingAccount: Bool?
    var isFollowed: Bool?
    var user: User?
    var deviceContactName: String?

    enum CodingKeys: String, CodingKey {
        case phoneNumber, userCount, hasExistingAccount, isFollowed
    }
    
    init(id: String = UUID().uuidString, phoneNumber: String, userCount: Int = 0, hasExistingAccount: Bool? = nil, isFollowed: Bool? = nil) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.userCount = userCount
        self.hasExistingAccount = hasExistingAccount
        self.isFollowed = isFollowed
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        self.id = self.phoneNumber
        
        self.userCount = try container.decodeIfPresent(Int.self, forKey: .userCount) ?? 0
        self.hasExistingAccount = try container.decodeIfPresent(Bool.self, forKey: .hasExistingAccount) ?? false
        self.isFollowed = try container.decodeIfPresent(Bool.self, forKey: .isFollowed)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(userCount, forKey: .userCount)
        try container.encodeIfPresent(hasExistingAccount, forKey: .hasExistingAccount)
        try container.encodeIfPresent(isFollowed, forKey: .isFollowed)
    }
}

