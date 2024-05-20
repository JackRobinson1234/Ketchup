//
//  CreateReviewView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import SwiftUI
struct CreateReviewView: View {
    var restaurant: Restaurant
    @State var description: String = ""
    var maxCharacters = 150
    @State var recommend: Bool? = nil
    @State private var favoriteMenuItem: String = ""
    @State private var favoriteMenuItems: [String] = []
    @FocusState private var isTextFieldFocused: Bool
    private let maxMenuItemCharacters = 50
    private let maxFavoriteMenuItems = 5
    
    var body: some View {
        VStack{
            Spacer()
            if let profileImageUrl = restaurant.profileImageUrl {
                // Replace with actual image loading logic
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
            
            
            
            ZStack(alignment: .topLeading){
                TextField("What's your review?...", text: $description)
                    .font(.title3)
                    .background(Color.white)
                    .frame(height: 75)
                    .padding(.horizontal, 20)
                
            }
            .onChange(of: description) {
                if description.count > maxCharacters {
                    description = String(description.prefix(maxCharacters))
                }
            }
            
            
            HStack {
                Spacer()
                
                Text("\(maxCharacters - description.count) characters remaining")
                    .font(.caption)
                    .foregroundColor(description.count > maxCharacters ? .red : .gray)
                    .padding(.horizontal, 10)
            }
            .padding(20)
            Divider()
                .padding(.bottom, 20)
            if !favoriteMenuItems.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(favoriteMenuItems, id: \.self) { item in
                            HStack{
                                HStack {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.red)
                                        .onTapGesture {
                                            withAnimation(.snappy) {
                                               removeItem(item)
                                            }
                                        }
                                    Text(item)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 5)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
            }
            HStack {
                TextField("Add a favorite menu item... (Max 5)", text: $favoriteMenuItem, onCommit: {
                    addItem()
                })
                .focused($isTextFieldFocused)
                .frame(height:44)
                .padding(.horizontal)
                .font(.subheadline)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 1.0)
                        .foregroundStyle(Color(.systemGray4))
                )
                .onChange(of: favoriteMenuItem) {
                    if favoriteMenuItem.count > maxMenuItemCharacters {
                        favoriteMenuItem = String(favoriteMenuItem.prefix(maxMenuItemCharacters))
                    }
                }
                Button(action: addItem) {
                    Image(systemName:"plus")
                        .frame(height:44)
                        .foregroundColor(favoriteMenuItem.isEmpty ? .gray : .black)
                        .cornerRadius(5)
                    
                }
                .disabled(favoriteMenuItem.isEmpty || favoriteMenuItems.count >= maxFavoriteMenuItems)
                .padding(.horizontal)
            }
            .padding(.horizontal)
            Spacer()
            Spacer()
            Button{
                
            } label: {
                Text("Post Review")
                    .modifier(StandardButtonModifier())
                    
            }
            .opacity(canPostReview ? 1 : 0.5)
            .disabled(!canPostReview)
        }
    }
    private var canPostReview: Bool {
           return !description.isEmpty && recommend != nil
       }
    private func addItem() {
        guard !favoriteMenuItem.isEmpty else { return }
        favoriteMenuItems.append(favoriteMenuItem)
        favoriteMenuItem = ""
    }
    private func removeItem(_ item: String) {
           favoriteMenuItems.removeAll { $0 == item }
       }
}
#Preview {
    CreateReviewView(restaurant: DeveloperPreview.restaurants[0])
}
