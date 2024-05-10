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
    @State private var showingDeleteAlert = false
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
            if let user = comment.user, user.isCurrentUser {
                            Button {
                                showingDeleteAlert = true
                            } label: {
                                Text("Delete")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                            .alert(isPresented: $showingDeleteAlert) {
                                Alert(
                                    title: Text("Delete Comment"),
                                    message: Text("Are you sure you want to delete this comment?"),
                                    primaryButton: .destructive(Text("Delete")) {
                                        Task {
                                            try await viewModel.deleteComment(comment: comment)
                                        }
                                    },
                                    secondaryButton: .cancel(Text("Cancel"))
                                )
                            }
                        }
                    }
                }
            }

#Preview {
    CommentCell(comment: DeveloperPreview.comment, viewModel: CommentViewModel(post: .constant(DeveloperPreview.posts[0])))
}
