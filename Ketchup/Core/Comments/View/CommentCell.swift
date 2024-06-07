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
                    ZStack {
                           Color.clear
                               .frame(width: 28, height: 28)
                               .cornerRadius(14) // Optional: Adds a rounded corner
                           
                           Image(systemName: "ellipsis")
                               .foregroundColor(.gray)
                               .font(.system(size: 18))
                       }
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


