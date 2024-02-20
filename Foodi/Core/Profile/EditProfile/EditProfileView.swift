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
    @StateObject private var viewModel: EditProfileViewModel
    @Binding var user: User
    @Environment(\.dismiss) var dismiss
    @State var favoritesPreview: [FavoriteRestaurant]
    
    init(user: Binding<User>) {
        self._user = user
        self._viewModel = StateObject(wrappedValue: EditProfileViewModel(user: user.wrappedValue))
        self._username = State(initialValue: _user.wrappedValue.username)
        self._favoritesPreview = State(initialValue: _user.wrappedValue.favorites)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 8) {
                    Divider()
                    
                    PhotosPicker(selection: $viewModel.selectedImage) {
                            VStack {
                                if let image = viewModel.profileImage {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(Circle())
                                        .foregroundColor(Color(.systemGray4))
                                } else {
                                    UserCircularProfileImageView(user: user, size: .large)
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
                    EditProfileRowView(title: "Username", placeholder: "Enter your username..", text: $viewModel.username)
                    EditProfileRowView(title: "Name", placeholder: "Enter your name..", text: $viewModel.fullname)
                    EditProfileRowView(title: "Bio", placeholder: "Enter your bio..", text: $viewModel.bio)
                    FavoriteRestaurantsView(user: user, favoriteRestaurantViewEnum: .editProfile, favorites: favoritesPreview)
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
                            try await viewModel.updateUserData()
                            dismiss()
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .onReceive(viewModel.$user, perform: { user in
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
