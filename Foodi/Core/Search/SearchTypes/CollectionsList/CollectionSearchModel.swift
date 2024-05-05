//
//  CollectionSearchModel.swift
//  Foodi
//
//  Created by Jack Robinson on 4/22/24.
//

import Foundation
struct CollectionSearchModel: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var username: String
    var description: String?
}
