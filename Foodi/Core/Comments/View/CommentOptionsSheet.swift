//
//  CommentOptionsSheet.swift
//  Foodi
//
//  Created by Jack Robinson on 5/21/24.
//

import SwiftUI

struct CommentOptionsSheet: View {
    let comment: Comment
    @ObservedObject var viewModel: CommentViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State var showReportDetails = false
    @State var optionsSheetDismissed: Bool = false
    var body: some View {
        VStack(spacing: 20) {
                CommentCell(comment: comment, viewModel: viewModel, previewMode: true)
                Divider()
            if let user = comment.user, user.isCurrentUser {
                Button {
                    showingDeleteAlert = true
                } label: {
                    Text("Delete Comment")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .alert(isPresented: $showingDeleteAlert) {
                    Alert(
                        title: Text("Delete Comment"),
                        message: Text("Are you sure you want to delete this comment?"),
                        primaryButton: .destructive(Text("Delete")) {
                            Task {
                                try await viewModel.deleteComment(comment: comment)
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
                    Text("Report Comment")
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
            ReportingView(contentId: comment.id, objectType: "comment", dismissView: $optionsSheetDismissed )
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                .onDisappear{
                    dismiss()
                }
                
        }
        
    }
}




