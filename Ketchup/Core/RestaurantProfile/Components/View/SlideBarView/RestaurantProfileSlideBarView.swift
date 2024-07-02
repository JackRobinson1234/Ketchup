//
//  RestaurantProfileSlideBarView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

import SwiftUI

enum Section {
    case posts, collections
}
enum RestaurantPostDisplayMode: String, CaseIterable {
    case all = "All"
    case media = "Media"
}
struct RestaurantProfileSlideBarView: View {
    @ObservedObject var viewModel: RestaurantViewModel
       @StateObject var reviewsViewModel: ReviewsViewModel
       @StateObject var feedViewModel: FeedViewModel
       @State private var restaurantPostDisplayMode: RestaurantPostDisplayMode = .media
       @Binding var scrollPosition: String?
       @Binding var scrollTarget: String?

       init(viewModel: RestaurantViewModel, scrollPosition: Binding<String?>, scrollTarget: Binding<String?>) {
           self.viewModel = viewModel
           self._reviewsViewModel = StateObject(wrappedValue: ReviewsViewModel(restaurant: viewModel.restaurant))
           self._feedViewModel = StateObject(wrappedValue: FeedViewModel())
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
                    .frame(width: 50, height: 20)
                
                    .onTapGesture {
                        withAnimation {
                            viewModel.currentSection = .posts
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentSection == .posts))
                    .frame(maxWidth: .infinity)
                
                
//                Image(systemName: currentSection == .reviews ? "line.3.horizontal" : "line.3.horizontal")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 50, height: 14)
//                    .font(currentSection == .reviews ? .system(size: 10, weight: .bold) : .system(size: 10, weight: .regular))
//                    .onTapGesture {
//                        withAnimation {
//                            viewModel.currentSection = .reviews
//                        }
//                    }
//                    .modifier(UnderlineImageModifier(isSelected: currentSection == .reviews))
//                    .frame(maxWidth: .infinity)
                
                
//                Image(systemName: currentSection == .menu ? "menucard.fill" : "menucard")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 50, height: 25)
//                
//                    .onTapGesture {
//                        withAnimation {
//                            viewModel.currentSection = .menu
//                        }
//                    }
//                    .modifier(UnderlineImageModifier(isSelected: currentSection == .menu))
//                    .frame(maxWidth: .infinity)
////                
//                Image(systemName: currentSection == .map ? "location.fill" : "location")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 50, height: 22)
//                
//                    .onTapGesture {
//                        withAnimation {
//                            self.currentSection = .map
//                        }
//                    }
//                    .modifier(UnderlineImageModifier(isSelected: currentSection == .map))
//                    .frame(maxWidth: .infinity)
                
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
                Picker("Post Display Mode", selection: $restaurantPostDisplayMode) {
                    ForEach(RestaurantPostDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding([.bottom, .horizontal])
                
                
                switch restaurantPostDisplayMode {
                case .all:
                    ProfileFeedView(
                        viewModel: feedViewModel,
                        scrollPosition: $scrollPosition,
                        scrollTarget: $scrollTarget
                    )
                case .media:
                    if let name = viewModel.restaurant?.name {
                        PostGridView(posts: viewModel.posts, feedTitleText: "User Posts of \(name)")
                    }
                }
            }
            .onAppear {
                feedViewModel.posts = viewModel.posts
            }
        }
        if viewModel.currentSection == .collections {
            RestaurantCollectionListView(viewModel: viewModel)
        }
    }
}

struct UnderlineImageModifier: ViewModifier {
    var isSelected: Bool

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isSelected ? Color("Colors/AccentColor") : .primary)
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


//
//#Preview {
//    RestaurantProfileSlideBarView(currentSection: .constant(.reviews), viewModel: RestaurantViewModel(restaurantId: "test"))
//}
