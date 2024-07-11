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
        NavigationStack{
            VStack {
                if !viewModel.comments.isEmpty {
                    Text(viewModel.commentCountText)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .fontWeight(.semibold)
                        .padding(.top, 24)
                }
                ScrollView{
                    Divider()
                    VStack(spacing: 24) {
                        ForEach(viewModel.comments) { comment in
                            CommentCell(comment: comment, viewModel: viewModel)
                        }
                    }
                    
                }
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
                    ScrollView{
                        CommentOptionsSheet(comment: comment, viewModel: viewModel)
                            .presentationDetents([.height(UIScreen.main.bounds.height * 0.3)])
                    }
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
            .navigationDestination(for: Comment.self) { comment in
                ProfileView(uid: comment.commentOwnerUid)
            }
            .fullScreenCover(item: $viewModel.selectedUserComment) { comment in
                NavigationStack{
                    if let user = viewModel.selectedUserComment?.commentOwnerUid{
                        ProfileView(uid: user)
                            .navigationDestination(for: PostRestaurant.self) { restaurant in
                                RestaurantProfileView(restaurantId: restaurant.id)
                            }
                    }
                }
            }
        }
    }
}

#Preview {
    CommentsView(post: .constant(DeveloperPreview.posts[0]))
}
