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
    var previewMode: Bool = false
    
    var body: some View {
        HStack (alignment: .top){
            UserCircularProfileImageView(profileImageUrl: comment.user?.profileImageUrl, size: .medium )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    Text("@\(comment.user?.username ?? "")")
                        .fontWeight(.semibold)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    
                    Text(" \(comment.timestamp.timestampString())")
                        .foregroundColor(.gray)
                        .font(.footnote)
                }
                
                Text(comment.commentText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .font(.caption)
            
            Spacer()
            if !previewMode {
                Button {
                    viewModel.selectedComment = comment
                    viewModel.showOptionsSheet = true
                } label: {
                    ZStack {
                           Color.clear
                               .frame(width: 28, height: 28)
                               .cornerRadius(14) // Optional: Adds a rounded corner
                           
                           Image(systemName: "ellipsis")
                               .foregroundColor(.gray)
                               .font(.system(size: 18))
                       }
                }
 
            }
        }
    }
}

#Preview {
    CommentCell(comment: DeveloperPreview.comment, viewModel: CommentViewModel(post: .constant(DeveloperPreview.posts[0])))
}


