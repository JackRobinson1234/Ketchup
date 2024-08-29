//
//  CollectionInvitesView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/29/24.
//

import SwiftUI

struct CollaborationInvitesView: View {
    @ObservedObject var viewModel: CollectionsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading Invites...")
                        .padding()
                } else if viewModel.invites.isEmpty {
                    Text("You don't have any collaboration invites.")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .padding()
                } else {
                    List(viewModel.invites) { invite in
                        CollaborationInviteCell(invite: invite, viewModel: viewModel)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Collaboration Invites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchCollaborationInvites()
                }
            }
        }
    }
}

struct CollaborationInviteCell: View {
    let invite: CollectionInvite
    @ObservedObject var viewModel: CollectionsViewModel
    
    var body: some View {
        HStack {
            // Reuse the CollectionListCell UI for displaying the invite
            CollectionListCell(
                collection: Collection(
                    id: invite.collectionId,
                    name: invite.collectionName,
                    uid: invite.inviterUid,
                    username: invite.inviterUsername,
                    fullname: "", // You can include the full name if available
                    timestamp: invite.timestamp,
                    coverImageUrl: invite.collectionCoverImageUrl,
                    restaurantCount: 0, // Assuming you want to show a placeholder value here
                    privateMode: false,
                    profileImageUrl: invite.inviterProfileImageUrl,
                    tempImageUrls: invite.tempImageUrls ?? [],
                    likes: 0, // Placeholder for likes count
                    collaborators: [],
                    pendingInvitations: []
                ),
                collectionsViewModel: viewModel
            )
            
            Spacer()
            
            // Accept Button
            Button(action: {
                Task {
                    await viewModel.acceptInvite(invite)
                }
            }) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.green)
            }
            .padding(.trailing, 8)
            
            // Reject Button
            Button(action: {
                Task {
                    await viewModel.rejectInvite(invite)
                }
            }) {
                Image(systemName: "x.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}


