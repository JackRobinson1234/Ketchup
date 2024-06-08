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
    @State var showFollowersList: Bool = false
    @State var showFollowingList: Bool = false
    
    init(showEditProfile: Bool = false, viewModel: ProfileViewModel, userFavorites: [FavoriteRestaurant] = []) {
        self.viewModel = viewModel
        self.userFavorites = viewModel.user.favorites
    }
    
    var body: some View {
        let user = viewModel.user
        //let user = DeveloperPreview.users[0]
        let frameWidth = UIScreen.main.bounds.width / 3 - 15
        VStack(spacing: 10) {
            HStack (alignment: .bottom) {
                Spacer()
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .frame(width: frameWidth)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Spacer()
                UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .xxLarge)
                    .frame(width: frameWidth)
                Spacer()
                
                if user.isCurrentUser {
                    Button {
                        showEditProfile.toggle()
                    } label: {
                        Text("Edit Profile")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundColor(.black)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .frame(width: frameWidth)
                    }
                } else {
                    Button {
                        handleFollowTapped()
                    } label: {
                        Text(user.isFollowed ? "Following" : "Follow")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundColor(user.isFollowed ? .black : .white)
                            .background(user.isFollowed ? Color.white : Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray, lineWidth: user.isFollowed ? 1 : 0)
                            }
                            .frame(width: frameWidth)
                    }
                }
                Spacer()
                
            }
            
          
            Text(user.fullname)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
      
            
            HStack(spacing: 4) {
                UserStatView(value: user.stats.followers, title: "Followers")
                UserStatView(value: user.stats.following, title: "Following")
                UserStatView(value: user.stats.posts, title: "Posts")
                UserStatView(value: user.stats.collections, title: "Collections")
            }
            if user.privateMode == false || user.isCurrentUser {
                FavoriteRestaurantsView(user: user, favorites: user.favorites)
            }
            
            // Additional components if needed
        }
        .padding([.bottom])
        .fullScreenCover(isPresented: $showEditProfile) {
            EditProfileView(user: $viewModel.user)
        }
        .sheet(isPresented: $showFollowingList) {
            ProfileUserLists(config: .following(uid: user.id))
        }
        .sheet(isPresented: $showFollowersList) {
            ProfileUserLists(config: .followers(uid: user.id))
        }
    }
    
    func handleFollowTapped() {
        viewModel.user.isFollowed ? viewModel.unfollow() : viewModel.follow()
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
        .frame(width:  UIScreen.main.bounds.width / 4 - 30, alignment: .center)
        .padding(.vertical, 10)
        .foregroundColor(.black)
    }
}

#Preview {
    ProfileHeaderView(viewModel: ProfileViewModel(uid: "1234")
    )
}
