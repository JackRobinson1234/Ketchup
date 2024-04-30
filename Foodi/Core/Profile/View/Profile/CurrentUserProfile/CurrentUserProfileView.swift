//
//  CurrentUserProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
struct CurrentUserProfileView: View {
    private let authService: AuthService
    @StateObject var profileViewModel: ProfileViewModel
    
    private let userService: UserService
    @State var currentProfileSection: ProfileSectionEnum
    @State var isLoading = true
    @State var showNotifications = false
    @State var showSettings = false
    init(authService: AuthService, userService: UserService, currentProfileSection: ProfileSectionEnum = .posts) {
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
                        //MARK: Profile Header
                        ProfileHeaderView(viewModel: profileViewModel)
                            .padding(.top)
                            //MARK: Slide bar
                        ProfileSlideBar(viewModel: profileViewModel, userService: userService, profileSection: $currentProfileSection)
                        
                        
                    }
                }
                
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button{
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape")
                        }
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
                .sheet(isPresented: $showNotifications) {
                    NotificationsView(userService: userService)
                }
                .fullScreenCover(isPresented: $showSettings){
                    SettingsView(userService: userService, authService: authService, user: profileViewModel.user)
                }
            }
        }
    }
}




#Preview {
    CurrentUserProfileView(authService: AuthService(), userService: UserService())
}
