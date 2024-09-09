//
//  ReportService.swift
//  Foodi
//
//  Created by Jack Robinson on 5/11/24.
//

import Foundation
import SwiftUI
import FirebaseFirestoreInternal
import FirebaseAuth
import Firebase
class ReportService {
    static let shared = ReportService() // Singleton instance
    private init() {}
    func uploadReport(contentId: String, reasons: [String], status: String, objectType: String) async throws {
        
        let ref = FirestoreConstants.ReportsCollection.document(contentId).collection("reports").document()
        if let uid = Auth.auth().currentUser?.uid {
            let report = Report(id: ref.documentID, contentId: contentId, reporterId: uid, reasons: reasons, status: status, timestamp: Timestamp(), objectType: objectType)
            guard let reportData = try? Firestore.Encoder().encode(report) else {
                //print("not encoding report right")
                return
            }
            
            do {
                try await ref.setData(reportData)
            } catch {
                //print("uploading a report failed")
            }
        }
    }
}
