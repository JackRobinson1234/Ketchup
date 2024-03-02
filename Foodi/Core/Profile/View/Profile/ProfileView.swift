//
//  ProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct ProfileView: View {
    //@StateObject var likesViewModel: LikedVideosViewModel
    @StateObject var profileViewModel: ProfileViewModel
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    /*private var user: User {
        return profileViewModel.user
    }*/
    private let userService: UserService
    @State var profileSection: ProfileSectionEnum
    private let uid: String


    init(uid: String, userService: UserService, profileSection: ProfileSectionEnum = .posts) {
        self.uid = uid
        let profileViewModel = ProfileViewModel(uid: uid, userService: UserService(), postService: PostService())
        self._profileViewModel = StateObject(wrappedValue: profileViewModel)
        self.userService = userService
        /*let likesViewModel = LikedVideosViewModel(uid: uid,
                                                  userService: UserService(),
                                                  postService: PostService())*/
        //self._likesViewModel = StateObject(wrappedValue: likesViewModel)
        self._profileSection = State(initialValue: profileSection)
        
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
            ScrollView {
                VStack(spacing: 2) {
                    ProfileHeaderView(viewModel: profileViewModel)
                    ProfileSlideBar(viewModel: profileViewModel, userService: userService, profileSection: $profileSection)
                }
            }
            .task { await profileViewModel.checkIfUserIsFollowed() }
            /*.task { await profileViewModel.fetchUserStats() }*/
            /*.navigationTitle(profileViewModel.user.username)
            .navigationBarTitleDisplayMode(.inline) */
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
}
/*
#Preview {
    ProfileView(user: DeveloperPreview.user, userService: UserService())
}
*/
