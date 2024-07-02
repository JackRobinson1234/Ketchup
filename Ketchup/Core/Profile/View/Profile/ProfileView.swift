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
    @State private var showingOptionsSheet = false
    @State var isDragging = false
    @State var dragDirection = "left"
    @State private var scrollPosition: String?
    @State private var scrollTarget: String?
    private let uid: String
    var drag: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if profileSection == .posts {
                        dismiss()
                   
                    } else if profileSection == .likes{
                        profileSection = .collections
                    } else if profileSection == .collections{
                        profileSection = .posts
                    }
                } else {
                        self.dragDirection = "right"
                        if profileSection == .posts {
                            profileSection = .collections
                        } else if profileSection == .collections{
                            profileSection = .likes
                        }
                        self.isDragging = false
                    }
                
            }
    }

    init(uid: String, profileSection: ProfileSectionEnum = .posts) {
        self.uid = uid
        let profileViewModel = ProfileViewModel(uid: uid)
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
            ScrollViewReader{ scrollProxy in
                ScrollView {
                    VStack(spacing: 2) {
                        ProfileHeaderView(viewModel: profileViewModel, profileSection: $profileSection)
                        if !profileViewModel.user.privateMode {
                            ProfileSlideBar(viewModel: profileViewModel, profileSection: $profileSection,
                                            scrollPosition: $scrollPosition,
                                            scrollTarget: $scrollTarget)
                        } else {
                            VStack {
                                Image(systemName: "lock.fill")
                                    .font(.largeTitle)
                                    .padding()
                                Text("Account is private")
                                    .font(.custom("MuseoSansRounded-300", size: 18))
                            }
                        }
                    }
                }
                .scrollPosition(id: $scrollPosition)
                .onChange(of: scrollTarget) {
                    scrollPosition = scrollTarget
                    scrollProxy.scrollTo(scrollTarget, anchor: .center)
                }
            }
            .gesture(drag)
            .sheet(isPresented: $showingOptionsSheet) {
                ProfileOptionsSheet(user: profileViewModel.user)
                        .presentationDetents([.height(UIScreen.main.bounds.height * 0.10)])
            }
            .task { await profileViewModel.checkIfUserIsFollowed() }
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !profileViewModel.user.isCurrentUser {
                        Button {
                            showingOptionsSheet = true
                        } label: {
                            ZStack{
                                Rectangle()
                                    .fill(.clear)
                                    .frame(width: 18, height: 14)
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 5, height: 5)
                                    .foregroundStyle(.primary)
                                
                            }
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .navigationDestination(for: FavoriteRestaurant.self) { restaurant in
                RestaurantProfileView(restaurantId: restaurant.id)
            }
        }
    }
}

#Preview {
    ProfileView(uid: DeveloperPreview.user.id)
}

