//
//  CurrentUserProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
struct CurrentUserProfileView: View {
    @StateObject var profileViewModel: ProfileViewModel
    @State var currentProfileSection: ProfileSectionEnum
    @State var isLoading = true
    @State var showNotifications = false
    @State var showSettings = false
    @State var isDragging = false
    @State var dragDirection = "left"
    @State private var scrollPosition: String?
    @State private var scrollTarget: String?
    @State private var showZoomedProfileImage = false

    var drag: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    if currentProfileSection == .collections {
                        currentProfileSection = .posts
                    } else if currentProfileSection == .likes {
                        currentProfileSection = .collections
                    }
                } else {
                    self.dragDirection = "right"
                    if currentProfileSection == .posts {
                        currentProfileSection = .collections
                    } else if currentProfileSection == .collections {
                        currentProfileSection = .likes
                    }
                    self.isDragging = false
                }
            }
    }

    init(currentProfileSection: ProfileSectionEnum = .posts) {
        let viewModel = ProfileViewModel(uid: "")
        self._profileViewModel = StateObject(wrappedValue: viewModel)
        self._currentProfileSection = State(initialValue: currentProfileSection)
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                // Loading screen
                ProgressView("Loading...")
                    .onAppear {
                        Task {
                            await profileViewModel.fetchCurrentUser()
                            isLoading = false
                        }
                    }
            } else {
                NavigationStack {
                    ScrollViewReader { scrollProxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 2) {
                                //MARK: Profile Header
                                ProfileHeaderView(viewModel: profileViewModel, profileSection: $currentProfileSection, showZoomedProfileImage: $showZoomedProfileImage)
                                    .padding(.top)
                                //MARK: Slide bar
                                ProfileSlideBar(viewModel: profileViewModel, profileSection: $currentProfileSection,
                                                scrollPosition: $scrollPosition,
                                                scrollTarget: $scrollTarget)
                            }
                        }
                        .onChange(of: scrollTarget) {
                            scrollPosition = scrollTarget
                            withAnimation {
                                scrollProxy.scrollTo(scrollTarget, anchor: .center)
                            }
                        }
                        .scrollPosition(id: $scrollPosition)
                    }
                    .gesture(drag)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showSettings.toggle()
                            } label: {
                                Image(systemName: "gearshape")
                                    .foregroundStyle(.primary)
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
                                        .foregroundColor(.primary)
                                        .padding()

                                    if profileViewModel.user.notificationAlert > 0 {
                                        Circle()
                                            .fill(Color("Colors/AccentColor"))
                                            .frame(width: 10, height: 10)
                                            .offset(x: 10, y: -10)
                                    }
                                }
                            }
                            .font(.custom("MuseoSansRounded-300", size: 18))
                            .foregroundColor(.primary)
                        }
                    }

                    //.navigationTitle(Text("@\(profileViewModel.user.username)"))
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: User.self) { user in
                        ProfileView(uid: user.id)
                    }
                    .navigationBarBackButtonHidden(true)
                    .refreshable { Task { try await profileViewModel.refreshCurrentUser() } }
                    .sheet(isPresented: $showNotifications) {
                        NotificationsView()
                    }
                    .fullScreenCover(isPresented: $showSettings) {
                        SettingsView(profileViewModel: profileViewModel)
                    }
                    .navigationDestination(for: FavoriteRestaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
                    .onChange(of: AuthService.shared.userSession) {
                        if AuthService.shared.userSession != nil {
                            Task { try await profileViewModel.refreshCurrentUser() }
                        }
                    }
                    .navigationDestination(for: PostRestaurant.self) { restaurant in
                        RestaurantProfileView(restaurantId: restaurant.id)
                    }
                }
            }

            if showZoomedProfileImage {
                Color.black.opacity(0.5)
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





#Preview {
    CurrentUserProfileView()
}
