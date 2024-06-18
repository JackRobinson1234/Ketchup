//
//  UploadWrittenReviewView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/18/24.
//

import SwiftUI

struct UploadWrittenReviewView: View {
    
    @ObservedObject var uploadViewModel: UploadViewModel
    @StateObject var reviewViewModel = ReviewsViewModel()
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
    private var canPostReview: Bool {
        return !description.isEmpty && recommend != nil
    }
    
    var body: some View {
        
        ZStack {
            
            Color.white
                .frame(width: UIScreen.main.bounds.width, height: 765)
                .cornerRadius(10)
            
            VStack {
                
                if let restaurant = uploadViewModel.restaurant {
                    
                    Button {
                        isPickingRestaurant = true
                    } label: {
                        // REPLACE RESTAURANT
                        RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .xLarge)
                    }
                } else {
                    Button {
                        isPickingRestaurant = true
                    } label: {
                        // ADD RESTAURANT
                        VStack {
                            Image(systemName: "plus.circle")
                                .resizable()
                                .foregroundColor(.black)
                                .frame(width: 80, height: 80, alignment: .center)
                            
                            Text("Add restaurant")
                                .foregroundColor(.black)
                            
                        }
                    }
                }
                
                if let restaurant = uploadViewModel.restaurant {
                    Text(restaurant.name)
                        .bold()
                        .font(.title3)
                    Text("\(restaurant.address ?? "") \(restaurant.city ?? ""), \(restaurant.state ?? "")")
                        .font(.subheadline)
                        .padding(.horizontal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text("\(restaurant.cuisine ?? ""), \(restaurant.price ?? "")")
                        .font(.subheadline)
                        .padding(.horizontal)
                    
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
                            Button(action: {
                                self.isEditingCaption = true
                            }) {
                                TextBox(text: $description, isEditing: $isEditingCaption, placeholder: "What's your review?", maxCharacters: 150)
                            }
                            
                            if !description.isEmpty, editedReview == true {
                                
                                NavigationLink(destination: AddMenuItemsReview(favoriteMenuItem: $favoriteMenuItem, favoriteMenuItems: $favoriteMenuItems)) {
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
                                        uploadViewModel.reset()
                                        tabBarController.selectedTab = 0
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
            
            if isEditingCaption {
                EditorView(text: $description, isEditing: $isEditingCaption, placeholder: "What's your review?", maxCharacters: 150, title: "Review")
                    .focused($isCaptionEditorFocused) // Connects the focus state to the editor view
                    .onAppear {
                        isCaptionEditorFocused = true // Automatically focuses the TextEditor when it appears
                    }
            }
            
        }
        .onChange(of: uploadViewModel.restaurant) {
            reviewViewModel.selectedRestaurant = uploadViewModel.restaurant
        }
        .onChange(of: description) {
            Debouncer(delay: 0.3).schedule{
                editedReview = true
            }
        }
        .navigationDestination(isPresented: $isPickingRestaurant) {
            SelectRestaurantListView(uploadViewModel: uploadViewModel)
                .navigationTitle("Select Restaurant")
        }
    }
}
#Preview {
    UploadWrittenReviewView(uploadViewModel: UploadViewModel())
}
