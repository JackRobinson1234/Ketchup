//
//  CurrentUserProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
struct CurrentUserProfileView: View {
    @StateObject var profileViewModel: ProfileViewModel
    @State var currentProfileSection: ProfileSectionEnum
    @State var isLoading = true
    @State var showNotifications = false
    @State var showSettings = false
    init(currentProfileSection: ProfileSectionEnum = .posts) {
        let viewModel = ProfileViewModel(uid: "")
        self._profileViewModel = StateObject(wrappedValue: viewModel)
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
                        ProfileSlideBar(viewModel: profileViewModel, profileSection: $currentProfileSection)
                        
                        
                    }
                }
                
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button{
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(.black)
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
                
                
                .navigationTitle(Text("@\(profileViewModel.user.username)"))
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: User.self) { user in
                    ProfileView(uid: user.id)
                }
                .navigationDestination(for: SearchModelConfig.self) { config in
                    SearchView(searchConfig: config)}
                .navigationBarBackButtonHidden(true)
                .refreshable { Task {try await profileViewModel.refreshCurrentUser() }}
                .sheet(isPresented: $showNotifications) {
                    NotificationsView()
                }
                .fullScreenCover(isPresented: $showSettings){
                    SettingsView(profileViewModel: profileViewModel)
                }
                .navigationDestination(for: FavoriteRestaurant.self) { restaurant in
                    RestaurantProfileView(restaurantId: restaurant.id)
                }
                .onChange(of: AuthService.shared.userSession) {
                    if AuthService.shared.userSession != nil {
                        Task {try await profileViewModel.refreshCurrentUser() }
                    }
                }
            }
        }
    }
}




#Preview {
    CurrentUserProfileView()
}
