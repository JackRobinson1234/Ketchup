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
        let db = Firestore.firestore()
        let reportRef = FirestoreConstants.ReportsCollection.document(contentId).collection("reports").document()
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ReportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let report = Report(id: reportRef.documentID, contentId: contentId, reporterId: uid, reasons: reasons, status: status, timestamp: Timestamp(), objectType: objectType)
        
        do {
            let reportData = try Firestore.Encoder().encode(report)
            
            // Start a batch write
            let batch = db.batch()
            
            // Add the report
            batch.setData(reportData, forDocument: reportRef)
            
            // Update the post's isReported field
            if objectType == "post"{
                let postRef = db.collection("posts").document(contentId)
                batch.updateData(["isReported": true], forDocument: postRef)
            }
            
            // Commit the batch
            try await batch.commit()
            
            print("Report uploaded and post updated successfully")
        } catch {
            print("Error uploading report and updating post: \(error.localizedDescription)")
            throw error
        }
    }
}
