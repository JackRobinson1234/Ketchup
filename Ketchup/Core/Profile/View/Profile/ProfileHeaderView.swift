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
    @Binding var profileSection: ProfileSectionEnum
    init(showEditProfile: Bool = false, viewModel: ProfileViewModel, userFavorites: [FavoriteRestaurant] = [], profileSection: Binding<ProfileSectionEnum>) {
        self.viewModel = viewModel
        self._profileSection = profileSection
        self.userFavorites = viewModel.user.favorites
      
    }
    
    var body: some View {
        let user = viewModel.user
        //let user = DeveloperPreview.users[0]
        let frameWidth = UIScreen.main.bounds.width / 3 - 15
        VStack(spacing: 10) {
            HStack (alignment: .bottom) {
                Spacer()
                UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .xxLarge)
                    .frame(width: frameWidth)
                VStack(alignment: .leading) {
                    Text(user.fullname)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        //.frame(width: frameWidth)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    if user.isCurrentUser {
                        Button {
                            showEditProfile.toggle()
                        } label: {
                            Text("Edit Profile")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 8)
                                .foregroundColor(Color("Colors/AccentColor"))
                                //.background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color("Colors/AccentColor"), lineWidth: 1)
                                }
                                //.frame(width: frameWidth)
                        }
                    } else {
                        Button {
                            handleFollowTapped()
                        } label: {
                            Text(user.isFollowed ? "Following" : "Follow")
                                .font(.subheadline)
                                .fontWeight(.semibold)
//                                .padding(.horizontal, 30)
                                .frame(width: 130)
                                .padding(.vertical, 8)
                                .foregroundColor(user.isFollowed ? Color("Colors/AccentColor") : .white)
                                .background(user.isFollowed ? Color.clear : Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color("Colors/AccentColor"), lineWidth: user.isFollowed ? 1 : 0)
                                }
                                //.frame(width: frameWidth)
                        }
                    }
                }
                Spacer()
                
            }
            
          
          
            
      
            
            HStack(spacing: 4) {
                Button{ 
                    showFollowersList.toggle()
                }label: {
                    UserStatView(value: user.stats.followers, title: "Followers")
                }
                Button{
                    showFollowingList.toggle()
                } label: {
                    UserStatView(value: user.stats.following, title: "Following")
                }
                Button{
                    profileSection = .posts
                } label: {
                    UserStatView(value: user.stats.posts, title: "Posts")
                }
                Button{
                    profileSection = .collections
                } label: {
                    UserStatView(value: user.stats.collections, title: "Collections")
                }
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
        .foregroundColor(.primary)
    }
        
}

#Preview {
    ProfileHeaderView(viewModel: ProfileViewModel(uid: "1234"), profileSection: .constant(.posts)
    )
}
