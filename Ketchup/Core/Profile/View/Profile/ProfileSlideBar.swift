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
    @ObservedObject var viewModel: ProfileViewModel
    @StateObject var collectionsViewModel: CollectionsViewModel
    @ObservedObject var feedViewModel: FeedViewModel
    @Binding var scrollPosition: String?
    @Binding var scrollTarget: String?
    @State private var postDisplayMode: PostDisplayMode = .media

    private var isKetchupMediaUser: Bool {
        return viewModel.user.username == "ketchup_media"
    }

    init(viewModel: ProfileViewModel, feedViewModel: FeedViewModel, scrollPosition: Binding<String?>, scrollTarget: Binding<String?>) {
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
                Image(systemName: viewModel.profileSection == .posts ? "line.3.horizontal" : "line.3.horizontal")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 15)
                    .onTapGesture {
                        withAnimation {
                            self.viewModel.profileSection = .posts
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: viewModel.profileSection == .posts))
                    .frame(maxWidth: .infinity)

                Image(systemName: viewModel.profileSection == .map ? "location.fill" : "location")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 20)
                    .onTapGesture {
                        withAnimation {
                            self.viewModel.profileSection = .map
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: viewModel.profileSection == .map))
                    .frame(maxWidth: .infinity)

                Image(systemName: viewModel.profileSection == .collections ? "folder.fill" : "folder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 20)
                    .onTapGesture {
                        withAnimation {
                            self.viewModel.profileSection = .collections
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: viewModel.profileSection == .collections))
                    .frame(maxWidth: .infinity)

                Image(systemName: viewModel.profileSection == .bookmarks ? "bookmark.fill" : "bookmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 20)
                    .onTapGesture {
                        withAnimation {
                            self.viewModel.profileSection = .bookmarks
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: viewModel.profileSection == .bookmarks))
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .padding(.bottom, 16)

            // MARK: Section Logic
            if viewModel.profileSection == .posts {
                VStack {
                   
                    if isKetchupMediaUser {
                        Text("This user has too many posts to view")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                            PostGridView(feedViewModel: feedViewModel, feedTitleText: "Posts by @\(viewModel.user.username)", showNames: true, scrollPosition: $scrollPosition, scrollTarget: $scrollTarget)
                        
                    }
                }
            }
            if viewModel.profileSection == .map {
                ProfileMapView(feedViewModel: feedViewModel)
                    .id("map")
                    .onAppear {
                        scrollTarget = "map"
                    }
            }
            if viewModel.profileSection == .bookmarks {
                BookmarksListView(profileViewModel: viewModel)
            }

            if viewModel.profileSection == .collections {
                CollectionsListView(viewModel: collectionsViewModel, user: viewModel.user)
            }
        }
    }
}
