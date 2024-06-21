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
    //@State var showPostTypeMenu: Bool = true
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
        ScrollView{
            ZStack {
                VStack {
                    HStack{
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
                                        .font(.title)
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
                                    if let address = restaurant.address {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                    }
                                    Text("Edit")
                                        .foregroundStyle(Color("Colors/AccentColor"))
                                        .font(.caption)
                                }
                            } else if let request = uploadViewModel.restaurantRequest {
                                VStack {
                                    RestaurantCircularProfileImageView(size: .xLarge)
                                    Text(request.name)
                                        .font(.title)
                                    Text("\(request.city), \(request.state)")
                                        .font(.caption)
                                    Text("(To be created)")
                                        .foregroundStyle(.gray)
                                        .font(.footnote)
                                    Text("Edit")
                                        .foregroundStyle(Color("Colors/AccentColor"))
                                        .font(.caption)
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
                                .font(.subheadline)
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
                                    .font(.subheadline)
                                    .foregroundColor(Color.gray)
                                    .padding(.horizontal, 25)
                                    .padding(.top, 8)
                            }
                        }
                        HStack {
                            Spacer()
                            Text("\(uploadViewModel.caption.count)/150")
                                .font(.caption)
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
                    
                    VStack(spacing: 20) {
                        HStack {
                            Text("Recommendation")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 20) {
                                RatingButton(title: "Recommend", systemImage: "heart", isActive: uploadViewModel.recommend == true) {
                                    uploadViewModel.recommend = true
                                }
                                RatingButton(title: "Don't Recommend", systemImage: "heart.slash", isActive: uploadViewModel.recommend == false) {
                                    uploadViewModel.recommend = false
                                }
                            }
                        }
                        
                        HStack {
                            Text("Service")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 20) {
                                RatingButton(title: "Service", systemImage: "heart", isActive: uploadViewModel.serviceRating == true) {
                                    uploadViewModel.serviceRating = true
                                }
                                RatingButton(title: "No Service", systemImage: "heart.slash", isActive: uploadViewModel.serviceRating == false) {
                                    uploadViewModel.serviceRating = false
                                }
                            }
                        }
                        
                        HStack {
                            Text("Atmosphere")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 20) {
                                RatingButton(title: "Atmosphere", systemImage: "heart", isActive: uploadViewModel.atmosphereRating == true) {
                                    uploadViewModel.atmosphereRating = true
                                }
                                RatingButton(title: "No Atmosphere", systemImage: "heart.slash", isActive: uploadViewModel.atmosphereRating == false) {
                                    uploadViewModel.atmosphereRating = false
                                }
                            }
                        }
                        
                        HStack {
                            Text("Value")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 20) {
                                RatingButton(title: "Value", systemImage: "heart", isActive: uploadViewModel.valueRating == true) {
                                    uploadViewModel.valueRating = true
                                }
                                RatingButton(title: "No Value", systemImage: "heart.slash", isActive: uploadViewModel.valueRating == false) {
                                    uploadViewModel.valueRating = false
                                }
                            }
                        }
                        
                        HStack {
                            Text("Food")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 20) {
                                RatingButton(title: "Food", systemImage: "heart", isActive: uploadViewModel.foodRating == true) {
                                    uploadViewModel.foodRating = true
                                }
                                RatingButton(title: "No Food", systemImage: "heart.slash", isActive: uploadViewModel.foodRating == false) {
                                    uploadViewModel.foodRating = false
                                }
                            }
                        }
                    }
                    Divider()
                    Button {
                        pickingFavorites = true
                    } label: {
                        HStack {
                            Image(systemName: "fork.knife.circle")
                                .foregroundStyle(.black)
                                .font(.subheadline)
                            VStack(alignment: .leading) {
                                Text("Add Favorite Menu Items")
                                    .font(.subheadline)
                                    .foregroundStyle(.black)
                                if !uploadViewModel.favoriteMenuItems.isEmpty {
                                    Text("\(uploadViewModel.favoriteMenuItems.count) items selected")
                                        .font(.footnote)
                                        .foregroundStyle(.gray)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.black)
                        }
                        
                    }
                    .padding(20)
                    Divider()
                    Spacer()
                    Button {
                        if uploadViewModel.postType == .cooking && titleText.isEmpty {
                            alertMessage = "Please add a title for your post."
                            showAlert = true
                        } else if uploadViewModel.postType == .dining && (uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil) {
                            alertMessage = "Please select a restaurant."
                            showAlert = true
                        } else {
                            Task {
                                if uploadViewModel.postType == .cooking {
                                    uploadViewModel.recipeTitle = titleText
                                }
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
                    .opacity(uploadViewModel.postType == .cooking && titleText.isEmpty ? 0.5 : 1.0)
                    .opacity(uploadViewModel.postType == .dining && (uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil) ? 0.5 : 1.0)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Enter Details"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                }
                .padding()
            }
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

struct RatingButton: View {
    var title: String
    var systemImage: String
    var isActive: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImage)
                    .foregroundColor(isActive ? Color("Colors/AccentColor") : .gray)
                    .font(.title)
//                Text(title)
//                    .font(.caption)
//                    .foregroundStyle(isActive ? Color("Colors/AccentColor") : .gray)
            }
        }
    }
}
func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
