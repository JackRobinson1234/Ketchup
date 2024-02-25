//
//  ProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct ProfileView: View {
    @StateObject var likesViewModel: LikedVideosViewModel
    @StateObject var profileViewModel: ProfileViewModel

    @Environment(\.dismiss) var dismiss
    private var user: User {
        return profileViewModel.user
    }
    private let userService: UserService
    @State var profileSection: ProfileSectionEnum


    init(user: User, userService: UserService, profileSection: ProfileSectionEnum = .posts) {
        let profileViewModel = ProfileViewModel(user: user, userService: UserService(), postService: PostService())
        self._profileViewModel = StateObject(wrappedValue: profileViewModel)
        self.userService = userService
        let likesViewModel = LikedVideosViewModel(user: user,
                                                  userService: UserService(),
                                                  postService: PostService())
        self._likesViewModel = StateObject(wrappedValue: likesViewModel)
        self._profileSection = State(initialValue: profileSection)
        
    }
    
    var body: some View {
            ScrollView {
                VStack(spacing: 2) {
                    ProfileHeaderView(viewModel: profileViewModel)
                    ProfileSlideBar(viewModel: profileViewModel, userService: userService, profileSection: $profileSection, likesViewModel: likesViewModel)
                }
            }
        .task { await profileViewModel.fetchUserPosts() }
        .task { await profileViewModel.checkIfUserIsFollowed() }
        .task { await profileViewModel.fetchUserStats() }
        .navigationTitle(user.username)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
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
        .navigationBarBackButtonHidden()
        
    }
}

#Preview {
    ProfileView(user: DeveloperPreview.user, userService: UserService())
}
