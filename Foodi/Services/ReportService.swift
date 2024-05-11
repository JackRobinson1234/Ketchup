//
//  ReportService.swift
//  Foodi
//
//  Created by Jack Robinson on 5/11/24.
//

import Foundation
import SwiftUI
import FirebaseFirestoreInternal
class ReportService {
    static let shared = ReportService() // Singleton instance
    private init() {}
    func uploadReport(contentId: String, reporterId: String, reason: String, status: String, objectType: String) async throws {
        
            let ref = FirestoreConstants.ReportsCollection.document()
            let report = Report(id: ref.documentID, contentId: contentId, reporterId: reporterId, reason: reason, status: status, timestamp: Timestamp(), objectType: objectType)
            
            guard let reportData = try? Firestore.Encoder().encode(report) else {
                print("not encoding collection right")
                return
            }
        do {
            try await ref.setData(reportData)
        } catch {
            print("uploading a report failed")
        }
    }
}
