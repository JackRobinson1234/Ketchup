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
    @State var recommend: Bool? = nil
    @State var serviceRating: Bool?
    @State var atmosphereRating: Bool?
    @State var valueRating: Bool?
    @State var foodRating: Bool?
    @State private var favoriteMenuItem: String = ""
    @State private var favoriteMenuItems: [String] = []
    @State private var isEditingCaption = false
    @FocusState private var isCaptionEditorFocused: Bool
    @State var editedReview = false
    @State var isPickingRestaurant = false
    @State var setRestaurant = false
    private var canPostReview: Bool {
        return !description.isEmpty && recommend != nil
    }
    @Environment(\.dismiss) var dismiss
    @State var changeTab: Bool = false
    @State var pickingFavorites: Bool = false
    @State private var showAlert = false
    private let characterLimit = 300
    @State private var isEditingDescription = false
    @FocusState private var isDescriptionFocused: Bool
    var body: some View {
        ZStack {
            Color.white
                .frame(width: UIScreen.main.bounds.width, height: 765)
                .cornerRadius(10)
            
            VStack {
                if let restaurant = reviewViewModel.selectedRestaurant {
                    Button {
                        isPickingRestaurant = true
                    } label: {
                        VStack {
                            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .xLarge)
                            
                            Text(restaurant.name)
                                .bold()
                                .font(.custom("MuseoSans-500", size: 18))
                            Text("\(restaurant.address ?? "") \(restaurant.city ?? ""), \(restaurant.state ?? "")")
                                .font(.custom("MuseoSans-500", size: 16))
                                .padding(.horizontal)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            
                            if let cuisine = restaurant.cuisine, let price = restaurant.price {
                                Text("\(cuisine), \(price)")
                                    .font(.custom("MuseoSans-500", size: 12))
                                    .foregroundStyle(.primary)
                            } else if let cuisine = restaurant.cuisine {
                                Text(cuisine)
                                    .font(.custom("MuseoSans-500", size: 12))
                                    .foregroundStyle(.primary)
                            } else if let price = restaurant.price {
                                Text(price)
                                    .font(.custom("MuseoSans-500", size: 12))
                                    .foregroundStyle(.primary)
                            }
                            if let restaurantRequest = reviewViewModel.restaurantRequest {
                                Text("To be Created")
                                    .foregroundStyle(.primary)
                                    .font(.custom("MuseoSans-500", size: 12))
                            }
                            if !setRestaurant {
                                Text("Edit")
                                    .foregroundStyle(Color("Colors/AccentColor"))
                                    .font(.custom("MuseoSans-500", size: 12))
                            }
                        }
                    }
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
                }
                
                if let restaurant = reviewViewModel.selectedRestaurant {
                    
                    HStack(spacing: 20) {
                        Button(action: { recommend = true }) {
                            VStack {
                                Image(systemName: "heart")
                                    .foregroundColor(recommend == true ? Color("Colors/AccentColor") : .gray)
                                    .font(.custom("MuseoSans-500", size: 20))
                                Text("Recommend")
                                    .font(.custom("MuseoSans-500", size: 12))
                                    .foregroundStyle(recommend == true ? Color("Colors/AccentColor") : .gray)
                            }
                        }
                        
                        Button(action: { recommend = false }) {
                            VStack {
                                HStack(spacing: 20) {
                                    RatingButton(title: "Recommend", systemImage: "heart", isActive: recommend == true) {
                                        recommend = true
                                    }
                                    RatingButton(title: "Don't Recommend", systemImage: "heart.slash", isActive: recommend == false) {
                                        recommend = false
                                    }
                                }
                            }
                            
                            HStack {
                                Text("Service")
                                    .font(.custom("MuseoSans-500", size: 18))
                                Spacer()
                                HStack(spacing: 20) {
                                    RatingButton(title: "Service", systemImage: "heart", isActive: serviceRating == true) {
                                       serviceRating = true
                                    }
                                    RatingButton(title: "No Service", systemImage: "heart.slash", isActive: serviceRating == false) {
                                        serviceRating = false
                                    }
                                }
                            }
                            
                            HStack {
                                Text("Atmosphere")
                                    .font(.custom("MuseoSans-500", size: 18))
                                Spacer()
                                HStack(spacing: 20) {
                                    RatingButton(title: "Atmosphere", systemImage: "heart", isActive: atmosphereRating == true) {
                                        atmosphereRating = true
                                    }
                                    RatingButton(title: "No Atmosphere", systemImage: "heart.slash", isActive: atmosphereRating == false) {
                                        atmosphereRating = false
                                    }
                                }
                            }
                            
                            HStack {
                                Text("Value")
                                    .font(.custom("MuseoSans-500", size: 18))
                                Spacer()
                                HStack(spacing: 20) {
                                    RatingButton(title: "Value", systemImage: "heart", isActive: valueRating == true) {
                                        valueRating = true
                                    }
                                    RatingButton(title: "No Value", systemImage: "heart.slash", isActive: valueRating == false) {
                                        valueRating = false
                                    }
                                }
                            }
                            
                            HStack {
                                Text("Food")
                                    .font(.custom("MuseoSans-500", size: 18))
                                Spacer()
                                HStack(spacing: 20) {
                                    RatingButton(title: "Food", systemImage: "heart", isActive: foodRating == true) {
                                        foodRating = true
                                    }
                                    RatingButton(title: "No Food", systemImage: "heart.slash", isActive: foodRating == false) {
                                        foodRating = false
                                    }
                                }
                            
                            }
                        }
                    }
                    .padding(20)
                    if recommend != nil {
                        VStack {
                            
                                Button(action: {
                                    self.isEditingDescription = true
                                }) {
                                    TextBox(text: $description, isEditing: $isEditingDescription, placeholder: "Enter your Review...*", maxCharacters: characterLimit)
                                }
                                .padding(.vertical)
                            
                            
                            if !description.isEmpty, editedReview == true {
                                Button {
                                    pickingFavorites = true
                                } label: {
                                    HStack {
                                        Image(systemName: "fork.knife.circle")
                                            .foregroundStyle(.black)
                                            .font(.custom("MuseoSans-500", size: 16))
                                        VStack(alignment: .leading) {
                                            Text("Add Favorite Menu Items")
                                                .font(.custom("MuseoSans-500", size: 16))
                                                .foregroundStyle(.black)
                                            if !favoriteMenuItems.isEmpty {
                                                Text("\(favoriteMenuItems.count) items selected")
                                                    .font(.custom("MuseoSans-500", size: 10))
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
                                
                                Button {
                                    Task {
                                        if let recommend {
                                            try await reviewViewModel.uploadReview(description: description, recommends: recommend, favorites: favoriteMenuItems)
                                            showAlert = true
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
            if isEditingDescription {
                EditorView(text: $description, isEditing: $isEditingDescription, placeholder: "Enter a Review...", maxCharacters: characterLimit, title: "Review")
                    .focused($isDescriptionFocused) // Connects the focus state to the editor view
                    .onAppear {
                        isDescriptionFocused = true // Automatically focuses the TextEditor when it appears
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

import Combine
@Observable
final class KeyboardToolbarViewModel {
    var isKeyboardVisible = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] _ in
                withAnimation(.easeIn.delay(0.15)) {
                    self?.isKeyboardVisible = true
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.isKeyboardVisible = false
            }
            .store(in: &cancellables)
    }
}

class Router: ObservableObject {
    @Published var path = NavigationPath()

    func reset() {
      path = NavigationPath()
    }
}
