//
//  SearchViewSlideBar.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct SearchViewSlideBar: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        VStack{
            //ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    Text("Restaurants")
                        .onTapGesture {
                            withAnimation {
                                viewModel.searchConfig = .restaurants
                            }
                        }
                        .modifier(UnderlineImageModifier(isSelected: viewModel.searchConfig == .restaurants))

                    
                    Text("Users")
                        .frame(width: 50, height: 25)
                    
                        .onTapGesture {
                            withAnimation {
                                viewModel.searchConfig = .users
                            }
                        }
                        .modifier(UnderlineImageModifier(isSelected: viewModel.searchConfig == .users))
                    //.frame(maxWidth: .infinity)
                    
                    
                    //.frame(maxWidth: .infinity)
                    
                    Text("Collections")
                        .onTapGesture {
                            withAnimation {
                                viewModel.searchConfig = .collections
                            }
                        }
                        .modifier(UnderlineImageModifier(isSelected: viewModel.searchConfig == .collections))
                    //.frame(maxWidth: .infinity)
                    
                }
                .padding()
            //}
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


//#Preview {
//    SearchViewSlideBar(searchConfig: .constant(.restaurants))
//}
