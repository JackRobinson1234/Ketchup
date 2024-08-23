//
//  TaggedUsersSheet.swift
//  Ketchup
//
//  Created by Joe Ciminelli on 7/13/24.
//
import Foundation
import SwiftUI
import Kingfisher

struct TaggedUsersSheetView: View {
    var taggedUsers: [PostUser]
    @State private var selectedUser: PostUser? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Went With")
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .bold()
                    .padding()
                
                Divider()
                
                List(taggedUsers) { user in
                    TaggedUserRow(user: user, selectedUser: $selectedUser)
                }
                .listStyle(PlainListStyle()) // Ensures the List does not have any background
                .background(Color.clear) // Makes sure the List's background is clear
            }
            .background(Color.clear) // Ensures the VStack's background is clear
            .fullScreenCover(item: $selectedUser) { user in
                NavigationStack {
                    ProfileView(uid: user.id)
                }
            }
        }
    }
}

struct TaggedUserRow: View {
    var user: PostUser
    @Binding var selectedUser: PostUser?
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                selectedUser = user
            }) {
                UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .small)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Button(action: {
                    selectedUser = user
                }) {
                    Text(user.fullname)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                        .foregroundStyle(.black)
                }
                
                Text("@\(user.username)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color.clear) // Ensures the row's background is clear
        .contentShape(Rectangle()) // Ensures the entire row is tappable
    }
}
