//
//  ActivityContactRow.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/11/24.
//

import SwiftUI
import FirebaseAuth

struct ActivityContactRow: View {
    @ObservedObject var viewModel: ActivityViewModel
    @State var contact: Contact
    @State private var isFollowed: Bool
    @State private var isCheckingFollowStatus: Bool = false
    @State private var hasCheckedFollowStatus: Bool = false
    @State private var isShowingProfile: Bool = false
    private var isCurrentUser: Bool {
        Auth.auth().currentUser?.uid == contact.user?.id
    }
    
    init(viewModel: ActivityViewModel, contact: Contact) {
        self.viewModel = viewModel
        self._contact = State(initialValue: contact)
        self._isFollowed = State(initialValue: contact.isFollowed ?? false)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            profileImageButton
            userInfoView
            if !isCurrentUser {
                followStatusView
            }
        }
        .frame(height: 140) // Set a consistent height for the entire row
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.vertical, 8)
        .onAppear(perform: checkFollowStatus)
    }
    
    private var profileImageButton: some View {
        Button(action: { isShowingProfile = true }) {
            UserCircularProfileImageView(profileImageUrl: contact.user?.profileImageUrl, size: .medium)
                .frame(width: 60, height: 60) // Increased size for better visibility
        }
        .fullScreenCover(isPresented: $isShowingProfile) {
            if let userId = contact.user?.id {
                NavigationStack {
                    ProfileView(uid: userId)
                }
            }
        }
    }
    
    private var userInfoView: some View {
        VStack(spacing: 2) {
            Button(action: { isShowingProfile = true }) {
                Text(contact.user?.fullname ?? contact.deviceContactName ?? contact.phoneNumber)
                    .font(.custom("MuseoSansRounded-500", size: 16))
                    .foregroundStyle(.black)
                    .lineLimit(1)
            }
            
            if let username = contact.user?.username {
                Text("@\(username)")
                    .font(.system(size: 12))
                    .foregroundColor(Color("Colors/AccentColor"))
                    .lineLimit(1)
            }
        }
    }
    
    private var followStatusView: some View {
        Group {
            if isCheckingFollowStatus {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 110, height: 36) // Match the size of the follow button
            } else {
                followButton
            }
        }
    }
    
    private var followButton: some View {
        Button(action: handleFollowAction) {
            Text(isFollowed ? "Following" : "Follow")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .fontWeight(.semibold)
                .frame(width: 110, height: 36)
                .foregroundColor(isFollowed ? Color("Colors/AccentColor") : .white)
                .background(isFollowed ? Color.clear : Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("Colors/AccentColor"), lineWidth: isFollowed ? 1 : 0)
                )
        }
    }
    
    private func checkFollowStatus() {
        guard let userId = contact.user?.id, !hasCheckedFollowStatus else { return }
        
        isCheckingFollowStatus = true
        Task {
            do {
                isFollowed = try await viewModel.checkIfUserIsFollowed(contact: contact)
                isCheckingFollowStatus = false
                hasCheckedFollowStatus = true
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
                viewModel.updateContactFollowStatus(contact: contact, isFollowed: isFollowed)
            } catch {
                print("Failed to follow/unfollow: \(error.localizedDescription)")
            }
        }
    }
}
