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
    @State var profileSection: ProfileSectionEnum
    private let uid: String


    init(uid: String, profileSection: ProfileSectionEnum = .posts) {
        self.uid = uid
        let profileViewModel = ProfileViewModel(uid: uid, postService: PostService())
        self._profileViewModel = StateObject(wrappedValue: profileViewModel)
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
                    if !profileViewModel.user.privateMode {
                        ProfileSlideBar(viewModel: profileViewModel, profileSection: $profileSection)
                    } else {
                        VStack {
                            Image(systemName: "lock.fill")
                                .font(.largeTitle)
                                .padding()
                            Text("Account is private")
                                .font(.headline)
                        }
                    }
                }
            }
            .task { await profileViewModel.checkIfUserIsFollowed() }
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

#Preview {
    ProfileView(uid: DeveloperPreview.user.id)
}

