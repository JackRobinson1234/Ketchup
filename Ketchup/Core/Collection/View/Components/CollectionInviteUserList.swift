//
//  CollectionInviteUserList.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/28/24.
//

import Foundation
import SwiftUI
import InstantSearchSwiftUI
import FirebaseAuth
struct CollectionInviteUserList: View {
    var debouncer = Debouncer(delay: 1.0)
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var followingUsers: [User] = []
    @FocusState private var isSearchFieldFocused: Bool
    @StateObject var searchViewModel = SearchViewModel(initialSearchConfig: .users)
    
    @State private var showConfirmationAlert = false
    @State private var showSuccessAlert = false
    @State private var selectedUser: User?

    var body: some View {
        NavigationStack{
            VStack {
                TextField("Search users...", text: $searchViewModel.searchQuery)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .focused($isSearchFieldFocused)
                
                InfiniteList(searchViewModel.userHits, itemView: { hit in
                    HStack {
                        UserCell(user: hit.object)
                            .padding()
                        Spacer()
                        userStatus(for: hit.object)
                    }
                    .padding(.trailing)
                    //.background(userRowBackground(for: hit.object))
                    .onTapGesture {
                        handleUserTap(hit.object)
                    }
                    Divider()
                }, noResults: {
                    Text("No results found")
                        .foregroundStyle(.black)
                })
            }
            .navigationTitle("Invite Users")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
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
            .alert("Confirm Invitation", isPresented: $showConfirmationAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Invite") {
                    if let user = selectedUser {
                        inviteUser(user)
                    }
                }
            } message: {
                Text("Do you want to invite \(selectedUser?.fullname ?? "") to collaborate on this collection?")
            }
            .alert("Invitation Sent", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("An invitation has been sent to \(selectedUser?.fullname ?? "").")
            }
        }
    }

    private func userStatus(for user: User) -> some View {
        if collectionsViewModel.selectedCollection?.collaborators.contains(user.id) == true {
            return Text("Collaborator")
                .foregroundColor(.black)
                .font(.custom("MuseoSansRounded-700", size: 14))
        } else if collectionsViewModel.selectedCollection?.pendingInvitations.contains(user.id) == true {
            return Text("Invited")
                .foregroundColor(.black)
          
                .font(.custom("MuseoSansRounded-700", size: 14))
        } else {
            return Text("Invite")
                .foregroundColor(Color("Colors/AccentColor"))
                .font(.custom("MuseoSansRounded-300", size: 14))
                
        }
    }

    private func userRowBackground(for user: User) -> Color {
        if collectionsViewModel.selectedCollection?.collaborators.contains(user.id) == true ||
           collectionsViewModel.selectedCollection?.pendingInvitations.contains(user.id) == true {
            return Color(.systemGray6)
        } else {
            return Color.white
        }
    }

    private func handleUserTap(_ user: User) {
        if collectionsViewModel.selectedCollection?.collaborators.contains(user.id) == true ||
           collectionsViewModel.selectedCollection?.pendingInvitations.contains(user.id) == true ||
            user.id == Auth.auth().currentUser?.uid
        {
            // Do nothing if the user is already a collaborator or invited
            return
        }
        selectedUser = user
        showConfirmationAlert = true
    }

    private func fetchFollowingUsers() {
        Task {
            do {
                let users = try await UserService.shared.fetchFollowingUsers()
                followingUsers = users
            } catch {
                //print("Error fetching following users: \(error)")
            }
        }
    }

    private func inviteUser(_ user: User) {
        Task {
            do {
                try await collectionsViewModel.inviteUserToCollection(inviteeUid: user.id)
                showSuccessAlert = true
            } catch {
                //print("Failed to send invite: \(error)")
                // Optionally: Show an error alert here
            }
        }
    }
}
