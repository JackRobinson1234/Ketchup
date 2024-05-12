//
//  CommentCell.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI

struct CommentCell: View {
    let comment: Comment
    @ObservedObject var viewModel: CommentViewModel
    @State private var showingOptionsSheet = false
    var previewMode: Bool = false
    
    var body: some View {
        HStack {
            UserCircularProfileImageView(profileImageUrl: comment.user?.profileImageUrl, size: .xxSmall)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    Text(comment.user?.username ?? "")
                        .fontWeight(.semibold)
                    
                    Text(" \(comment.timestamp.timestampString())")
                        .foregroundColor(.gray)
                }
                
                Text(comment.commentText)
            }
            .font(.caption)
            
            Spacer()
            if !previewMode {
                Button {
                    showingOptionsSheet = true
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                }
                .sheet(isPresented: $showingOptionsSheet) {
                    CommentOptionsSheet(comment: comment, viewModel: viewModel)
                        .presentationDetents([.height(UIScreen.main.bounds.height * 0.15)])
                }
            }
        }
    }
}

#Preview {
    CommentCell(comment: DeveloperPreview.comment, viewModel: CommentViewModel(post: .constant(DeveloperPreview.posts[0])))
}


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



