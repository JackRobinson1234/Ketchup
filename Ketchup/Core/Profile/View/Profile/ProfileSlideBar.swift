//
//  ProfileSlideBar.swift
//  Foodi
//
//  Created by Jack Robinson on 2/19/24.
//

import SwiftUI

//  ProfileSlideBar.swift
//  Foodi
//
//  Created by Jack Robinson on 2/19/24.
//

import SwiftUI

enum ProfileSectionEnum {
    case posts, bookmarks, collections, map
}

enum PostDisplayMode: String, CaseIterable {
    case all = "All Posts"
    case media = "Only Media"
}

struct ProfileSlideBar: View {
    @Binding var profileSection: ProfileSectionEnum
    @ObservedObject var viewModel: ProfileViewModel
    @StateObject var collectionsViewModel: CollectionsViewModel
    @ObservedObject var feedViewModel = FeedViewModel()
    @Binding var scrollPosition: String?
    @Binding var scrollTarget: String?
    @State private var postDisplayMode: PostDisplayMode = .media

    private var isKetchupMediaUser: Bool {
        return viewModel.user.username == "ketchup_media"
    }

    init(viewModel: ProfileViewModel, feedViewModel: FeedViewModel, profileSection: Binding<ProfileSectionEnum>, scrollPosition: Binding<String?>, scrollTarget: Binding<String?>) {
        self._profileSection = profileSection
        self.feedViewModel = feedViewModel
        self.viewModel = viewModel
        self._collectionsViewModel = StateObject(wrappedValue: CollectionsViewModel())
        self._scrollPosition = scrollPosition
        self._scrollTarget = scrollTarget
    }

    var body: some View {
        VStack {
            // MARK: Images
            HStack(spacing: 0) {
                Image(systemName: profileSection == .posts ? "line.3.horizontal" : "line.3.horizontal")
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

                Image(systemName: profileSection == .map ? "location.fill" : "location")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 20)
                    .onTapGesture {
                        withAnimation {
                            self.profileSection = .map
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: profileSection == .map))
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

                Image(systemName: profileSection == .bookmarks ? "bookmark.fill" : "bookmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 20)
                    .onTapGesture {
                        withAnimation {
                            self.profileSection = .bookmarks
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: profileSection == .bookmarks))
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .padding(.bottom, 22)

            // MARK: Section Logic
            if profileSection == .posts {
                VStack {
                    DropdownMenuView(selection: $postDisplayMode, options: PostDisplayMode.allCases)
                    
                    if isKetchupMediaUser && (postDisplayMode == .all || postDisplayMode == .media) {
                        Text("This user has too many posts to view")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        switch postDisplayMode {
                        case .all:
                            ProfileFeedView(
                                viewModel: feedViewModel,
                                scrollPosition: $scrollPosition,
                                scrollTarget: $scrollTarget
                            )
                        case .media:
                            PostGridView(feedViewModel: feedViewModel, feedTitleText: "Posts by @\(viewModel.user.username)", showNames: true)
                        }
                    }
                }
            }
            if profileSection == .map {
                ProfileMapView(feedViewModel: feedViewModel)
                    .id("map")
                    .onAppear {
                        scrollTarget = "map"
                    }
            }
            if profileSection == .bookmarks {
                Text("Building")
//                LikedPostsView(viewModel: viewModel, scrollPosition: $scrollPosition,
//                               scrollTarget: $scrollTarget)
            }

            if profileSection == .collections {
                CollectionsListView(viewModel: collectionsViewModel, user: viewModel.user)
            }
        }
    }
}
struct DropdownMenuView: View {
    @Binding var selection: PostDisplayMode
    @State private var isExpanded = false
    
    var options: [PostDisplayMode]
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { // Faster animation
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 1) {
                    Text(selection.rawValue)
                        .foregroundColor(.primary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.primary)
                }
            }
            .padding(.bottom)
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) { // Faster animation
                                isExpanded = false
                            }
                            selection = option
                        }) {
                            Text(option.rawValue)
                                .foregroundColor(.primary)
                                .padding()
                        }
                    }
                }
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}
