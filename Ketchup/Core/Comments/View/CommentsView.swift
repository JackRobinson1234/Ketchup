import SwiftUI
import InstantSearchSwiftUI

struct CommentsView: View {
    @StateObject var viewModel: CommentViewModel
    @StateObject var searchViewModel = SearchViewModel(initialSearchConfig: .users)
    let debouncer = Debouncer(delay: 1.0)
    @FocusState private var isInputFocused: Bool

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
                            taggedUsersView
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
                    CommentInputView(viewModel: viewModel, isInputFocused: _isInputFocused)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .onChange(of: viewModel.commentText) {
                handleCommentTextChange()
            }
            .onAppear {
                viewModel.fetchFollowingUsers()
            }
            .overlay {
                if viewModel.showEmptyView && !viewModel.isTagging {
                    ContentUnavailableView("No comments yet. Add yours now!", systemImage: "exclamationmark.bubble")
                        .foregroundStyle(.gray)
                }
            }
            .onChange(of: viewModel.comments.count) {
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
            .onChange(of: viewModel.shouldFocusTextField) { newValue in
                isInputFocused = newValue
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var taggedUsersView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mention Users")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .fontWeight(.bold)
                .padding(.top, 10)
                .padding(.horizontal)
            
            if !viewModel.filteredTaggedUsers.isEmpty {
                ForEach(viewModel.filteredTaggedUsers, id: \.id) { user in
                    Button(action: {
                        handleUserSelection(username: user.username)
                    }) {
                        UserCell(user: user)
                            .padding(.horizontal)
                    }
                    .contentShape(Rectangle())
                }
            } else {
                InfiniteList(searchViewModel.userHits, itemView: { hit in
                    Button {
                        handleUserSelection(username: hit.object.username)
                    } label: {
                        UserCell(user: hit.object)
                            .padding()
                    }
                    Divider()
                }, noResults: {
                    Text("No results found")
                        .foregroundStyle(.black)
                })
            }
        }
    }
    
    private func handleCommentTextChange() {
        if viewModel.filteredTaggedUsers.isEmpty {
            let text = viewModel.checkForAlgoliaTagging()
            if !text.isEmpty {
                searchViewModel.searchQuery = text
                Debouncer(delay: 0).schedule {
                    searchViewModel.notifyQueryChanged()
                }
            }
        }
    }
    
    private func handleUserSelection(username: String) {
        var words = viewModel.commentText.split(separator: " ").map(String.init)
        words.removeLast()
        words.append("@" + username)
        viewModel.commentText = words.joined(separator: " ") + " "
        viewModel.isTagging = false
    }
}
