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
    
    @State private var isTaggingUsers = false
    
    var overallRatingPercentage: Double {
        ((reviewViewModel.serviceRating + reviewViewModel.atmosphereRating + reviewViewModel.valueRating + reviewViewModel.foodRating) / 4)
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
                    
                    Divider()
                    
                    VStack {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $reviewViewModel.description)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .frame(height: 75)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .cornerRadius(5)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            dismissKeyboard()
                                        }
                                    }
                                }
                                .onChange(of: reviewViewModel.description) {
                                    reviewViewModel.checkForMentioning()
                                }
                            if reviewViewModel.description.isEmpty {
                                Text("Enter a caption...")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundColor(Color.gray)
                                    .padding(.horizontal, 25)
                                    .padding(.top, 8)
                            }
                        }
                        HStack {
                            Spacer()
                            Text("\(reviewViewModel.description.count)/300")
                                .font(.custom("MuseoSansRounded-300", size: 10))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 10)
                        }
                    }
                    .onChange(of: reviewViewModel.description) {
                        if reviewViewModel.description.count >= 300 {
                            reviewViewModel.description = String(reviewViewModel.description.prefix(300))
                        }
                        reviewViewModel.checkForMentioning()
                    }
                    
                    if reviewViewModel.isMentioning {
                        ForEach(reviewViewModel.filteredMentionedUsers, id: \.id) { user in
                            Button(action: {
                                let username = user.username
                                var words = reviewViewModel.description.split(separator: " ").map(String.init)
                                words.removeLast()
                                words.append("@" + username)
                                reviewViewModel.description = words.joined(separator: " ") + " "
                                reviewViewModel.isMentioning = false
                            }) {
                                HStack {
                                    UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .small)
                                    Text(user.username)
                                        .font(.custom("MuseoSansRounded-300", size: 14))
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    Divider()
                    
                    VStack(spacing: 10) {
                        OverallRatingView(rating: overallRatingPercentage)
                        RatingSliderGroup(label: "Food", rating: $reviewViewModel.foodRating)
                        RatingSliderGroup(label: "Atmosphere", rating: $reviewViewModel.atmosphereRating)
                        RatingSliderGroup(label: "Value", rating: $reviewViewModel.valueRating)
                        RatingSliderGroup(label: "Service", rating: $reviewViewModel.serviceRating)
                    }
                    
                    Divider()
                    
                    
                        
                    
                    
//                    if uploadViewModel.caption.isEmpty {
//                        Text("Enter a caption...")
//                            .font(.custom("MuseoSansRounded-300", size: 16))
//                            .foregroundColor(Color.gray)
//                            .padding(.horizontal, 25)
//                            .padding(.top, 8)
//                    }
                    
                    
                    Button {
                        isTaggingUsers = true
                    } label: {
                        HStack {
                            Text("Went with anyone?")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .foregroundColor(.black)
                                .frame(alignment: .trailing)
                            
                            Spacer()
                            if reviewViewModel.taggedUsers.isEmpty {
                                Image(systemName: "chevron.right")
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(Color("Colors/AccentColor"))
                                    .padding(.trailing, 10)
                            } else {
                                HStack {
                                    Text("\(reviewViewModel.taggedUsers.count) people")
                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                        .foregroundColor(.black)
                                    
                                    Image(systemName: "chevron.right")
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(Color("Colors/AccentColor"))
                                }
                                .padding(.trailing, 10)
                            }
                        }
                    }
                    
                    Divider()
                    
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
                .padding(.bottom, 100)
                .padding()
                .padding(.top, 50)
                
//                if reviewViewModel.isEditingDescription {
//                    EditorView(text: $reviewViewModel.description, isEditing: $reviewViewModel.isEditingDescription, placeholder: "Enter a Review...", maxCharacters: characterLimit, title: "Review")
//                        .focused($isDescriptionFocused)
//                        .onAppear {
//                            isDescriptionFocused = true
//                        }
//                }
                
            }
            .alert(isPresented: $reviewViewModel.showDetailsAlert) {
                Alert(title: Text("Enter Details"), message: Text("Please Select a Restaurant"), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $reviewViewModel.showAlert) {
                Alert(
                    title: Text("Review Successful"),
                    message: Text("Your review has been posted."),
                    dismissButton: .default(Text("OK")) {
                            tabBarController.selectedTab = 0
                    }
                )
            }
//            .onChange(of: reviewViewModel.description) {
//                Debouncer(delay: 0.3).schedule {
//                    reviewViewModel.editedReview = true
//                }
//                    reviewViewModel.checkForMentioning()
//            }
            .sheet(isPresented: $reviewViewModel.isPickingRestaurant) {
                RestaurantReviewSelector(reviewsViewModel: reviewViewModel)
                    .navigationTitle("Select Restaurant")
            }
//            .navigationDestination(isPresented: $isTaggingUsers) {
//                SelectFollowingWrittenView(reviewViewModel: reviewViewModel)
//                    .navigationTitle("Tag Users")
//            }
        }
    }
}
