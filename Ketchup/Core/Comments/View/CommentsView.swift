import SwiftUI
import InstantSearchSwiftUI

struct CommentsView: View {
    @StateObject var viewModel: CommentViewModel
    @StateObject var searchViewModel = SearchViewModel(initialSearchConfig: .users)
    let debouncer = Debouncer(delay: 1.0)

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
                            Text("Mention Users")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .fontWeight(.bold)
                                .padding(.top, 10)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if !viewModel.filteredTaggedUsers.isEmpty{
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
                                InfiniteList(searchViewModel.userHits, itemView: { hit in
                                    Button{
                                        let username = hit.object.username
                                        var words = viewModel.commentText.split(separator: " ").map(String.init)
                                        words.removeLast()
                                        words.append("@" + username)
                                        viewModel.commentText = words.joined(separator: " ") + " "
                                        viewModel.isTagging = false
                                    } label: {
                                        UserCell(user: hit.object)
                                            .padding()
                                      
                                    }
                        
                                    Divider()
                                }, noResults: {
                                    Text("No results found")
                                        .foregroundStyle(.primary)
                                })
                                
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
            .onChange(of: viewModel.commentText){
                if viewModel.filteredTaggedUsers.isEmpty{
                    print("Entering 1")
                    let text = viewModel.checkForAlgoliaTagging()
                    if !text.isEmpty{
                        print("Entering 2")
                        searchViewModel.searchQuery = text
                        print(text)
                        Debouncer(delay: 0).schedule{
                            print("Entering 3")
                            searchViewModel.notifyQueryChanged()
                        }
                    }
                }
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
            .listStyle(PlainListStyle())
        }
    }
}
