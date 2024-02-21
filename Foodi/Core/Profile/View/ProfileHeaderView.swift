//
//  ProfileHeaderView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct ProfileHeaderView: View {
    @State private var showEditProfile = false
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var userFavorites: [FavoriteRestaurant]? = []
    private var user: User {
        return viewModel.user
    }
    init(showEditProfile: Bool = false, viewModel: ProfileViewModel, userFavorites: [FavoriteRestaurant] = []) {
        self.viewModel = viewModel
        self.userFavorites = user.favorites
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack{
                VStack(spacing: 8) {
                    UserCircularProfileImageView(user: user, size: .xLarge)
                }
                
                VStack(alignment: .leading ){
                    Text("\(user.username)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(10)
                        .padding(.leading)
                    HStack(spacing: 16) {
                        
                        NavigationLink(value: SearchModelConfig.users(userListConfig: .following(uid: user.id))) {
                            UserStatView(value: user.stats.following, title: "Following")
                        }
                        .disabled(user.stats.following == 0)
                        
                        NavigationLink(value: SearchModelConfig.users(userListConfig: .followers(uid: user.id))) {
                            UserStatView(value: user.stats.followers, title: "Followers")
                        }
                        .disabled(user.stats.followers == 0)
                        
                        UserStatView(value: user.stats.likes, title: "Saves")
                    }
                }
            }
            HStack{
                if let bio = user.bio {
                    Text(bio)
                        .font(.subheadline)
                        .padding(.horizontal,20)
                }
                Spacer()
            }
            
            FavoriteRestaurantsView(user: user, favoriteRestaurantViewEnum: .profileView, favorites: user.favorites)
            // action button view
            if user.isCurrentUser {
                Button {
                    showEditProfile.toggle()
                } label: {
                    Text("Edit Profile")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 360, height: 32)
                        .foregroundStyle(.black)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            } else {
                Button {
                    handleFollowTapped()
                } label: {
                    Text(user.isFollowed ? "Following" : "Follow")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 360, height: 32)
                        .foregroundStyle(user.isFollowed ? .black : .white)
                        .background(user.isFollowed ? .white : .blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray, lineWidth: user.isFollowed ? 1 : 0)
                        }
                }
            }
            
            
            Divider()
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            EditProfileView(user: $viewModel.user)
        }
    }
    
    func handleFollowTapped() {
        user.isFollowed ? viewModel.unfollow() : viewModel.follow()
    }
}

struct UserStatView: View {
    let value: Int
    let title: String
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .opacity(value == 0 ? 0.5 : 1.0)
        .frame(width: 80, alignment: .center)
        .foregroundColor(.black)
    }
}

#Preview {
    ProfileHeaderView(viewModel: ProfileViewModel(
        user: DeveloperPreview.users[0],
        userService: UserService(),
        postService: PostService())
    )
}
