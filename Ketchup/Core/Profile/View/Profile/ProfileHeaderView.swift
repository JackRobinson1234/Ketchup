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
    @Binding var showZoomedProfileImage: Bool
    
    init(showEditProfile: Bool = false, viewModel: ProfileViewModel, userFavorites: [FavoriteRestaurant] = [], showZoomedProfileImage: Binding<Bool>) {
        self.viewModel = viewModel
        self._showZoomedProfileImage = showZoomedProfileImage
        self.userFavorites = viewModel.user.favorites
    }
    
    var body: some View {
        let user = viewModel.user
        let frameWidth = UIScreen.main.bounds.width / 3 - 15
        VStack(spacing: 6) {
            HStack(alignment: .top) {
                Spacer()
                UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .xxLarge)
                    .frame(width: frameWidth)
                    .onTapGesture {
                        showZoomedProfileImage.toggle()
                    }
                VStack(alignment: .leading) {
                    Text(user.fullname)
                        .font(.custom("MuseoSansRounded-300", size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("@\(user.username)")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundColor(Color("Colors/AccentColor"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    if let location = user.location, let city = location.city, let state = location.state {
                        Text("\(city), \(state)")
                            .font(.custom("MuseoSansRounded-300", size: 14))
                            .foregroundColor(.black)
                        
                    }
                    
                    if user.isCurrentUser {
                        Button {
                            showEditProfile.toggle()
                        } label: {
                            Text("Edit Profile")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .fontWeight(.semibold)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 8)
                                .foregroundColor(Color("Colors/AccentColor"))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color("Colors/AccentColor"), lineWidth: 1)
                                }
                        }
                    } else if user.id != "6nLYduH5e0RtMvjhediR7GkaI003"{
                        Button {
                            handleFollowTapped()
                        } label: {
                            Text(user.isFollowed ? "Following" : "Follow")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .fontWeight(.semibold)
                                .frame(width: 130)
                                .padding(.vertical, 8)
                                .foregroundColor(user.isFollowed ? Color("Colors/AccentColor") : .white)
                                .background(user.isFollowed ? Color.clear : Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color("Colors/AccentColor"), lineWidth: user.isFollowed ? 1 : 0)
                                }
                        }
                    }
                }
                Spacer()
            }
            
            HStack(spacing: 4) {
                Button {
                    showFollowersList.toggle()
                } label: {
                    UserStatView(value: user.stats.followers, title: "Followers")
                }
                Button {
                    showFollowingList.toggle()
                } label: {
                    UserStatView(value: user.stats.following, title: "Following")
                }
                Button {
                    viewModel.profileSection = .posts
                } label: {
                    UserStatView(value: user.stats.posts, title: "Posts")
                }
                Button {
                    viewModel.profileSection = .collections
                } label: {
                    UserStatView(value: user.stats.collections, title: "Collections")
                }
            }
            
            Text("🔥\(user.weeklyStreak) week streak")
                .font(.custom("MuseoSansRounded-700", size: 14))
                .foregroundColor(.black)
                .cornerRadius(12)
            
            Text("Favorites")
                .font(.custom("MuseoSansRounded-700", size: 14))
                .foregroundStyle(.black)
            
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
                .font(.custom("MuseoSansRounded-300", size: 16))
                .fontWeight(.bold)
            
            Text(title)
                .font(.custom("MuseoSansRounded-300", size: 10))
                .foregroundStyle(.gray)
        }
        .opacity(value == 0 ? 0.5 : 1.0)
        .frame(width: UIScreen.main.bounds.width / 4 - 30, alignment: .center)
        .padding(.vertical, 10)
        .foregroundColor(.black)
    }
}
