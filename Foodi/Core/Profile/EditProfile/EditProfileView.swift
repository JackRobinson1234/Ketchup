//
//  EditProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Kingfisher
import PhotosUI

struct EditProfileView: View {
    @State private var username = ""
    @StateObject private var editProfileViewModel: EditProfileViewModel
    @Binding var user: User
    @Environment(\.dismiss) var dismiss
    //@State var favoritesPreview: [FavoriteRestaurant]
    
    init(user: Binding<User>) {
        self._user = user
        self._username = State(initialValue: _user.wrappedValue.username)
        //self._favoritesPreview = State(initialValue: _user.wrappedValue.favorites)
        self._editProfileViewModel = StateObject(wrappedValue: EditProfileViewModel(user: user.wrappedValue))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 8) {
                    Divider()
                    PhotosPicker(selection: $editProfileViewModel.selectedImage) {
                            VStack {
                                if let image = editProfileViewModel.profileImage {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(Circle())
                                        .foregroundColor(Color(.systemGray4))
                                } else {
                                    UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .large)
                                }
                                Text("Edit profile picture")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 8)
                    
                    Divider()
                }
                .padding(.bottom, 4)
                
                VStack {
                    EditProfileRowView(title: "Username", placeholder: "Enter your username..", text: $editProfileViewModel.username)
                    EditProfileRowView(title: "Name", placeholder: "Enter your name..", text: $editProfileViewModel.fullname)
                    EditProfileRowView(title: "Bio", placeholder: "Enter your bio..", text: $editProfileViewModel.bio)
                    editFavoritesView(user: user, editProfileViewModel: editProfileViewModel)
                }
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.subheadline)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Task {
                            try await editProfileViewModel.updateUserData()
                            dismiss()
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .onReceive(editProfileViewModel.$user, perform: { user in
                self.user = user
            })
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
        }

    }
}

struct EditProfileRowView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        
        HStack {
            Text(title)
                .padding(.leading, 8)
                .frame(width: 100, alignment: .leading)
                            
            VStack {
                TextField(placeholder, text: $text)
                
                Divider()
            }
        }
        .font(.subheadline)
        .frame(height: 36)
    }
}

#Preview {
    EditProfileView(user: .constant(DeveloperPreview.user))
}

struct editFavoritesView: View {
    let user: User
    let restaurantService: RestaurantService = RestaurantService()
    @State private var fetchedRestaurant: Restaurant?
    @State private var isEditFavoritesShowing = false
    @State var oldSelection: FavoriteRestaurant = FavoriteRestaurant(name: "", id: "", restaurantProfileImageUrl: nil)
    @ObservedObject var editProfileViewModel: EditProfileViewModel
    var body: some View {
        HStack(alignment: .top, spacing: 8){
            Spacer()
            ForEach(editProfileViewModel.favoritesPreview) { favoriteRestaurant in
                VStack (spacing:10){
                    Button{
                        oldSelection = favoriteRestaurant
                        isEditFavoritesShowing.toggle()
                    } label: {
                        VStack{
                            Text("Edit")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            HStack{
                                VStack {
                                    ZStack(alignment: .bottom) {
                                        if let imageUrl = favoriteRestaurant.restaurantProfileImageUrl {
                                            RestaurantCircularProfileImageView(imageUrl: imageUrl, size: .medium)
                                        }
                                    }
                                    Text(favoriteRestaurant.name)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .center) // Limit the width
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                            }
                        }
                    }
                    if !favoriteRestaurant.name.isEmpty{
                        Button{
                            oldSelection = favoriteRestaurant
                            if let index = editProfileViewModel.favoritesPreview.firstIndex(of: oldSelection) {
                                editProfileViewModel.favoritesPreview[index] = FavoriteRestaurant(name: "", id: "", restaurantProfileImageUrl: "")
                            }
                        } label: {
                            VStack{
                                Text("Clear")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                            }
                        }
                    }
                }

                Spacer()
                    
                }
            }
        .sheet(isPresented: $isEditFavoritesShowing) { FavoriteRestaurantSearchView(oldSelection: $oldSelection, editProfileViewModel: editProfileViewModel)}
    }
}
