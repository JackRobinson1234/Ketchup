//
//  ReelsUploadView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//

import SwiftUI
import AVKit
import AVFoundation

struct ReelsUploadView: View {
    // VIEW MODEL
    @ObservedObject var uploadViewModel: UploadViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    
    // SHOW POP UPS AND SELECTION VIEWS
    @FocusState private var isCaptionEditorFocused: Bool
    @State private var isEditingCaption = false
    @State var isPickingRestaurant = false
    @State var isAddingRecipe = false
    @State var titleText: String = ""
    private let maxCharacters = 25
    private let spacing: CGFloat = 20
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (spacing * 2)) / 3
    }
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @EnvironmentObject var tabBarController: TabBarController
    @State var pickingFavorites: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPickingRestaurant = true
                    } label: {
                        if uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.largeTitle) // Adjust the size as needed
                                    .foregroundColor(Color("Colors/AccentColor"))
                                Text("Add a restaurant")
                                    .foregroundColor(.primary)
                            }
                        } else if let restaurant = uploadViewModel.restaurant {
                            VStack {
                                RestaurantCircularProfileImageView(imageUrl: uploadViewModel.restaurant?.profileImageUrl, size: .xLarge)
                                Text(restaurant.name)
                                    .font(.custom("MuseoSansRounded-300", size: 20))
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
                                if let address = restaurant.address {
                                    Text(address)
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .foregroundStyle(.primary)
                                }
                                Text("Edit")
                                    .foregroundStyle(Color("Colors/AccentColor"))
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                            }
                        } else if let request = uploadViewModel.restaurantRequest {
                            VStack {
                                RestaurantCircularProfileImageView(size: .xLarge)
                                Text(request.name)
                                    .font(.custom("MuseoSansRounded-300", size: 20))
                                Text("\(request.city), \(request.state)")
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                                Text("(To be created)")
                                    .foregroundStyle(.gray)
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                                Text("Edit")
                                    .foregroundStyle(Color("Colors/AccentColor"))
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                            }
                        }
                    }
                    
                    Spacer()
                    if uploadViewModel.mediaType == "video" {
                        FinalVideoPreview(uploadViewModel: uploadViewModel)
                            .frame(width: width, height: 150) // Half of the original dimensions
                            .cornerRadius(5) // Adjusted corner radius to maintain proportionality
                    } else if uploadViewModel.mediaType == "photo" {
                        FinalPhotoPreview(uploadViewModel: uploadViewModel)
                            .frame(width: width, height: 150) // Half of the original dimensions
                            .cornerRadius(5) // Adjusted corner radius to maintain proportionality
                    } else {
                        Rectangle()
                            .frame(width: width, height: 150) // Half of the original dimensions
                            .cornerRadius(5) // Adjusted corner radius to maintain proportionality
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
                .padding(.vertical)
                
                Divider()
                
                VStack {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $uploadViewModel.caption)
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
                        if uploadViewModel.caption.isEmpty {
                            Text("Enter a caption...")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .foregroundColor(Color.gray)
                                .padding(.horizontal, 25)
                                .padding(.top, 8)
                        }
                    }
                    HStack {
                        Spacer()
                        Text("\(uploadViewModel.caption.count)/150")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                    }
                }
                .onChange(of: uploadViewModel.caption) {
                    if uploadViewModel.caption.count >= 150 {
                        uploadViewModel.caption = String(uploadViewModel.caption.prefix(150))
                    }
                }
                
                Divider()
                
//                Button {
//                    pickingFavorites = true
//                } label: {
//                    HStack {
//                        Image(systemName: "fork.knife.circle")
//                            .foregroundStyle(.black)
//                            .font(.custom("MuseoSansRounded-300", size: 16))
//                        VStack(alignment: .leading) {
//                            Text("Add Favorite Menu Items")
//                                .font(.custom("MuseoSansRounded-300", size: 16))
//                                .foregroundStyle(.black)
//                            if !uploadViewModel.favoriteMenuItems.isEmpty {
//                                Text("\(uploadViewModel.favoriteMenuItems.count) items selected")
//                                    .font(.custom("MuseoSansRounded-300", size: 10))
//                                    .foregroundStyle(.gray)
//                            }
//                        }
//                        Spacer()
//                        Image(systemName: "chevron.right")
//                            .foregroundStyle(.black)
//                    }
//                    
//                }
//                .padding(20)
//                
//                Divider()
                
                VStack(spacing: 20) {
                    HStack {
                        Text("Overall")
                            .font(.custom("MuseoSansRounded-300", size: 18))
                        Spacer()
                        RatingButtonGroup(rating: $uploadViewModel.overallRating)
                    }
                    
                    HStack {
                        Text("Service")
                            .font(.custom("MuseoSansRounded-300", size: 18))
                        Spacer()
                        RatingButtonGroup(rating: $uploadViewModel.serviceRating)
                    }
                    
                    HStack {
                        Text("Atmosphere")
                            .font(.custom("MuseoSansRounded-300", size: 18))
                        Spacer()
                        RatingButtonGroup(rating: $uploadViewModel.atmosphereRating)
                    }
                    
                    HStack {
                        Text("Value")
                            .font(.custom("MuseoSansRounded-300", size: 18))
                        Spacer()
                        RatingButtonGroup(rating: $uploadViewModel.valueRating)
                    }
                    
                    HStack {
                        Text("Food")
                            .font(.custom("MuseoSansRounded-300", size: 18))
                        Spacer()
                        RatingButtonGroup(rating: $uploadViewModel.foodRating)
                    }
                }
                
                Divider()
                
                Spacer()
                
                Button {
                    if (uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil) {
                        alertMessage = "Please select a restaurant."
                        showAlert = true
                    } else {
                        Task {
                            await uploadViewModel.uploadPost()
                            uploadViewModel.reset()
                            cameraViewModel.reset()
                            tabBarController.selectedTab = 0
                        }
                    }
                } label: {
                    Text(uploadViewModel.isLoading ? "" : "Post")
                        .modifier(StandardButtonModifier(width: 90))
                        .overlay {
                            if uploadViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                }
                .opacity((uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil) ? 0.5 : 1.0)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Enter Details"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
          
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .preferredColorScheme(.light)
        .onTapGesture {
            dismissKeyboard()
        }
        .gesture(
            DragGesture().onChanged { value in
                if value.translation.height > 50 {
                    dismissKeyboard()
                }
            }
        )
        .navigationDestination(isPresented: $isPickingRestaurant) {
            SelectRestaurantListView(uploadViewModel: uploadViewModel)
                .navigationTitle("Select Restaurant")
        }
        .sheet(isPresented: $pickingFavorites) {
            NavigationView {
                AddMenuItemsReview(favoriteMenuItems: $uploadViewModel.favoriteMenuItems)
            }
            .presentationDetents([.height(UIScreen.main.bounds.height * 0.33)])
        }
    }
}

struct RatingButtonGroup: View {
    @Binding var rating: Rating
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<5, id: \.self) { number in
                RatingButton(ratingValue: number, isActive: rating.rawValue == number) {
                    if let value = Rating(rawValue: number){
                        rating = value
                    }
                }
            }
        }
    }
}

struct RatingButton: View {
    var ratingValue: Int
    var isActive: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Rating.image(forValue: ratingValue)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28) // Adjust size as needed
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isActive ? Color("Colors/AccentColor") : Color.clear, lineWidth: 1)
                )
        }
    }
}

func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
