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
    @State var overallRating: Rating = .three
    @State var serviceRating: Rating = .three
    @State var atmosphereRating: Rating = .three
    @State var valueRating: Rating = .three
    @State var foodRating: Rating = .three
    @State private var favoriteMenuItem: String = ""
    @State private var favoriteMenuItems: [String] = []
    @State private var isEditingCaption = false
    @FocusState private var isCaptionEditorFocused: Bool
    @State var editedReview = false
    @State var isPickingRestaurant = false
    @State var setRestaurant = false
    private var canPostReview: Bool {
        return !description.isEmpty
    }
    @Environment(\.dismiss) var dismiss
    @State var changeTab: Bool = false
    @State var pickingFavorites: Bool = false
    @State private var showAlert = false
    private let characterLimit = 300
    @State private var isEditingDescription = false
    @FocusState private var isDescriptionFocused: Bool
    @State var showDetailsAlert = false
    
    var body: some View {
        ScrollView {
            ZStack {
                VStack {
                    if let restaurant = reviewViewModel.selectedRestaurant {
                        Button {
                            isPickingRestaurant = true
                        } label: {
                            VStack {
                                RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .xLarge)
                                Text(restaurant.name)
                                    .bold()
                                    .font(.custom("MuseoSansRounded-300", size: 18))
                                Text("\(restaurant.address ?? "") \(restaurant.city ?? ""), \(restaurant.state ?? "")")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .padding(.horizontal)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                
                                if let cuisine = restaurant.cuisine, let price = restaurant.price {
                                    Text("\(cuisine), \(price)")
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .foregroundStyle(.primary)
                                } else if let cuisine = restaurant.cuisine {
                                    Text(cuisine)
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .foregroundStyle(.primary)
                                } else if let price = restaurant.price {
                                    Text(price)
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .foregroundStyle(.primary)
                                }
                                if reviewViewModel.restaurantRequest != nil {
                                    Text("To be Created")
                                        .foregroundStyle(.primary)
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                }
                                if !setRestaurant {
                                    Text("Edit")
                                        .foregroundStyle(Color("Colors/AccentColor"))
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                }
                            }
                        }
                        .padding(.bottom)
                        .disabled(setRestaurant)
                    } else {
                        Button {
                            isPickingRestaurant = true
                        } label: {
                            VStack {
                                Image(systemName: "plus")
                                    .resizable()
                                    .foregroundColor(Color("Colors/AccentColor"))
                                    .frame(width: 40, height: 40, alignment: .center)
                                
                                Text("Add restaurant")
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.bottom)
                    }
                    
                    VStack(spacing: 20) {
                        HStack {
                            Text("Overall")
                                .font(.custom("MuseoSansRounded-300", size: 18))
                            Spacer()
                            RatingButtonGroup(rating: $overallRating)
                        }
                        
                        HStack {
                            Text("Service")
                                .font(.custom("MuseoSansRounded-300", size: 18))
                            Spacer()
                            RatingButtonGroup(rating: $serviceRating)
                        }
                        
                        HStack {
                            Text("Atmosphere")
                                .font(.custom("MuseoSansRounded-300", size: 18))
                            Spacer()
                            RatingButtonGroup(rating: $atmosphereRating)
                        }
                        
                        HStack {
                            Text("Value")
                                .font(.custom("MuseoSansRounded-300", size: 18))
                            Spacer()
                            RatingButtonGroup(rating: $valueRating)
                        }
                        
                        HStack {
                            Text("Food")
                                .font(.custom("MuseoSansRounded-300", size: 18))
                            Spacer()
                            RatingButtonGroup(rating: $foodRating)
                        }
                    }
                    .padding(20)
                    
                    VStack {
                        Button(action: {
                            self.isEditingDescription = true
                        }) {
                            TextBox(text: $description, isEditing: $isEditingDescription, placeholder: "Enter your Review...*", maxCharacters: characterLimit)
                        }
                        .padding(.vertical)
                        
//                        Button {
//                            pickingFavorites = true
//                        } label: {
//                            HStack {
//                                Image(systemName: "fork.knife.circle")
//                                    .foregroundStyle(.black)
//                                    .font(.custom("MuseoSansRounded-300", size: 16))
//                                VStack(alignment: .leading) {
//                                    Text("Add Favorite Menu Items")
//                                        .font(.custom("MuseoSansRounded-300", size: 16))
//                                        .foregroundStyle(.black)
//                                    if !favoriteMenuItems.isEmpty {
//                                        Text("\(favoriteMenuItems.count) items selected")
//                                            .font(.custom("MuseoSansRounded-300", size: 10))
//                                            .foregroundStyle(.gray)
//                                    }
//                                }
//                                Spacer()
//                                Image(systemName: "chevron.right")
//                                    .foregroundStyle(.black)
//                            }
//                            .padding()
//                        }
//                        Divider()
                        
                        Button {
                            if description.isEmpty {
                                showDetailsAlert = true
                            } else {
                                Task {
                                    try await reviewViewModel.uploadReview(description: description, overallRating: overallRating, serviceRating: serviceRating, atmosphereRating: atmosphereRating, valueRating: valueRating, foodRating: foodRating, favorites: favoriteMenuItems)
                                    showAlert = true
                                }
                            }
                        } label: {
                            Text("Post Review")
                                .modifier(StandardButtonModifier())
                        }
                        .opacity(canPostReview ? 1 : 0.6)
                    }
                }
                
                .padding()
                .padding(.top, 50)
                
                if isEditingDescription {
                    EditorView(text: $description, isEditing: $isEditingDescription, placeholder: "Enter a Review...", maxCharacters: characterLimit, title: "Review")
                        .focused($isDescriptionFocused)
                        .onAppear {
                            isDescriptionFocused = true
                        }
                }
                
                if !changeTab {
                    VStack {
                        HStack {
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
            .alert(isPresented: $showDetailsAlert) {
                Alert(title: Text("Enter Details"), message: Text("Please type your review"), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Review Successful"),
                    message: Text("Your review has been posted."),
                    dismissButton: .default(Text("OK")) {
                        if changeTab {
                            tabBarController.selectedTab = 0
                        } else {
                            dismiss()
                        }
                    }
                )
            }
            .sheet(isPresented: $pickingFavorites) {
                NavigationView {
                    AddMenuItemsReview(favoriteMenuItems: $favoriteMenuItems)
                }
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.33)])
            }
            .onChange(of: description) {
                Debouncer(delay: 0.3).schedule {
                    editedReview = true
                }
            }
            .sheet(isPresented: $isPickingRestaurant) {
                RestaurantReviewSelector(reviewsViewModel: reviewViewModel)
                    .navigationTitle("Select Restaurant")
            }
        }
    }
}
