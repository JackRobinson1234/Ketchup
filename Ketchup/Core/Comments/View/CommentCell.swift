//
//  CommentCell.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI

struct CommentCell: View {
    let comment: Comment
    let replies: [Comment]
    @ObservedObject var viewModel: CommentViewModel
    let isReply: Bool
    
    @State private var parsedComment: AttributedString?
    @State private var selectedUser: PostUser?
    @State private var isShowingProfileSheet = false
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    @State private var commentHeight: CGFloat = 0
    @State private var showingDeleteAlert = false
    @State private var showReportDetails = false
    @State private var isHighlighted = false
    
    private let optionsWidth: CGFloat = 60
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            commentContent
            
            if !isReply && !replies.isEmpty {
                ForEach(replies) { reply in
                    CommentCell(comment: reply, replies: [], viewModel: viewModel, isReply: true)
                        .padding(.leading, 20)
                }
            }
        }
    }
    
    private var commentContent: some View {
        ZStack(alignment: .trailing) {
            if comment.commentOwnerUsername != "Deleted" {
                actionButton
            }
            
            VStack(alignment: .leading, spacing: 8) {
                mainCommentContent
                    .background(isHighlighted ? Color.red.opacity(0.1) : Color.clear)
                    .animation(.easeInOut(duration: 3).delay(3), value: isHighlighted)
            }
            .background(Color.white)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged(onChanged)
                    .onEnded(onEnded)
            )
        }
        .frame(maxWidth: .infinity)
        .background(
            Color.gray.opacity(0.1)
                .offset(x: offset > 0 ? 0 : offset)
        )
    }
    
    private var mainCommentContent: some View {
           HStack(alignment: .top, spacing: 12) {
               if comment.commentOwnerUsername != "Deleted" {
                   UserCircularProfileImageView(profileImageUrl: comment.commentOwnerProfileImageUrl, size: .small)
               }
               
               VStack(alignment: .leading, spacing: 4) {
                   if comment.commentOwnerUsername != "Deleted" {
                       HStack {
                           Text("@\(comment.commentOwnerUsername)")
                               .fontWeight(.semibold)
                               .font(.custom("MuseoSansRounded-300", size: 14))
                           if isReply, let replyTo = comment.replyTo {
                               Text("replying to @\(replyTo.username)")
                                   .foregroundColor(.gray)
                                   .font(.custom("MuseoSansRounded-300", size: 12))
                           }
                           Text("\(comment.timestamp.timestampString())")
                               .foregroundColor(.gray)
                               .font(.custom("MuseoSansRounded-300", size: 12))
                       }
                   }
                   
                   if let parsed = parsedComment {
                       Text(parsed)
                           .font(.custom("MuseoSansRounded-300", size: 14))
                   } else {
                       Text(comment.commentText)
                           .font(.custom("MuseoSansRounded-300", size: 14))
                           .foregroundColor(comment.commentOwnerUsername == "Deleted" ? .gray : .black)
                           .onAppear {
                               parsedComment = parseComment(comment.commentText)
                           }
                   }
                   
                   if comment.commentOwnerUsername != "Deleted" {
                       HStack {
                           Button(action: {
                               viewModel.initiateReply(to: comment, replyToUser: comment.commentOwnerUsername)
                           }) {
                               Text("Reply")
                                   .font(.custom("MuseoSansRounded-300", size: 12))
                                   .foregroundColor(.gray)
                           }
                           
                           Spacer()
                           
                           likeButton
                       }
                   }
               }
           }
           .padding(.horizontal)
           .padding(.vertical, 8)
       }
    
    private var likeButton: some View {
        HStack(spacing: 4) {
            Button(action: {
                Task {
                    if comment.didLike {
                        await viewModel.unlike(comment)
                    } else {
                        await viewModel.like(comment)
                    }
                }
            }) {
                Image(systemName: comment.didLike ? "heart.fill" : "heart")
                    .foregroundColor(comment.didLike ? .red : .gray)
                    .font(.system(size: 16))
            }
            
            if comment.likes > 0 {
                Text("\(comment.likes)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var actionButton: some View {
        Button(action: {
            if comment.commentOwnerUid == AuthService.shared.userSession?.id {
                showingDeleteAlert = true
            } else {
                showReportDetails = true
            }
        }) {
            Image(systemName: comment.commentOwnerUid == AuthService.shared.userSession?.id ? "trash" : "exclamationmark.triangle")
                .foregroundColor(.gray)
                .font(.system(size: 18))
        }
        .frame(width: optionsWidth)
        .frame(height: commentHeight)
        .background(Color.gray.opacity(0.2))
    }
    private func onChanged(value: DragGesture.Value) {
        if value.translation.width < 0 {
            offset = max(value.translation.width, -optionsWidth)
        }
    }
    
    private func onEnded(value: DragGesture.Value) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
            if value.translation.width < 0 {
                if -value.translation.width > optionsWidth / 2 {
                    offset = -optionsWidth
                    isSwiped = true
                } else {
                    offset = 0
                    isSwiped = false
                }
            } else {
                offset = 0
                isSwiped = false
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

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
