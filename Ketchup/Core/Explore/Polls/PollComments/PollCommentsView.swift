//
//  PollCommentsView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/28/24.
//

import SwiftUI
import InstantSearchSwiftUI

//struct PollCommentsView: View {
//    @StateObject var viewModel: PollCommentViewModel
//    @StateObject var searchViewModel = SearchViewModel(initialSearchConfig: .users)
//    @FocusState private var isInputFocused: Bool
//    
//    init(poll: Binding<Poll>) {
//        let viewModel = PollCommentViewModel(poll: poll)
//        self._viewModel = StateObject(wrappedValue: viewModel)
//    }
//    
//    var body: some View {
//        NavigationStack {
//            VStack {
//                if !viewModel.organizedComments.isEmpty && !viewModel.isTagging {
//                    Text(viewModel.commentCountText)
//                        .font(.custom("MuseoSansRounded-300", size: 16))
//                        .fontWeight(.semibold)
//                        .padding(.top, 24)
//                }
//                ScrollViewReader { scrollViewProxy in
//                    ScrollView {
//                        Divider()
//                        VStack(spacing: 24) {
//                            if viewModel.isTagging {
//                                taggedUsersView
//                            } else {
//                                ForEach(viewModel.organizedComments, id: \.comment.id) { commentWithReplies in
//                                    PollCommentCell(comment: commentWithReplies.comment, replies: commentWithReplies.replies, viewModel: viewModel, isReply: false)
//                                        .id(commentWithReplies.comment.id)
//                                }
//                            }
//                        }
//                    }
//                    .onChange(of: viewModel.lastAddedCommentId) { commentId in
//                        if let commentId = commentId {
//                            scrollViewProxy.scrollTo(commentId, anchor: .center)
//                        }
//                    }
//                    .onAppear {
//                        Task {
//                            try await viewModel.fetchComments()
//                        }
//                    }
//                }
//                Divider()
//                    .padding(.bottom)
//                
//                HStack(spacing: 12) {
//                    UserCircularProfileImageView(profileImageUrl: AuthService.shared.userSession?.profileImageUrl, size: .xSmall)
//                    CommentInputView(viewModel: viewModel, isInputFocused: _isInputFocused)
//                }
//                .padding(.horizontal)
//                .padding(.bottom)
//            }
//            .onChange(of: viewModel.commentText) { newValue in
//                handleCommentTextChange()
//            }
//            .onAppear {
//                viewModel.fetchFollowingUsers()
//            }
//            .overlay {
//                if viewModel.showEmptyView && !viewModel.isTagging {
//                    EmptyStateView(
//                        message: "No comments yet. Add yours now!",
//                        systemImage: "exclamationmark.bubble"
//                    )
//                    .foregroundStyle(.gray)
//                }
//            }
//            .onChange(of: viewModel.organizedComments.count) { newValue in
//                viewModel.showEmptyView = viewModel.organizedComments.isEmpty
//            }
//            .fullScreenCover(item: $viewModel.selectedUserComment) { comment in
//                NavigationStack {
//                    if let user = viewModel.selectedUserComment?.commentOwnerUid {
//                        ProfileView(uid: user)
//                    }
//                }
//            }
//            .onChange(of: viewModel.shouldFocusTextField) { newValue in
//                isInputFocused = newValue
//            }
//            .listStyle(PlainListStyle())
//        }
//    }
//    
//    private var taggedUsersView: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text("Mention Users")
//                .font(.custom("MuseoSansRounded-300", size: 16))
//                .fontWeight(.bold)
//                .padding(.top, 10)
//                .padding(.horizontal)
//            
//            if !viewModel.filteredTaggedUsers.isEmpty {
//                ForEach(viewModel.filteredTaggedUsers, id: \.id) { user in
//                    Button(action: {
//                        handleUserSelection(username: user.username)
//                    }) {
//                        UserCell(user: user)
//                            .padding(.horizontal)
//                    }
//                    .contentShape(Rectangle())
//                }
//            } else {
//                InfiniteList(searchViewModel.userHits, itemView: { hit in
//                    Button {
//                        handleUserSelection(username: hit.object.username)
//                    } label: {
//                        UserCell(user: hit.object)
//                            .padding()
//                    }
//                    Divider()
//                }, noResults: {
//                    Text("No results found")
//                        .foregroundStyle(.black)
//                })
//            }
//        }
//    }
//    
//    private func handleCommentTextChange() {
//        if viewModel.filteredTaggedUsers.isEmpty {
//            let text = viewModel.checkForTagging()
//            if !text.isEmpty {
//                searchViewModel.searchQuery = text
//                Debouncer(delay: 0).schedule {
//                    searchViewModel.notifyQueryChanged()
//                }
//            }
//        }
//    }
//    
//    private func handleUserSelection(username: String) {
//        var words = viewModel.commentText.split(separator: " ").map(String.init)
//        words.removeLast()
//        words.append("@" + username)
//        viewModel.commentText = words.joined(separator: " ") + " "
//        viewModel.isTagging = false
//    }
//}
