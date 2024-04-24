//
//  SearchViewSlideBar.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct SearchViewSlideBar: View {
    @Binding var searchConfig: SearchModelConfig
    init(searchConfig: Binding<SearchModelConfig>) {
        self._searchConfig = searchConfig
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                Text("Restaurants")
                    .onTapGesture {
                        withAnimation {
                            self.searchConfig = .restaurants
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: searchConfig == .restaurants))
                
                Text("At Home Posts")
                    .onTapGesture {
                        withAnimation {
                            self.searchConfig = .posts
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: searchConfig == .posts))
                //.frame(maxWidth: .infinity)
                
                Text("Users")
                    .frame(width: 50, height: 25)
                
                    .onTapGesture {
                        withAnimation {
                            self.searchConfig = .users
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: searchConfig == .users))
                //.frame(maxWidth: .infinity)
                
                
                //.frame(maxWidth: .infinity)
                
                Text("Collections")
                    .onTapGesture {
                        withAnimation {
                            self.searchConfig = .collections
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: searchConfig == .collections))
                //.frame(maxWidth: .infinity)
                
            }
            .padding()
        }
    }
}

struct UnderlineTextModifier: ViewModifier {
    var isSelected: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    Spacer()
                        .frame(height: 10) // Adjust the height of the spacer to control the distance between the image and the underline bar
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(isSelected ? .black : .clear)
                }
            )
    }
}


#Preview {
    SearchViewSlideBar(searchConfig: .constant(.posts))
}
