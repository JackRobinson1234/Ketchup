//
//  ProfileSlideBar.swift
//  Foodi
//
//  Created by Jack Robinson on 2/19/24.
//

import SwiftUI

enum ProfileSectionEnum {
    case posts, likes, collections
}

struct ProfileSlideBar: View {
    @Binding var profileSection: ProfileSectionEnum
    @ObservedObject var viewModel: ProfileViewModel
    private let userService: UserService
    
    init(viewModel: ProfileViewModel, userService: UserService, profileSection: Binding<ProfileSectionEnum>) {
        self.userService = userService
        self._profileSection = profileSection
        self.viewModel = viewModel
        }

    var body: some View {
        //MARK: Images
        VStack{
            HStack(spacing: 0) {
                Image(systemName: profileSection == .posts ? "square.grid.2x2.fill" : "square.grid.2x2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 15)
                
                    .onTapGesture {
                        withAnimation {
                            self.profileSection = .posts
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: profileSection == .posts))
                    .frame(maxWidth: .infinity)
                    //.task { await viewModel.fetchUserPosts() }
                
                Image(systemName: profileSection == .likes ? "heart.fill" : "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 20)
                
                    .onTapGesture {
                        withAnimation {
                            self.profileSection = .likes
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: profileSection == .likes))
                    .frame(maxWidth: .infinity)
                    
                
               
                Image(systemName: profileSection == .collections ? "folder.fill" : "folder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 20)
                
                    .onTapGesture {
                        withAnimation {
                            self.profileSection = .collections
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: profileSection == .collections))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .padding(.bottom, 10)
        
        // MARK: Section Logic
        
        if profileSection == .posts {
            PostGridView(posts: viewModel.posts, userService: userService)
        }
        
                
        if profileSection == .likes {
            LikedPostsView(user: viewModel.user, userService: userService, postService: PostService())
                
            }
        if profileSection == .collections {
            CollectionsListView(user: viewModel.user)
        }
        
        }
    
    }
        


/*
#Preview {
    CurrentProfileSlideBarView(viewModel: ProfileViewModel(user: DeveloperPreview.users[0], userService: UserService(), postService: PostService()), userService: UserService(), currentProfileSection: .constant(.posts), likesViewModel: LikedVideosViewModel(user: DeveloperPreview.users[0], userService: UserService(), postService: PostService()))
}
*/
