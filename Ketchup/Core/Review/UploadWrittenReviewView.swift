//
//  UploadWrittenReviewView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/18/24.
//

import SwiftUI

struct UploadWrittenReviewView: View {
    @ObservedObject var reviewViewModel: ReviewsViewModel
    @EnvironmentObject var tabBarController: TabBarController
    @State var description: String = ""
    var maxCharacters = 150
    @State var recommend: Bool? = nil
    @State private var favoriteMenuItem: String = ""
    @State private var favoriteMenuItems: [String] = []
    @State private var isEditingCaption = false
    @FocusState private var isCaptionEditorFocused: Bool
    private let maxMenuItemCharacters = 50
    private let maxFavoriteMenuItems = 5
    @State var editedReview = false
    @State var isPickingRestaurant = false
    @State var setRestaurant = false
    private var canPostReview: Bool {
        return !description.isEmpty && recommend != nil
    }
    @Environment(\.dismiss) var dismiss
    @State var changeTab: Bool = false
    @State var pickingFavorites: Bool = false
    
    var body: some View {
        ZStack {
            Color.white
                 // Ensure it covers the entire screen including safe area
                .frame(width: UIScreen.main.bounds.width, height: 765) // Set to full screen height
                .cornerRadius(10)
            
            VStack {
                if let restaurant = reviewViewModel.selectedRestaurant {
                    Button {
                        isPickingRestaurant = true
                    } label: {
                        // REPLACE RESTAURANT
                        VStack{
                            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .xLarge)
                            
                            Text(restaurant.name)
                                .bold()
                                .font(.title3)
                            Text("\(restaurant.address ?? "") \(restaurant.city ?? ""), \(restaurant.state ?? "")")
                                .font(.subheadline)
                                .padding(.horizontal)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            
                            if let cuisine = restaurant.cuisine, let price = restaurant.price {
                                Text("\(cuisine), \(price)")
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                
                                
                            } else if let cuisine = restaurant.cuisine {
                                Text(cuisine)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                
                                
                            } else if let price = restaurant.price {
                                Text(price)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                            if let restaurantRequest = reviewViewModel.restaurantRequest{
                                Text("To be Created")
                                    .foregroundStyle(.primary)
                                    .font(.caption)
                            }
                            if !setRestaurant {
                                Text("Edit")
                                    .foregroundStyle(Color("Colors/AccentColor"))
                                    .font(.caption)
                            }
                        }
                        
                    }
                    .disabled(setRestaurant)
                } else {
                    Button {
                        isPickingRestaurant = true
                    } label: {
                        // ADD RESTAURANT
                        VStack {
                            Image(systemName: "plus")
                                .resizable()
                                .foregroundColor(Color("Colors/AccentColor"))
                                .frame(width: 40, height: 40, alignment: .center)
                            
                            Text("Add restaurant")
                                .foregroundColor(.black)
                            
                        }
                    }
                }
                
                if let restaurant = reviewViewModel.selectedRestaurant {
                    
                    HStack(spacing: 20) {
                        Button(action: { recommend = true }) {
                            VStack {
                                Image(systemName: "heart")
                                    .foregroundColor(recommend == true ? Color("Colors/AccentColor") : .gray)
                                    .font(.title)
                                Text("Recommend")
                                    .font(.caption)
                                    .foregroundStyle(recommend == true ? Color("Colors/AccentColor") : .gray)
                            }
                        }
                        
                        Button(action: { recommend = false }) {
                            VStack {
                                Image(systemName: "heart.slash")
                                    .foregroundColor(recommend == false ? .black : .gray)
                                    .font(.title)
                                Text("Don't Recommend")
                                    .font(.caption)
                                    .foregroundStyle(recommend == false ? .black : .gray)
                            }
                        }
                    }
                    .padding(20)
                    if recommend != nil {
                        VStack{
                            ZStack(alignment: .topLeading) {
                                
                                TextEditor(text: $description)
                                    .frame(height: 100)  // Adjust the height as needed
                                    .padding(4)
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Done") {
                                                dismissKeyboard()
                                            }
                                        }
                                    }
                                
                                if description.isEmpty {
                                    Text("Add a review...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                }
                            }
                            .padding()
                            Divider()
                            
                            if !description.isEmpty, editedReview == true {
                                
                                Button{pickingFavorites = true} label: {
                                    HStack {
                                        Image(systemName: "fork.knife.circle")
                                            .foregroundStyle(.black)
                                            .font(.subheadline)
                                        VStack (alignment: .leading){
                                            Text("Add Favorite Menu Items")
                                                .font(.subheadline)
                                                .foregroundStyle(.black)
                                            if !favoriteMenuItems.isEmpty{
                                                Text("\(favoriteMenuItems.count) items selected")
                                                    .font(.footnote)
                                                    .foregroundStyle(.gray)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.black)
                                        
                                    }
                                    .padding()
                                    
                                }
                                Divider()
                                
                                Button{
                                    Task{
                                        if let recommend {
                                            try await reviewViewModel.uploadReview(description: description, recommends: recommend, favorites: favoriteMenuItems)
                                        }
                                        if changeTab {
                                            tabBarController.selectedTab = 0
                                        } else {
                                            dismiss()
                                        }
                                    }
                                } label: {
                                    Text("Post Review")
                                        .modifier(StandardButtonModifier())
                                    
                                }
                                .opacity(recommend != nil ? 1 : 0)
                                .disabled(!canPostReview)
                            }
                            
                        }
                        .opacity(recommend != nil ? 1 : 0)
                        
                    }
                }
            }
            .padding()
            .padding(.top, 30)
            if !changeTab {
                VStack{
                    HStack{
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.primary.opacity(0.6))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            }
            
        }
        .sheet(isPresented: $pickingFavorites){
            NavigationStack{
                AddMenuItemsReview(favoriteMenuItem: $favoriteMenuItem, favoriteMenuItems: $favoriteMenuItems)
            }
            .presentationDetents([.height(UIScreen.main.bounds.height * 0.33)])
        }
        .onChange(of: description) {
            Debouncer(delay: 0.3).schedule{
                editedReview = true
            }
        }
        .sheet(isPresented: $isPickingRestaurant) {
            RestaurantReviewSelector(reviewsViewModel: reviewViewModel)
                .navigationTitle("Select Restaurant")
        }
    }
}
//#Preview {
//    UploadWrittenReviewView(review)
//}
