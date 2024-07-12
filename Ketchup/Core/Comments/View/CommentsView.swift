import SwiftUI

struct CommentsView: View {
    @StateObject var viewModel: CommentViewModel
    
    init(post: Binding<Post>) {
        let viewModel = CommentViewModel(post: post)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if !viewModel.comments.isEmpty && !viewModel.isTagging {
                    Text(viewModel.commentCountText)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .fontWeight(.semibold)
                        .padding(.top, 24)
                }
                ScrollView {
                    Divider()
                    VStack(spacing: 24) {
                        if viewModel.isTagging {
                            Text("Tag Users")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .fontWeight(.bold)
                                .padding(.top, 10)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(viewModel.filteredTaggedUsers, id: \.id) { user in
                                Button(action: {
                                    let username = user.username
                                    var words = viewModel.commentText.split(separator: " ").map(String.init)
                                    words.removeLast()
                                    words.append("@" + username)
                                    viewModel.commentText = words.joined(separator: " ") + " "
                                    viewModel.isTagging = false
                                }) {
                                    UserCell(user: user)
                                        .padding(.horizontal)
                                }
                                .contentShape(Rectangle())
                            }
                        } else {
                            ForEach(viewModel.comments) { comment in
                                CommentCell(comment: comment, viewModel: viewModel)
                            }
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
                if let comment = viewModel.selectedComment {
                    ScrollView {
                        CommentOptionsSheet(comment: comment, viewModel: viewModel)
                            .presentationDetents([.height(UIScreen.main.bounds.height * 0.3)])
                    }
                }
            }
            .overlay {
                if viewModel.showEmptyView && !viewModel.isTagging {
                    ContentUnavailableView("No comments yet. Add yours now!", systemImage: "exclamationmark.bubble")
                        .foregroundStyle(.gray)
                }
            }
            .onChange(of: viewModel.comments.count) { _ in
                viewModel.showEmptyView = viewModel.comments.isEmpty
            }
            .onAppear {
                Task { try await viewModel.fetchComments() }
            }
            .navigationDestination(for: Comment.self) { comment in
                ProfileView(uid: comment.commentOwnerUid)
            }
            .fullScreenCover(item: $viewModel.selectedUserComment) { comment in
                NavigationStack {
                    if let user = viewModel.selectedUserComment?.commentOwnerUid {
                        ProfileView(uid: user)
                            .navigationDestination(for: PostRestaurant.self) { restaurant in
                                RestaurantProfileView(restaurantId: restaurant.id)
                            }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

#Preview {
    CommentsView(post: .constant(DeveloperPreview.posts[0]))
}
