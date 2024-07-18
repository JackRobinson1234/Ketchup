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
    
    @State private var parsedComment: AttributedString?
    @State private var selectedUser: PostUser?
    @State private var isShowingProfileSheet = false
    
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
                
                if let parsed = parsedComment {
                    Text(parsed)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                } else {
                    Text(comment.commentText)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .onAppear {
                            parsedComment = parseComment(comment.commentText)
                        }
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
                            .cornerRadius(14)
                        
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                }
            }
        }
        .padding(.horizontal)
        .environment(\.openURL, OpenURLAction { url in
            if url.scheme == "user",
               let userId = url.host,
               let mentionedUsers = comment.mentionedUsers,
               let user = mentionedUsers.first(where: { $0.id == userId }) {
                selectedUser = user
                return .handled
            }
            return .systemAction
        })
        .onChange(of: selectedUser) {
            isShowingProfileSheet = selectedUser != nil
        }
        .sheet(isPresented: $isShowingProfileSheet) {
            if let user = selectedUser {
                NavigationStack {
                    if user.id == "invalid" {
                        Text("User does not exist")
                    } else {
                        ProfileView(uid: user.id)
                    }
                }
            }
        }
    }
    
    private func parseComment(_ input: String) -> AttributedString {
        var result = AttributedString(input)
        let pattern = "@\\w+"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return result
        }
        
        let nsRange = NSRange(input.startIndex..., in: input)
        let matches = regex.matches(in: input, range: nsRange)
        
        for match in matches.reversed() {
            guard let range = Range(match.range, in: input) else { continue }
            
            let fullMatch = String(input[range])
            let username = String(fullMatch.dropFirst()) // Remove @ from username
            
            if let mentionedUsers = comment.mentionedUsers,
               let user = mentionedUsers.first(where: { $0.username.lowercased() == username.lowercased() }),
               let attributedRange = Range(range, in: result) {
                result[attributedRange].foregroundColor = Color("Colors/AccentColor")
                result[attributedRange].link = URL(string: "user://\(user.id)")
            }
        }
        
        return result
    }
}


#Preview {
    CommentCell(comment: DeveloperPreview.comment, viewModel: CommentViewModel(post: .constant(DeveloperPreview.posts[0])))
}


