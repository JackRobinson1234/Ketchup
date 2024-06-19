//
//  CreateReviewView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import SwiftUI
import SwiftUI
struct CreateReviewView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ReviewsViewModel
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
    var restaurant: Restaurant?
    private var canPostReview: Bool {
        return !description.isEmpty && recommend != nil
    }
    
    var body: some View {
        //NavigationStack{
        if let restaurant = restaurant ?? viewModel.selectedRestaurant {
            ZStack{
                VStack{
                    if let profileImageUrl = restaurant.profileImageUrl {
                        RestaurantCircularProfileImageView(imageUrl: profileImageUrl, size: .xLarge)
                    }
                   
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
                                Spacer()
                                Button{
                                    viewModel.selectedRestaurant = restaurant
                                    Task{
                                        if let recommend {
                                            try await viewModel.uploadReview(description: description, recommends: recommend, favorites: favoriteMenuItems)
                                        }
                                        dismiss()
                                        dismiss()
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
            
            .onChange(of: description) {
                Debouncer(delay: 0.3).schedule{
                    editedReview = true
                }
            }
            .modifier(BackButtonModifier())
            .navigationBarBackButtonHidden()
        }
    }
}
#Preview {
    CreateReviewView(viewModel: ReviewsViewModel(restaurant: DeveloperPreview.restaurants[0]))
}
