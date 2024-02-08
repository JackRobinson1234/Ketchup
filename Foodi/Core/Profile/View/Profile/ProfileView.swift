//
//  ProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct ProfileView: View {
        @StateObject var viewModel: ProfileViewModel
        @Environment(\.dismiss) var dismiss
        
        private var user: User {
            return viewModel.user
        }
        private let userService: UserService
        
        init(user: User, userService: UserService) {
            
            let profileViewModel = ProfileViewModel(user: user,
                                                    userService: UserService(),
                                                    postService: PostService())
            self._viewModel = StateObject(wrappedValue: profileViewModel)
            self.userService = userService
        }
        
        var body: some View {
            
                ScrollView {
                    VStack(spacing: 2) {
                        ProfileHeaderView(viewModel: viewModel)
                        PostGridView(viewModel: viewModel, userService: UserService())
                    }
                }
            .task { await viewModel.fetchUserPosts() }
            .task { await viewModel.checkIfUserIsFollowed() }
            .task { await viewModel.fetchUserStats() }
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
