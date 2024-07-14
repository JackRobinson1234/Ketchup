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
    case posts, likes, collections
}

enum PostDisplayMode: String, CaseIterable {
    case all = "All"
    case media = "Media"
    case map = "Map"
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
            //MARK: Images
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
                
                Image(systemName: profileSection == .likes ? "heart.fill" : "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 20)
                    .onTapGesture {
                        withAnimation {
                            self.profileSection = .likes
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: profileSection == .likes))
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .padding(.bottom, 22)
            
            // MARK: Section Logic
            if profileSection == .posts {
                VStack {
                    Picker("Post Display Mode", selection: $postDisplayMode) {
                        ForEach(PostDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding([.bottom, .horizontal])
                    .onChange(of: postDisplayMode) {
                        if postDisplayMode == .map {
                            scrollTarget = "map"
                        }
                    }
                    
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
                        case .map:
                            ProfileMapView(feedViewModel: feedViewModel)
                                .id("map")
                        }
                    }
                }
               
            }
            
            if profileSection == .likes {
                LikedPostsView(viewModel: viewModel, scrollPosition: $scrollPosition,
                               scrollTarget: $scrollTarget)
            }
            
            if profileSection == .collections {
                CollectionsListView(viewModel: collectionsViewModel, user: viewModel.user)
            }
        }
    }
}
