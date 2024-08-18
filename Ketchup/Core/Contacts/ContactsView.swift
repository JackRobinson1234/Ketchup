//
//  ContactsView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/17/24.
//
import SwiftUI
import Contacts
import ContactsUI

import Contacts

struct ContactsView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.contacts.isEmpty {
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
            ForEach(filteredContacts, id: \.identifier) { contact in
                ContactRow(viewModel: viewModel, contact: contact)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return viewModel.contacts
        } else {
            return viewModel.contacts.filter { contact in
                let name = "\(contact.givenName) \(contact.familyName)"
                return name.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

struct ContactRow: View {
    @ObservedObject var viewModel: ContactsViewModel
    let contact: CNContact
    @State private var isFollowed: Bool = false
    @State private var isCheckingFollowStatus: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(contact.givenName + " " + contact.familyName)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            if let user = viewModel.firebaseUsers[contact.identifier] {
                if isCheckingFollowStatus {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    followButton(for: user)
                }
            } else {
                inviteButton
            }
        }
        .padding(.vertical, 8)
        .onAppear(perform: checkFollowStatus)
    }
    
    private func followButton(for user: User) -> some View {
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
        guard let user = viewModel.firebaseUsers[contact.identifier] else { return }
        isCheckingFollowStatus = true
        Task {
            do {
                isFollowed = try await viewModel.checkIfUserIsFollowed(userId: user.id)
                isCheckingFollowStatus = false
            } catch {
                print("Error checking follow status: \(error.localizedDescription)")
                isCheckingFollowStatus = false
            }
        }
    }
    
    private func handleFollowAction() {
        guard let user = viewModel.firebaseUsers[contact.identifier] else { return }
        Task {
            do {
                if isFollowed {
                    try await viewModel.unfollow(userId: user.id)
                } else {
                    try await viewModel.follow(userId: user.id)
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
