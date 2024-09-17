//
//  CommentCell.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI
import UIKit

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
    @Environment(\.openURL) private var openURL
    @State var isReported: Bool = false
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
            if comment.commentOwnerUsername == "Deleted" {
                HStack{
                    Text("Original Comment has been deleted")
                        .font(.custom("MuseoSansRounded-300", size: 14))
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            } else {
                actionButton
                VStack(alignment: .leading, spacing: 8) {
                    
                    mainCommentContent
                    
                }
                
                .background(Color.white)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged(onChanged)
                        .onEnded(onEnded)
                )
                
                .frame(maxWidth: .infinity)
                .background(
                    Color.gray.opacity(0.1)
                        .offset(x: offset > 0 ? 0 : offset)
                )
            }
        }
    }
    
    private var mainCommentContent: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                viewModel.selectedUserComment = comment
            } label: {
                UserCircularProfileImageView(profileImageUrl: comment.commentOwnerProfileImageUrl, size: .small)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack (alignment: .bottom){
                    Button {
                        viewModel.selectedUserComment = comment
                    } label: {
                        Text("@\(comment.commentOwnerUsername)")
                            .fontWeight(.semibold)
                            .font(.custom("MuseoSansRounded-300", size: 14))
                            .foregroundColor(.black)
                            .lineLimit(1) // Limit to one line
                            .minimumScaleFactor(0.5) // Allow scaling down to 0.5
                    }
                    if isReply, let replyTo = comment.replyTo {
                        Text("replying to @\(replyTo.username)")
                            .foregroundColor(.gray)
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .lineLimit(1) // Limit to one line
                            .minimumScaleFactor(0.5) // Allow scaling down to 0.5
                    }
                    Text("\(comment.timestamp.timestampString())")
                        .foregroundColor(.gray)
                        .font(.custom("MuseoSansRounded-300", size: 12))
                }
                Spacer().frame(height: 6)
                if let parsed = parsedComment {
                    Text(parsed)
                        .font(.custom("MuseoSansRounded-300", size: 14))
                } else {
                    Text(comment.commentText)
                        .font(.custom("MuseoSansRounded-300", size: 14))
                        .foregroundColor(.black)
                        .onAppear {
                            parsedComment = parseComment(comment.commentText)
                        }
                }
                Spacer().frame(height: 6)
                HStack {
                    Button(action: {
                        viewModel.initiateReply(to: comment, replyToUser: comment.commentOwnerUsername)
                    }) {
                        Text("Reply")
                            .font(.custom("MuseoSansRounded-500", size: 12))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            Spacer()
            likeButton
        }
        .padding(.horizontal)
        .padding(.vertical, 3)
        .background(
            Rectangle()
                .fill(comment.isHighlighted ? Color.red.opacity(0.1) : Color.clear)
        )
    
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
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Comment"),
                message: Text("Are you sure you want to delete this comment?"),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        try await viewModel.deleteComment(comment: comment)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: selectedUser) {
            isShowingProfileSheet = selectedUser != nil
        }
        
        
        .sheet(isPresented: $showReportDetails) {
            ReportingView(contentId: comment.id, objectType: "comment",isReported: $isReported, dismissView: .constant(false))
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
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
                .onDisappear{
                    selectedUser = nil
                    isShowingProfileSheet = false
                }
            }
        }
    }
    
    
    private var likeButton: some View {
        VStack(spacing: 4) {
            Button(action: {
                Task {
                    if comment.didLike {
                        await viewModel.unlike(comment)
                    } else {
                        await viewModel.like(comment)
                        triggerHapticFeedback() // Trigger haptics on like
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
        .padding(.top, 4)
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
                .foregroundColor(.gray)  // Icon color changes to white when swiped
                .font(.system(size: 18))
        }
        .frame(width: optionsWidth)
        .frame(height: commentHeight)
        .background(isSwiped ? Color.red : Color.gray.opacity(0.2))  // Background changes to red when swiped
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
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
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
