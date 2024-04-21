//
//  CreatePostSelection.swift
//  Foodi
//
//  Created by Jack Robinson on 2/5/24.
//
/*
 import SwiftUI
 enum PostType {
     case restaurant
     case recipe
     case brand
 }
 struct CreatePostSelection: View {
     @Binding var selectedTab: Int
     @State var restaurantPostCover: Bool = false
     @State var recipePostCover: Bool = false
     @State var brandPostCover: Bool = false
     @ObservedObject var viewModel: UploadPostViewModel
     
     init(selectedTab: Binding<Int>, viewModel: UploadPostViewModel) {
         self._selectedTab = selectedTab
         self.viewModel = viewModel
     }
         
     
     
     
     var body: some View {
         NavigationStack{
             VStack{
                 Button{restaurantPostCover.toggle()}
             label: {postOption(image:"building.2", title: "Post About a Restaurant", description: "Restaurant posts appear on the Discover Feed and on the selected restaurant's profile")}
                 
                 Button{recipePostCover.toggle() } label: {
                     postOption(image: "fork.knife.circle", title: "Post Food You Cooked", description: "Food you Cooked posts appear on the Discover Feed")
                 }
                 Button{brandPostCover.toggle()} label: {
                     postOption(image: "bag", title: "Post About a Food Brand", description: "Brand posts appear on the Discover Feed")
                 }
                 Spacer()
             }
             .toolbar(.hidden, for: .tabBar)
             .fullScreenCover(isPresented: $restaurantPostCover){RestaurantSelectorView(tabIndex: $selectedTab, cover: $restaurantPostCover, postType: .restaurant)}
             .fullScreenCover(isPresented: $recipePostCover){NavigationStack{UploadPostView(viewModel: viewModel, tabIndex: $selectedTab, restaurant: nil, cover: $recipePostCover, postType: .recipe)}}
             .fullScreenCover(isPresented: $brandPostCover){NavigationStack{MediaSelectorView(tabIndex: $selectedTab, cover: $brandPostCover, postType: .brand)}}
         }
     }
 }


 struct postOption: View {
     var image: String
     var title: String
     var description: String
     var body: some View {
         HStack(spacing: 10){
             Image(systemName: image)
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(width: 50)
                 .foregroundColor(.black)
             Spacer()
             VStack (alignment: .leading){
                 Text(title)
                     .font(.title3)
                     .bold()
                     .multilineTextAlignment(.leading)
                 Text(description)
                     .font(.subheadline)
                     .multilineTextAlignment(.leading)
             }
                 .frame(maxWidth: .infinity, alignment: .leading)
             Spacer()
             Image(systemName: "chevron.right")
                 .foregroundStyle(.black)
             
         }
         .padding()
     }
 }
*/
