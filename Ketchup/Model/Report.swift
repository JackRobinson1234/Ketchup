//
//  Report.swift
//  Foodi
//
//  Created by Jack Robinson on 5/11/24.
//

import Foundation
import FirebaseDatabase
import SwiftUI
import FirebaseFirestoreInternal
import Firebase
struct Report: Codable {
    let id: String
    let contentId: String
    let reporterId: String
    let reasons: [String]
    let status: String
    let timestamp: Timestamp
    let objectType: String
    // Unix timestamp in seconds
    
    init(id: String, contentId: String, reporterId: String, reasons: [String], status: String, timestamp: Timestamp, objectType: String) {
        self.id = id
        self.contentId = contentId
        self.reporterId = reporterId
        self.reasons = reasons
        self.status = status
        self.timestamp = timestamp
        self.objectType = objectType
    }
}


