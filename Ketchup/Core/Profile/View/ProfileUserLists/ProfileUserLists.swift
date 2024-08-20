//
//  ProfileUserLists.swift
//  Foodi
//
//  Created by Jack Robinson on 4/22/24.
//

import SwiftUI
import FirebaseAuth

struct ProfileUserLists: View {
    @StateObject var viewModel: ProfileUserListViewModel
    @State private var searchText = ""
    private let config: UserListConfig
    
    init(config: UserListConfig) {
        self.config = config
        self._viewModel = StateObject(wrappedValue: ProfileUserListViewModel(config: config))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.users.isEmpty && !viewModel.isLoading {
                    emptyView
                } else {
                    userList
                }
            }
            .navigationTitle(config.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search users")
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
            Image("Skip")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            Text("No Users Found")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top)
        }
    }
    
    private var userList: some View {
        List {
            ForEach(filteredUsers) { user in
                UserRow(viewModel: viewModel, user: user)
            }
            
            if viewModel.hasMoreUsers {
                ProgressView()
                    .onAppear {
                        viewModel.fetchUsers()
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.users
        } else {
            return viewModel.users.filter { user in
                user.username.lowercased().contains(searchText.lowercased()) ||
                user.fullname.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

struct UserRow: View {
    @ObservedObject var viewModel: ProfileUserListViewModel
    @State var user: User
    @State private var isFollowed: Bool
    @State private var isCheckingFollowStatus: Bool = false
    @State private var hasCheckedFollowStatus: Bool = false
    @State private var isShowingProfile: Bool = false

    init(viewModel: ProfileUserListViewModel, user: User) {
        self.viewModel = viewModel
        self._user = State(initialValue: user)
        self._isFollowed = State(initialValue: user.isFollowed ?? false)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: ProfileView(uid: user.id)) {
                HStack {
                    UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .small)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.fullname)
                            .font(.custom("MuseoSansRounded-500", size: 16))
                            .foregroundStyle(.black)
                        
                        Text("@\(user.username)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        locationText
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            if isCheckingFollowStatus {
                ProgressView()
                    .scaleEffect(0.7)
            } else if user.id != Auth.auth().currentUser?.uid {
                followButton
            }
        }
        .padding(.vertical, 8)
        .onAppear(perform: checkFollowStatus)
    }
    
    private var locationText: some View {
        Text(locationString)
            .font(.system(size: 12))
            .foregroundColor(.gray)
    }
    
    private var locationString: String {
        if let city = user.location?.city, let state = user.location?.state {
            return "\(city), \(state)"
        } else if let city = user.location?.city {
            return city
        } else if let state = user.location?.state {
            return state
        } else {
            return "Location not available"
        }
    }
    
    private func checkFollowStatus() {
        guard !hasCheckedFollowStatus else { return }
        
        isCheckingFollowStatus = true
        Task {
            do {
                isFollowed = try await viewModel.checkIfUserIsFollowed(user: user)
                isCheckingFollowStatus = false
                hasCheckedFollowStatus = true
            } catch {
                print("Error checking follow status: \(error.localizedDescription)")
                isCheckingFollowStatus = false
            }
        }
    }
    
    private func handleFollowAction() {
        Task {
            do {
                if isFollowed {
                    try await viewModel.unfollow(userId: user.id)
                } else {
                    try await viewModel.follow(userId: user.id)
                }
                isFollowed.toggle()
                viewModel.updateUserFollowStatus(user: user, isFollowed: isFollowed)
            } catch {
                print("Failed to follow/unfollow: \(error.localizedDescription)")
            }
        }
    }
    
    private var followButton: some View {
        Button(action: handleFollowAction) {
            Text(isFollowed ? "Following" : "Follow")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .fontWeight(.semibold)
                .frame(width: 110)
                .padding(.vertical, 8)
                .foregroundColor(isFollowed ? Color("Colors/AccentColor") : .white)
                .background(isFollowed ? Color.clear : Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("Colors/AccentColor"), lineWidth: isFollowed ? 1 : 0)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())  // Ensures only the button area is tappable
    }
}
