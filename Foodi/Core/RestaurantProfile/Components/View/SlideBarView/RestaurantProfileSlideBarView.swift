//
//  RestaurantProfileSlideBarView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

import SwiftUI

enum Section {
    case posts, menu, map, reviews
}

struct RestaurantProfileSlideBarView: View {
    @Binding var currentSection: Section
    @ObservedObject var viewModel: RestaurantViewModel

    var body: some View {
        //MARK: Selecting Images
        VStack{
            HStack(spacing: 0) {
                Image(systemName: currentSection == .posts ? "square.grid.2x2.fill" : "square.grid.2x2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 20)
                
                    .onTapGesture {
                        withAnimation {
                            self.currentSection = .posts
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentSection == .posts))
                    .frame(maxWidth: .infinity)
                
                Image(systemName: currentSection == .menu ? "menucard.fill" : "menucard")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 25)
                
                    .onTapGesture {
                        withAnimation {
                            self.currentSection = .menu
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentSection == .menu))
                    .frame(maxWidth: .infinity)
                
                Image(systemName: currentSection == .map ? "location.fill" : "location")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 22)
                
                    .onTapGesture {
                        withAnimation {
                            self.currentSection = .map
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentSection == .map))
                    .frame(maxWidth: .infinity)
                Image(systemName: currentSection == .reviews ? "message.fill" : "message")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 20)
                
                    .onTapGesture {
                        withAnimation {
                            self.currentSection = .reviews
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentSection == .reviews))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white)
        
        
        // MARK: Section Logic
        if currentSection == .map {
            MapRestaurantProfileView(viewModel: viewModel)

        }
        if currentSection == .posts {
            PostGridView(posts: viewModel.posts, userService: UserService())
        }
    }
}

struct UnderlineImageModifier: ViewModifier {
    var isSelected: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    Spacer()
                        .frame(height: 40) // Adjust the height of the spacer to control the distance between the image and the underline bar
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(isSelected ? .black : .clear)
                }
            )
    }
}


/*
#Preview {
    RestaurantProfileSlideBarView(viewModel: RestaurantViewModel(restaurant: DeveloperPreview.restaurants[0], restaurantService: RestaurantService(), postService: PostService()))
}
*/
