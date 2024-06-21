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
                            if let restaurantRequest = reviewViewModel.restaurantRequest {
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
                                            .font(.subheadline)
                                        VStack(alignment: .leading) {
                                            Text("Add Favorite Menu Items")
                                                .font(.subheadline)
                                                .foregroundStyle(.black)
                                            if !favoriteMenuItems.isEmpty {
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
