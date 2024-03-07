//
//  CurrentUserProfileVIew.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
struct CurrentUserProfileView: View {
    private let authService: AuthService
    @StateObject var profileViewModel: ProfileViewModel
    
    private let userService: UserService
    @State var currentProfileSection: currentProfileSection
    @State var isLoading = true
    @State var showNotifications = false
    init(authService: AuthService, userService: UserService, currentProfileSection: currentProfileSection = .posts) {
        self.authService = authService
        
        let viewModel = ProfileViewModel(uid: "",
                                         userService: UserService(),
                                         postService: PostService())
        self._profileViewModel = StateObject(wrappedValue: viewModel)
        self.userService = userService
        self._currentProfileSection = State(initialValue: currentProfileSection)
        
    }
    
    
    var body: some View {
        if isLoading {
            // Loading screen
            ProgressView("Loading...")
                .onAppear {
                    Task {
                        await profileViewModel.fetchCurrentUser()
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
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showNotifications.toggle()
                        } label : {
                            Image(systemName: "bell")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                    }
                }
                
                
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: User.self) { user in
                    ProfileView(uid: user.id, userService: userService)
                }
                .navigationDestination(for: SearchModelConfig.self) { config in
                    SearchView(userService: UserService(), searchConfig: config)}
                .navigationBarBackButtonHidden(true)
                .refreshable { await profileViewModel.fetchCurrentUser() }
                .fullScreenCover(isPresented: $showNotifications) {
                    NotificationsView(userService: userService)
                }
            }
        }
    }
}




#Preview {
    CurrentUserProfileView(authService: AuthService(), userService: UserService())
}
