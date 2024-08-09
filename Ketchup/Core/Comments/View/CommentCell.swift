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
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    @State private var commentHeight: CGFloat = 0
    @State private var showingDeleteAlert = false
    @State private var showReportDetails = false
    
    private let optionsWidth: CGFloat = 60
    
    var body: some View {
        ZStack(alignment: .trailing) {
            actionButton
            
            mainCommentContent
                .background(Color.white)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged(onChanged)
                        .onEnded(onEnded)
                )
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: HeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
        }
        .frame(maxWidth: .infinity)
        .background(
            Color.gray.opacity(0.1)
                .offset(x: offset > 0 ? 0 : offset)
        )
        .onPreferenceChange(HeightPreferenceKey.self) { height in
            self.commentHeight = height
        }
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
        .sheet(isPresented: $showReportDetails) {
            ReportingView(contentId: comment.id, objectType: "comment", dismissView: .constant(false))
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
        }
    }
    
    private var mainCommentContent: some View {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    viewModel.selectedUserComment = comment
                } label: {
                    UserCircularProfileImageView(profileImageUrl: comment.commentOwnerProfileImageUrl, size: .small)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Button {
                            viewModel.selectedUserComment = comment
                        } label: {
                            Text("@\(comment.commentOwnerUsername)")
                                .fontWeight(.semibold)
                                .font(.custom("MuseoSansRounded-300", size: 14))
                        }
                        Text("\(comment.timestamp.timestampString())")
                            .foregroundColor(.gray)
                            .font(.custom("MuseoSansRounded-300", size: 12))
                    }
                    
                    if let parsed = parsedComment {
                        Text(parsed)
                            .font(.custom("MuseoSansRounded-300", size: 14))
                    } else {
                        Text(comment.commentText)
                            .font(.custom("MuseoSansRounded-300", size: 14))
                            .onAppear {
                                parsedComment = parseComment(comment.commentText)
                            }
                    }
                }
                
                Spacer()
                
                if !previewMode {
                    likeButton
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    
    private var likeButton: some View {
        VStack {
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

#Preview {
    CommentCell(comment: DeveloperPreview.comment, viewModel: CommentViewModel(post: .constant(DeveloperPreview.posts[0])))
}


