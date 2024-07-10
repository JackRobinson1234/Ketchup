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
    @Environment(\.dismiss) var dismiss
    private let characterLimit = 300
    @FocusState var isDescriptionFocused
    var overallRatingPercentage: Double {
        ((reviewViewModel.serviceRating + reviewViewModel.atmosphereRating + reviewViewModel.valueRating + reviewViewModel.foodRating) / 4) * 10
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                VStack {
                    if let restaurant = reviewViewModel.selectedRestaurant {
                        Button {
                            reviewViewModel.isPickingRestaurant = true
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
                                
                                if let cuisine = restaurant.categoryName, let price = restaurant.price {
                                    Text("\(cuisine), \(price)")
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .foregroundStyle(.primary)
                                } else if let cuisine = restaurant.categoryName {
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
                                if !reviewViewModel.setRestaurant {
                                    Text("Edit")
                                        .foregroundStyle(Color("Colors/AccentColor"))
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                }
                            }
                        }
                        .padding(.bottom)
                        .disabled(reviewViewModel.setRestaurant)
                    } else {
                        Button {
                            reviewViewModel.isPickingRestaurant = true
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
                    
                    VStack(spacing: 10) {
                        OverallRatingView(rating: overallRatingPercentage)
                        RatingSliderGroup(label: "Food", rating: $reviewViewModel.foodRating)
                        RatingSliderGroup(label: "Atmosphere", rating: $reviewViewModel.atmosphereRating)
                        RatingSliderGroup(label: "Value", rating: $reviewViewModel.valueRating)
                        RatingSliderGroup(label: "Service", rating: $reviewViewModel.serviceRating)
                    }
                    
                    VStack {
                        Button(action: {
                            reviewViewModel.isEditingDescription = true
                        }) {
                            TextBox(text: $reviewViewModel.description, isEditing: $reviewViewModel.isEditingDescription, placeholder: "Enter your Review...", maxCharacters: characterLimit)
                        }
                        .padding(.vertical)
                        
                        if reviewViewModel.showDetailsAlert {
                            Text("Please Select a Restaurant!")
                                .foregroundStyle(Color("Colors/AccentColor"))
                                .font(.custom("MuseoSansRounded-300", size: 10))
                                .onAppear {
                                    Debouncer(delay: 2.0).schedule { reviewViewModel.showDetailsAlert = false }
                                }
                        }
                        Button {
                            if reviewViewModel.selectedRestaurant == nil {
                                print("SHOULD SHOW ALERT")
                                reviewViewModel.showDetailsAlert = true
                                
                            } else {
                                Task {
                                    try await reviewViewModel.uploadReview(description: reviewViewModel.description, overallRating: overallRatingPercentage, serviceRating: reviewViewModel.serviceRating, atmosphereRating: reviewViewModel.atmosphereRating, valueRating: reviewViewModel.valueRating, foodRating: reviewViewModel.foodRating)
                                    reviewViewModel.showAlert = true
                                    reviewViewModel.reset()
                                }
                            }
                        } label: {
                            Text("Post Review")
                                .modifier(StandardButtonModifier())
                        }
                        .opacity(reviewViewModel.selectedRestaurant != nil ? 1 : 0.6)
                    }
                }
                .padding(.bottom, 100)
                .padding()
                .padding(.top, 50)
                
                if reviewViewModel.isEditingDescription {
                    EditorView(text: $reviewViewModel.description, isEditing: $reviewViewModel.isEditingDescription, placeholder: "Enter a Review...", maxCharacters: characterLimit, title: "Review")
                        .focused($isDescriptionFocused)
                        .onAppear {
                            isDescriptionFocused = true
                        }
                }
                
                if !reviewViewModel.changeTab {
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
            .alert(isPresented: $reviewViewModel.showDetailsAlert) {
                Alert(title: Text("Enter Details"), message: Text("Please Select a Restaurant"), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $reviewViewModel.showAlert) {
                Alert(
                    title: Text("Review Successful"),
                    message: Text("Your review has been posted."),
                    dismissButton: .default(Text("OK")) {
                        if reviewViewModel.changeTab {
                            tabBarController.selectedTab = 0
                        } else {
                            dismiss()
                        }
                    }
                )
            }
            .onChange(of: reviewViewModel.description) {
                Debouncer(delay: 0.3).schedule {
                    reviewViewModel.editedReview = true
                }
            }
            .sheet(isPresented: $reviewViewModel.isPickingRestaurant) {
                RestaurantReviewSelector(reviewsViewModel: reviewViewModel)
                    .navigationTitle("Select Restaurant")
            }
        }
    }
}
