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
        HStack(alignment: .top) {
            Button {
                viewModel.selectedUserComment = comment
            } label: {
                UserCircularProfileImageView(profileImageUrl: comment.user?.profileImageUrl, size: .medium)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    Button {
                        viewModel.selectedUserComment = comment
                    } label: {
                        Text("@\(comment.user?.username ?? "")")
                            .fontWeight(.semibold)
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .foregroundStyle(.primary)
                    }
                    Text("\(comment.timestamp.timestampString())")
                        .foregroundColor(.gray)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                }
                
                Text(makeAttributedString(from: comment.commentText))
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .onTapGesture {
                        handleTagTap(for: comment)
                    }
            }
            .font(.custom("MuseoSansRounded-300", size: 10))
            
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
        .padding(.horizontal)
    }
    
    private func makeAttributedString(from text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        let pattern = "@[A-Za-z0-9_]+"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        for match in matches {
            let range = match.range(at: 0)
            if let swiftRange = Range(range, in: attributedString) {
                attributedString[swiftRange].foregroundColor = Color("Colors/AccentColor")
            }
        }
        
        return attributedString
    }
    
    private func handleTagTap(for comment: Comment) {
            print("nav to prof")
    }
}


#Preview {
    CommentCell(comment: DeveloperPreview.comment, viewModel: CommentViewModel(post: .constant(DeveloperPreview.posts[0])))
}


