//
//  RestaurantProfileSlideBarView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

enum Section {
    case posts, collections, stats
}
enum RestaurantPostDisplayMode: String, CaseIterable {
    case all = "All Posts"
    case media = "Media Only"
}
struct RestaurantProfileSlideBarView: View {
    @ObservedObject var viewModel: RestaurantViewModel
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var restaurantPostDisplayMode: PostDisplayMode = .media
    @Binding var scrollPosition: String?
    @Binding var scrollTarget: String?
    
    init(viewModel: RestaurantViewModel, feedViewModel: FeedViewModel, scrollPosition: Binding<String?>, scrollTarget: Binding<String?>) {
        self.viewModel = viewModel
        self.feedViewModel = feedViewModel
        self._scrollPosition = scrollPosition
        self._scrollTarget = scrollTarget
    }
    var body: some View {
        //MARK: Selecting Images
        VStack{
            HStack(spacing: 0) {
                let currentSection = viewModel.currentSection
                Image(systemName: currentSection == .posts ? "line.3.horizontal" : "line.3.horizontal")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 15)
                
                    .onTapGesture {
                        withAnimation {
                            viewModel.currentSection = .posts
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentSection == .posts))
                    .frame(maxWidth: .infinity)
                
                
                Image(systemName: currentSection == .stats ? "info.circle.fill" : "info.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 22)
                    .onTapGesture {
                        withAnimation {
                            viewModel.currentSection = .stats
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentSection == .stats))
                    .frame(maxWidth: .infinity)
                
                Image(systemName: currentSection == .collections ? "folder.fill" : "folder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 22)
                
                    .onTapGesture {
                        withAnimation {
                            viewModel.currentSection = .collections
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentSection == .collections))
                    .frame(maxWidth: .infinity)
                
                
                
                
            }
        }
        .padding()
        
        
        // MARK: Section Logic
        if viewModel.currentSection == .posts {
            VStack {
                if let name = viewModel.restaurant?.name {
                    PostGridView(feedViewModel: feedViewModel, feedTitleText: "User Posts of \(name)", showNames: false, scrollPosition: $scrollPosition, scrollTarget: $scrollTarget, friendIds: viewModel.friendsWhoPosted.map { $0.id })
                }
            }
        }
        if viewModel.currentSection == .collections {
            RestaurantCollectionListView(viewModel: viewModel)
        }
        
        if viewModel.currentSection == .stats {
            if let restaurant = viewModel.restaurant{
                RestaurantStatsView(restaurant: restaurant, scrollPosition: $scrollPosition, scrollTarget: $scrollTarget, viewModel: viewModel)
            }
        }
    }
}

struct UnderlineImageModifier: ViewModifier {
    var isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(isSelected ? Color("Colors/AccentColor") : .black)
            .overlay(
                VStack {
                    Spacer()
                        .frame(height: 40) // Adjust the height of the spacer to control the distance between the image and the underline bar
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(isSelected ? Color("Colors/AccentColor") : .clear)
                }
            )
    }
}

