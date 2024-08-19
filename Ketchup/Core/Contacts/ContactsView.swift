//
//  ContactsView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/17/24.
//
import SwiftUI
import Contacts
import ContactsUI


struct ContactsView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.contacts.isEmpty && !viewModel.isLoading {
                    emptyView
                } else {
                    contactsList
                }
            }
            .navigationTitle("Contacts on App")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search contacts")
            .onAppear {
                if viewModel.contacts.isEmpty {
                    viewModel.fetchContacts()
                }
            }
            .alert(item: Binding<AlertItem?>(
                get: { viewModel.error.map { AlertItem(error: $0) } },
                set: { _ in viewModel.error = nil }
            )) { alertItem in
                Alert(title: Text("Error"), message: Text(alertItem.error.localizedDescription))
            }
        }
    }
    
    private var emptyView: some View {
        VStack {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text("No Contacts Found on App")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top)
            Text("Invite your contacts to join the app!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 4)
        }
    }
    
    private var contactsList: some View {
        List {
            ForEach(filteredContacts) { contact in
                ContactRow(viewModel: viewModel, contact: contact)
            }
            if viewModel.hasMoreContacts {
                ProgressView()
                    .onAppear {
                        viewModel.fetchContacts()
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredContacts: [MergedContact] {
        if searchText.isEmpty {
            return viewModel.contacts
        } else {
            return viewModel.contacts.filter { contact in
                contact.displayName.lowercased().contains(searchText.lowercased()) ||
                contact.phoneNumber.contains(searchText)
            }
        }
    }
}

struct ContactRow: View {
    @ObservedObject var viewModel: ContactsViewModel
    let contact: MergedContact
    @State private var isFollowed: Bool = false
    @State private var isCheckingFollowStatus: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(contact.displayName)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            if contact.hasExistingAccount {
                if isCheckingFollowStatus {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    followButton
                }
            } else {
                inviteButton
            }
        }
        .padding(.vertical, 8)
        .onAppear(perform: checkFollowStatus)
    }
    
    private var followButton: some View {
        Button(action: handleFollowAction) {
            Text(isFollowed ? "Following" : "Follow")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isFollowed ? .blue : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isFollowed ? Color.clear : Color.blue)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.blue, lineWidth: isFollowed ? 1 : 0)
                )
        }
    }
    
    private var inviteButton: some View {
        Button(action: { viewModel.inviteContact(contact) }) {
            Text("Invite")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.blue, lineWidth: 1)
                )
        }
    }
    
    private func checkFollowStatus() {
        guard let userId = contact.user?.id else { return }
        isCheckingFollowStatus = true
        Task {
            do {
                isFollowed = try await viewModel.checkIfUserIsFollowed(userId: userId)
                isCheckingFollowStatus = false
            } catch {
                print("Error checking follow status: \(error.localizedDescription)")
                isCheckingFollowStatus = false
            }
        }
    }
    
    private func handleFollowAction() {
        guard let userId = contact.user?.id else { return }
        Task {
            do {
                if isFollowed {
                    try await viewModel.unfollow(userId: userId)
                } else {
                    try await viewModel.follow(userId: userId)
                }
                isFollowed.toggle()
            } catch {
                print("Failed to follow/unfollow: \(error.localizedDescription)")
            }
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let error: Error
}
