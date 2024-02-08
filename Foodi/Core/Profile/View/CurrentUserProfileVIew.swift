//
//  CurrentUserProfileVIew.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
struct CurrentUserProfileView: View {
    private let authService: AuthService
    private let user: User
    @StateObject var profileViewModel: ProfileViewModel
    private let userService: UserService
    @State var currentProfileSection: currentProfileSection
    init(authService: AuthService, user: User, userService: UserService, currentProfileSection: currentProfileSection = .posts) {
        self.authService = authService
        self.user = user
        
        let viewModel = ProfileViewModel(user: user,
                                         userService: UserService(),
                                         postService: PostService())
        self._profileViewModel = StateObject(wrappedValue: viewModel)
        self.userService = userService
        self._currentProfileSection = State(initialValue: currentProfileSection)
    }
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 2) {
                    ProfileHeaderView(viewModel: profileViewModel)
                        .padding(.top)
                    CurrentProfileSlideBarView(viewModel: profileViewModel, userService: userService, currentProfileSection: $currentProfileSection)
                    PostGridView(viewModel: profileViewModel, userService: userService)
                    
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") {
                        authService.signout()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .task { await profileViewModel.fetchUserPosts() }
            .task { await profileViewModel.fetchUserStats() }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: User.self) { user in
                ProfileView(user: user, userService: userService)
            }
            .navigationDestination(for: SearchModelConfig.self) { config in
                SearchView(userService: UserService(), searchConfig: config)}
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    CurrentUserProfileView(authService: AuthService(),
                           user: DeveloperPreview.user, userService: UserService())
}
