//
//  CurrentUserProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import FirebaseAuth
struct CurrentUserProfileView: View {
    @StateObject var profileViewModel: ProfileViewModel
    @State var currentProfileSection: ProfileSectionEnum
    @State var isLoading = true
    @State var showNotifications: Bool = false
    @State var showSettings = false
    @State var isDragging = false
    @State var dragDirection = "left"
    @State private var scrollPosition: String?
    @State private var scrollTarget: String?
    @State private var showZoomedProfileImage = false
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var selectedBadge: Badge? = nil
    @State private var selectedBadgeType: BadgeType? = nil

    @StateObject var collectionsViewModel = CollectionsViewModel()
    init(currentProfileSection: ProfileSectionEnum = .posts,  feedViewModel: FeedViewModel) {
        let viewModel = ProfileViewModel(uid: "")
        self._profileViewModel = StateObject(wrappedValue: viewModel)
        self._currentProfileSection = State(initialValue: currentProfileSection)
        self.feedViewModel = feedViewModel

    }
    
    var body: some View {
        ZStack {
            if isLoading {
                // Loading screen
                FastCrossfadeFoodImageView()
                    .onAppear {
                        Task {
                            await profileViewModel.fetchCurrentUser()
                            try await feedViewModel.fetchUserPosts(user: profileViewModel.user)
                            isLoading = false
                        }
                    }
            } else {
                NavigationStack {
                    ScrollViewReader { scrollProxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 2) {
                                //MARK: Profile Header
                                ProfileHeaderView(viewModel: profileViewModel,  showZoomedProfileImage: $showZoomedProfileImage)
                                    .padding(.top)
                                //MARK: Slide bar
                                ProfileSlideBar(viewModel: profileViewModel, collectionsViewModel: collectionsViewModel, feedViewModel: feedViewModel,
                                                scrollPosition: $scrollPosition,
                                                scrollTarget: $scrollTarget,
                                                selectedBadge: $selectedBadge,
                                                selectedBadgeType: $selectedBadgeType
                                )
                            }
                        }
                        .onChange(of: scrollTarget) {newValue in
                            scrollPosition = scrollTarget
                            withAnimation {
                                scrollProxy.scrollTo(scrollTarget, anchor: .center)
                            }
                        }
                        //.scrollPosition(id: $scrollPosition)
                    }
                    //.gesture(drag)
                    .toolbarBackground(Color.white, for: .navigationBar) // Set navigation bar background color
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showSettings.toggle()
                            } label: {
                                Image(systemName: "gearshape")
                                    .foregroundStyle(.black)
                            }
                        }

                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                Task {
                                    showNotifications.toggle()
                                    try await profileViewModel.clearNotificationAlerts()
                                }
                            } label : {
                                ZStack {
                                    Image(systemName: "bell")
                                        .font(.custom("MuseoSansRounded-300", size: 18))
                                        .foregroundColor(.black)

                                    if  profileViewModel.user.notificationAlert > 0 {
                                        Circle()
                                            .fill(Color("Colors/AccentColor"))
                                            .frame(width: 10, height: 10)
                                            .offset(x: 10, y: -10)
                                    }
                                }
                            }
                            .font(.custom("MuseoSansRounded-300", size: 18))
                            .foregroundColor(.black)
                        }
                    }

                    //.navigationTitle(Text("@\(profileViewModel.user.username)"))
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: User.self) { user in
                        ProfileView(uid: user.id)
                    }
                    .navigationBarBackButtonHidden(true)
                    .refreshable {
                        if profileViewModel.profileSection == .posts{
                            Task {
                                try await profileViewModel.refreshCurrentUser()
                                try await feedViewModel.fetchUserPosts(user: profileViewModel.user)
                            }
                        } else if profileViewModel.profileSection == .collections{
                            Task {
                                try await profileViewModel.refreshCurrentUser()
                                if let user = Auth.auth().currentUser?.uid {
                                    await collectionsViewModel.fetchCollections(user: user)
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $showNotifications) {
                        NotificationsView(isPresented: $showNotifications)
                    }
                    .fullScreenCover(isPresented: $showSettings) {
                        SettingsView(profileViewModel: profileViewModel)
                    }
                    .navigationDestination(for: FavoriteRestaurant.self) { restaurant in
                        
                            RestaurantProfileView(restaurantId: restaurant.id)
                        
                    }
                    .onChange(of: AuthService.shared.userSession) {newValue in
                        if AuthService.shared.userSession != nil {
                            Task { try await profileViewModel.refreshCurrentUser()
                            }
                        }
                    }
                    .navigationDestination(for: PostRestaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
                }
            }
            
            // Overlay for the popup
            if let badge = selectedBadge {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            selectedBadge = nil
                        }
                    }
                
                VStack {
                    Spacer()
                    BadgeDetailView(badge: badge, onDismiss: {
                        withAnimation {
                            selectedBadge = nil
                        }
                    })
                    .frame(width: UIScreen.main.bounds.width * 0.8,
                           height: UIScreen.main.bounds.height * 0.6)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    Spacer()
                }
            }
            
            // Overlay for Badge Type Info View
            if let badgeType = selectedBadgeType {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            selectedBadgeType = nil
                        }
                    }
                
                VStack {
                    Spacer()
                    BadgeTypeInfoView(badgeType: badgeType, onDismiss: {
                        withAnimation {
                            selectedBadgeType = nil
                        }
                    })
                    .frame(width: UIScreen.main.bounds.width * 0.8) // Keep a fixed width
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .fixedSize(horizontal: false, vertical: true) // Allow height to be dynamic based on content
                    Spacer()
                }
            }
            
            if showZoomedProfileImage {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showZoomedProfileImage = false
                        }
                    }
                VStack {
                    Spacer()
                    UserCircularProfileImageView(profileImageUrl: profileViewModel.user.profileImageUrl, size: .xxxLarge)
                        .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.width * 0.8)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .onTapGesture {
                            withAnimation {
                                showZoomedProfileImage = false
                            }
                        }
                    Spacer()
                }
                .transition(.scale)
            }
        }
        .navigationDestination(for: PostUser.self) { user in
            ProfileView(uid: user.id)
        }
    }
}
