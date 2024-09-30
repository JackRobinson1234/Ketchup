//
//  SelectFollowingEditPostView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/16/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct SelectFollowingEditPostView: View {
    var debouncer = Debouncer(delay: 1.0)
    @ObservedObject var editViewModel: ReelsEditViewModel
    @Environment(\.dismiss) var dismiss
    @State private var followingUsers: [User] = []
    @FocusState private var isSearchFieldFocused: Bool
    @StateObject var searchViewModel = SearchViewModel(initialSearchConfig: .users)
    @EnvironmentObject var tabBarController: TabBarController

    var body: some View {
        VStack {
            TextField("Search users...", text: $searchViewModel.searchQuery)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .focused($isSearchFieldFocused)

            if searchViewModel.searchQuery.isEmpty {
                List {
                    ForEach(editViewModel.taggedUsers) { postUser in
                        HStack {
                            UserCell(user: User(id: postUser.id, username: postUser.username, fullname: postUser.fullname, profileImageUrl: postUser.profileImageUrl, privateMode: postUser.privateMode))
                                .padding(.horizontal)
                            Spacer()
                            Button(action: {
                                untagUser(postUser)
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            } else {
                if !filteredUsers.isEmpty {
                    List {
                        ForEach(filteredUsers.prefix(10), id: \.id) { user in
                            Button(action: {
                                tagUser(user)
                            }) {
                                HStack {
                                    UserCell(user: user)
                                        .padding(.horizontal)
                                    Spacer()
                                    if editViewModel.taggedUsers.contains(where: { $0.id == user.id }) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    InfiniteList(searchViewModel.userHits, itemView: { hit in
                        Button {
                            tagUser(hit.object)
                        } label: {
                            UserCell(user: hit.object)
                                .padding()
                            Spacer()
                            if editViewModel.taggedUsers.contains(where: { $0.id == hit.object.id }) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Divider()
                    }, noResults: {
                        Text("No results found")
                            .foregroundStyle(.black)
                    })
                }
            }
        }
        .navigationTitle("Tag Users")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
        })
    
        .onAppear(perform: fetchFollowingUsers)
        .onChange(of: searchViewModel.searchQuery) {
            if filteredUsers.isEmpty && !searchViewModel.searchQuery.isEmpty {
                debouncer.schedule {
                    searchViewModel.notifyQueryChanged()
                }
            }
        }
    }

    private var filteredUsers: [User] {
        return followingUsers.filter { $0.username.lowercased().contains(searchViewModel.searchQuery.lowercased()) }
    }

    private func fetchFollowingUsers() {
        Task {
            do {
                let users = try await UserService.shared.fetchFollowingUsers()
                followingUsers = users
            } catch {
                print("Error fetching following users: \(error)")
            }
        }
    }

    private func tagUser(_ user: User) {
        if !editViewModel.taggedUsers.contains(where: { $0.id == user.id }) {
            let postUser = PostUser(id: user.id,
                                    fullname: user.fullname,
                                    profileImageUrl: user.profileImageUrl,
                                    privateMode: user.privateMode,
                                    username: user.username,
                                    statusNameImage: user.statusImageName)
            editViewModel.taggedUsers.append(postUser)
            print("User tagged: \(user.username)")
        } else {
            untagUser(PostUser(id: user.id,
                               fullname: user.fullname,
                               profileImageUrl: user.profileImageUrl,
                               privateMode: user.privateMode,
                               username: user.username,
                               statusNameImage: user.statusImageName))
        }
        isSearchFieldFocused = false
        searchViewModel.searchQuery = ""
    }

    private func untagUser(_ postUser: PostUser) {
        if let index = editViewModel.taggedUsers.firstIndex(where: { $0.id == postUser.id }) {
            editViewModel.taggedUsers.remove(at: index)
            print("User untagged: \(postUser.username)")
        }
    }
}

