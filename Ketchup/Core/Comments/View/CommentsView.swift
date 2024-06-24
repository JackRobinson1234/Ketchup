//
//  CommentsView.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import SwiftUI

struct CommentsView: View {
    @StateObject var viewModel: CommentViewModel
    
    init(post: Binding<Post>) {
        let viewModel = CommentViewModel(post: post)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            if !viewModel.comments.isEmpty {
                Text(viewModel.commentCountText)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .fontWeight(.semibold)
                    .padding(.top, 24)
            }
            
            Divider()
            
            List {
                VStack(spacing: 24) {
                    ForEach(viewModel.comments) { comment in
                        CommentCell(comment: comment, viewModel: viewModel)
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
            
            Divider()
                .padding(.bottom)
            
            HStack(spacing: 12) {
                UserCircularProfileImageView(profileImageUrl: AuthService.shared.userSession?.profileImageUrl, size: .xSmall)
                
                CommentInputView(viewModel: viewModel)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .sheet(isPresented: $viewModel.showOptionsSheet) {
            if let comment = viewModel.selectedComment{
                CommentOptionsSheet(comment: comment, viewModel: viewModel)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.10)])
            }
        }
        .overlay {
            if viewModel.showEmptyView {
                ContentUnavailableView("No comments yet. Add yours now!", systemImage: "exclamationmark.bubble")
                    .foregroundStyle(.gray)
            }
        }
        .onChange(of: viewModel.comments.count) {
            viewModel.showEmptyView = viewModel.comments.isEmpty
        }
        .onAppear{
            Task {try await viewModel.fetchComments() }
        }
    }
}

#Preview {
    CommentsView(post: .constant(DeveloperPreview.posts[0]))
}
