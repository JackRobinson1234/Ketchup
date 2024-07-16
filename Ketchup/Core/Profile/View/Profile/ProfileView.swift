//
//  ProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct ProfileView: View {
    @StateObject var profileViewModel: ProfileViewModel
    @StateObject var feedViewModel = FeedViewModel()
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    @State var profileSection: ProfileSectionEnum
    @State private var showingOptionsSheet = false
    @State var isDragging = false
    @State var dragDirection = "left"
    @State private var scrollPosition: String?
    @State private var scrollTarget: String?
    @State private var showZoomedProfileImage = false
    private let uid: String
    var drag: some Gesture {
        
        DragGesture(minimumDistance: 5)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if profileSection == .posts {
                        dismiss()
                        
                    } else if profileSection == .bookmarks{
                        profileSection = .collections
                    } else if profileSection == .collections{
                        profileSection = .posts
                    }
                } else {
                    self.dragDirection = "right"
                    if profileSection == .posts {
                        profileSection = .collections
                    } else if profileSection == .collections{
                        profileSection = .bookmarks
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
                        try await feedViewModel.fetchUserPosts(user: profileViewModel.user)
                        isLoading = false
                    }
                }
        } else{
            ZStack{
                ScrollViewReader{ scrollProxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 2) {
                            ProfileHeaderView(viewModel: profileViewModel, profileSection: $profileSection, showZoomedProfileImage: $showZoomedProfileImage)
                            if !profileViewModel.user.privateMode {
                                ProfileSlideBar(viewModel: profileViewModel, feedViewModel: feedViewModel, profileSection: $profileSection,
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
                        withAnimation {
                            print("SCROLLING")
                            scrollProxy.scrollTo(scrollTarget, anchor: .center)
                        }
                    }
                }
                .gesture(drag)
                .sheet(isPresented: $showingOptionsSheet) {
                    ProfileOptionsSheet(user: profileViewModel.user)
                        .presentationDetents([.height(UIScreen.main.bounds.height * 0.10)])
                }
                .task { await profileViewModel.checkIfUserIsFollowed() }
                .toolbar(.hidden, for: .tabBar)
                .toolbarBackground(Color.white, for: .navigationBar)
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
                
                if showZoomedProfileImage {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showZoomedProfileImage = false
                        }
                    VStack {
                        Spacer()
                        UserCircularProfileImageView(profileImageUrl: profileViewModel.user.profileImageUrl, size: .xxxLarge)
                            .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.width * 0.8)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .onTapGesture {
                                showZoomedProfileImage = false
                            }
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView(uid: DeveloperPreview.user.id)
}
