//
//  CollectionInviteUserList.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/28/24.
//

import Foundation
import SwiftUI
import InstantSearchSwiftUI
struct CollectionInviteUserList: View {
    var debouncer = Debouncer(delay: 1.0)
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var followingUsers: [User] = []
    @FocusState private var isSearchFieldFocused: Bool
    @StateObject var searchViewModel = SearchViewModel(initialSearchConfig: .users)

    var body: some View {
        VStack {
            TextField("Search users...", text: $searchViewModel.searchQuery)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .focused($isSearchFieldFocused)

            InfiniteList(searchViewModel.userHits, itemView: { hit in
                Button {
                    inviteUser(hit.object)
                } label: {
                    UserCell(user: hit.object)
                        .padding()
                    Spacer()
                    if collectionsViewModel.selectedCollection?.pendingInvitations.contains(hit.object.id) == true {
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
        .navigationTitle("Invite Users")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
        })
        .onAppear(perform: fetchFollowingUsers)
        .onChange(of: searchViewModel.searchQuery) {
            debouncer.schedule {
                searchViewModel.notifyQueryChanged()
            }
        }
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

    private func inviteUser(_ user: User) {
        Task {
            do {
                try await collectionsViewModel.inviteUserToCollection(inviteeUid: user.id)
                // Optionally: Provide feedback to the user about the invite being sent
            } catch {
                print("Failed to send invite: \(error)")
            }
        }
    }
}
