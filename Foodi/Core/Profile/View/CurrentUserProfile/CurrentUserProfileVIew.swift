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
    @State var isLoading = true
    init(authService: AuthService, user: User, userService: UserService, currentProfileSection: currentProfileSection = .posts) {
        self.authService = authService
        self.user = user
        let viewModel = ProfileViewModel(uid: user.id,
                                         userService: UserService(),
                                         postService: PostService())
        self._profileViewModel = StateObject(wrappedValue: viewModel)
        self.userService = userService
        self._currentProfileSection = State(initialValue: currentProfileSection)
        print(user)
    }
    
    
    var body: some View {
        if isLoading {
            // Loading screen
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        await profileViewModel.fetchUser()
                        isLoading = false
                    }
                }
        } else{
            NavigationStack {
                ScrollView {
                    VStack(spacing: 2) {
                        
                        ProfileHeaderView(viewModel: profileViewModel)
                            .padding(.top)
                        CurrentProfileSlideBarView(viewModel: profileViewModel, userService: userService, currentProfileSection: $currentProfileSection)
                        
                        
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
                
                .task { await profileViewModel.fetchUserStats() }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: User.self) { user in
                    ProfileView(uid: user.id, userService: userService)
                }
                .navigationDestination(for: SearchModelConfig.self) { config in
                    SearchView(userService: UserService(), searchConfig: config)}
                .navigationBarBackButtonHidden(true)
            }
        }
    }
}




#Preview {
    CurrentUserProfileView(authService: AuthService(),
                           user: DeveloperPreview.user, userService: UserService())
}
