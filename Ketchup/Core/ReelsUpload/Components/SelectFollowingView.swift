//
//  SelectFollowingView.swift
//  Ketchup
//
//  Created by Joe Ciminelli on 7/12/24.
//
import SwiftUI

struct SelectFollowingView: View {
    @ObservedObject var uploadViewModel: UploadViewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    @State private var followingUsers: [User] = []
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack {
            TextField("Search users...", text: $searchText)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .focused($isSearchFieldFocused)

            if searchText.isEmpty {
                List {
                    ForEach(Array(uploadViewModel.taggedUsers), id: \.self) { postUser in
                        if let user = followingUsers.first(where: { $0.username == postUser.username }) {
                            HStack {
                                UserCell(user: user)
                                    .padding(.horizontal)
                                Spacer()
                                Button(action: {
                                    tagUser(user)
                                }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            } else {
                List {
                    ForEach(filteredUsers.prefix(10), id: \.id) { user in
                        Button(action: {
                            tagUser(user)
                        }) {
                            HStack {
                                UserCell(user: user)
                                    .padding(.horizontal)
                                Spacer()
                                if uploadViewModel.taggedUsers.contains(where: { $0.id == user.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear(perform: fetchFollowingUsers)
        .navigationTitle("Tag Users")
    }

    private var filteredUsers: [User] {
        return followingUsers.filter { $0.username.lowercased().contains(searchText.lowercased()) }
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
        if let index = uploadViewModel.taggedUsers.firstIndex(where: { $0.username == user.username }) {
            uploadViewModel.taggedUsers.remove(at: index) // Un-tag user if already tagged
        } else {
            uploadViewModel.taggedUsers.append(PostUser(id: user.id,
                                                        fullname: user.fullname,
                                                        profileImageUrl: user.profileImageUrl,
                                                        privateMode: user.privateMode,
                                                        username: user.username))
        }
        isSearchFieldFocused = false
        searchText = ""
    }
}

//struct SelectFollowingWrittenView: View {
//    @ObservedObject var reviewViewModel: ReviewsViewModel
//    @Environment(\.dismiss) var dismiss
//    @State private var searchText: String = ""
//    @State private var followingUsers: [User] = []
//    @FocusState private var isSearchFieldFocused: Bool
//
//    var body: some View {
//        VStack {
//            TextField("Search users...", text: $searchText)
//                .padding()
//                .background(Color(.systemGray6))
//                .cornerRadius(8)
//                .padding(.horizontal)
//                .focused($isSearchFieldFocused)
//
//            if searchText.isEmpty {
//                List {
//                    ForEach(Array(reviewViewModel.taggedUsers.keys), id: \.self) { username in
//                        if let user = followingUsers.first(where: { $0.username == username }) {
//                            HStack {
//                                UserCell(user: user)
//                                    .padding(.horizontal)
//                                Spacer()
//                                Button(action: {
//                                    tagUser(user)
//                                }) {
//                                    Image(systemName: "minus.circle")
//                                        .foregroundColor(.red)
//                                }
//                            }
//                        }
//                    }
//                }
//            } else {
//                List {
//                    ForEach(filteredUsers.prefix(10), id: \.id) { user in
//                        Button(action: {
//                            tagUser(user)
//                        }) {
//                            HStack {
//                                UserCell(user: user)
//                                    .padding(.horizontal)
//                                Spacer()
//                                if reviewViewModel.taggedUsers[user.username] != nil {
//                                    Image(systemName: "checkmark")
//                                        .foregroundColor(.blue)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        .onAppear(perform: fetchFollowingUsers)
//        .navigationTitle("Tag Users")
//    }
//
//    private var filteredUsers: [User] {
//        return followingUsers.filter { $0.username.lowercased().contains(searchText.lowercased()) }
//    }
//
//    private func fetchFollowingUsers() {
//        Task {
//            do {
//                let users = try await UserService.shared.fetchFollowingUsers()
//                followingUsers = users
//            } catch {
//                print("Error fetching following users: \(error)")
//            }
//        }
//    }
//
//    private func tagUser(_ user: User) {
//        if reviewViewModel.taggedUsers[user.username] != nil {
//            reviewViewModel.taggedUsers.removeValue(forKey: user.username)
//        } else {
//            reviewViewModel.taggedUsers[user.username] = user.id
//        }
//        isSearchFieldFocused = false
//        searchText = ""
//    }
//}




