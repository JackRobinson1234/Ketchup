//
//  ReviewOptionsSheet.swift
//  Foodi
//
//  Created by Jack Robinson on 5/21/24.
//

import SwiftUI
import FirebaseAuth

struct ReviewOptionsSheet: View {
    var review: Review
    @ObservedObject var viewModel: ReviewsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State var showReportDetails = false
    @State var optionsSheetDismissed: Bool = false
    var body: some View {
        VStack(spacing: 20) {
            ReviewCell(review: review, viewModel: viewModel, previewMode: true)
                Divider()
            if let currentUser = Auth.auth().currentUser?.uid, review.user.id == currentUser {
                Button {
                    showingDeleteAlert = true
                } label: {
                    Text("Delete Review")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .alert(isPresented: $showingDeleteAlert) {
                    Alert(
                        title: Text("Delete Review"),
                        message: Text("Are you sure you want to delete this review?"),
                        primaryButton: .destructive(Text("Delete")) {
                            Task {
                                try await viewModel.deleteReview(reviewId: review.id)
                                optionsSheetDismissed = true
                                dismiss()
                            }
                        },
                        secondaryButton: .cancel(Text("Cancel"))
                    )
                }
            } else {
                Button {
                    showReportDetails = true
                } label: {
                    Text("Report Review")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
            }
        }
        .onChange(of: optionsSheetDismissed) {
            if optionsSheetDismissed {
                dismiss()
            }
        }
        .onAppear {
            if optionsSheetDismissed {
                dismiss()
            }
        }
        .padding()
        .sheet(isPresented: $showReportDetails) {
            ReportingView(contentId: review.id, objectType: "review", dismissView: $optionsSheetDismissed )
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                .onDisappear{
                    dismiss()
                }
                
        }
        
    }
}

//#Preview {
//    ReviewOptionsSheet()
//}
