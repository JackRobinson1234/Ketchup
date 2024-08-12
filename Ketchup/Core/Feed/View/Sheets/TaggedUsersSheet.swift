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
                    Button {
                        selectedUser = user
                    } label: {
                        HStack(spacing: 12) {
                            UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .medium)
                            
                            VStack(alignment: .leading) {
                                Text("@\(user.username)")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.black)
                                Text(user.fullname)
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                                    .foregroundStyle(.black)
                            }
                            .foregroundStyle(.black)
                            
                            Spacer()
                        }
                    }
                }
            }
            .fullScreenCover(item: $selectedUser) { user in
                NavigationStack {
                    ProfileView(uid: user.id)
                }
            }
        }
    }
}
