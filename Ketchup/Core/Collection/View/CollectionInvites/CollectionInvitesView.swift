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
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.invites) { invite in
                                CollaborationInviteCell(invite: invite, viewModel: viewModel)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
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
    @State private var showCollection: Bool = false
    @State private var showRejectAlert: Bool = false

    var body: some View {
        VStack{
        HStack {
            // Reuse the CollectionListCell UI for displaying the invite
            Button {
                Task {
                    viewModel.selectedCollection = try await CollectionService.shared.fetchCollection(withId: invite.collectionId)
                    showCollection = true
                }
            } label: {
                CollectionListCell(
                    collection: Collection(
                        id: invite.collectionId,
                        name: invite.collectionName,
                        timestamp: invite.timestamp,
                        description: "",
                        username: invite.inviterUsername,
                        fullname: "",
                        uid: "",
                        coverImageUrl: invite.collectionCoverImageUrl,
                        restaurantCount: 0,
                        privateMode: false,
                        profileImageUrl: invite.inviterProfileImageUrl,
                        tempImageUrls: invite.tempImageUrls,
                        likes: 0,
                        collaborators: [],
                        pendingInvitations: []
                    ),
                    collectionsViewModel: viewModel, showChevron: false
                )
            }
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
                showRejectAlert = true
            }) {
                Image(systemName: "x.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.red)
            }
        }
        .padding(.trailing)
        .fullScreenCover(isPresented: $showCollection) {
            CollectionView(collectionsViewModel: viewModel)
        }
        .alert("Reject Invitation", isPresented: $showRejectAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reject", role: .destructive) {
                Task {
                    await viewModel.rejectInvite(invite)
                }
            }
        } message: {
            Text("Are you sure you want to reject the invitation to collaborate on '\(invite.collectionName)'? This action cannot be undone.")
        }
        Divider()
    }
    }
}


