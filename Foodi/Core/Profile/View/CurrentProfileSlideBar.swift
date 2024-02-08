//
//  CurrentProfileSlideBar.swift
//  Foodi
//
//  Created by Jack Robinson on 2/8/24.
//

import SwiftUI

import SwiftUI

enum currentProfileSection {
    case posts, likes, collections, messages
}

struct CurrentProfileSlideBarView: View {
    @Binding var currentProfileSection: currentProfileSection
    @ObservedObject var viewModel: ProfileViewModel
    private let userService: UserService
    init(viewModel: ProfileViewModel, userService: UserService, currentProfileSection: Binding<currentProfileSection>) {
            self.userService = userService
            self._currentProfileSection = currentProfileSection
            self.viewModel = viewModel
        }

    var body: some View {
        //MARK: Selecting Images
        VStack{
            HStack(spacing: 0) {
                Image(systemName: currentProfileSection == .posts ? "square.grid.2x2.fill" : "square.grid.2x2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 20)
                
                    .onTapGesture {
                        withAnimation {
                            self.currentProfileSection = .posts
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentProfileSection == .posts))
                    .frame(maxWidth: .infinity)
                
                Image(systemName: currentProfileSection == .likes ? "heart.fill" : "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 25)
                
                    .onTapGesture {
                        withAnimation {
                            self.currentProfileSection = .likes
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentProfileSection == .likes))
                    .frame(maxWidth: .infinity)
                
                Image(systemName: currentProfileSection == .collections ? "folder.fill" : "folder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 22)
                
                    .onTapGesture {
                        withAnimation {
                            self.currentProfileSection = .collections
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentProfileSection == .collections))
                    .frame(maxWidth: .infinity)
                Image(systemName: currentProfileSection == .messages ? "message.fill" : "message")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 20)
                
                    .onTapGesture {
                        withAnimation {
                            self.currentProfileSection = .messages
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: currentProfileSection == .messages))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white)
        
        
        // MARK: Section Logic
        
    }
}



#Preview {
    CurrentProfileSlideBarView(viewModel: ProfileViewModel(user: DeveloperPreview.users[0], userService: UserService(), postService: PostService()), userService: UserService(), currentProfileSection: .constant(.posts))
}
