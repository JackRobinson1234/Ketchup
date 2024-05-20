//
//  ReviewCell.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import SwiftUI

struct ReviewCell: View {
    var review: Review
    @State var showUserProfile: Bool = false
    var body: some View {
        VStack(alignment: .leading){
            
                Button{showUserProfile.toggle()} label: {
                    HStack {
                        UserCircularProfileImageView(profileImageUrl: review.user.profileImageUrl, size: .xxSmall)
                        Text("@\(review.user.username)")
                            .font(.caption)
                            .foregroundStyle(.black)
                    }

                }
            if review.recommendation {
                HStack{
                    Image(systemName: "heart")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("Recommended")
                        .font(.caption)
                        .bold()
                }
                } else {
                    HStack{
                    Image(systemName: "heart.slash")
                        .foregroundColor(.gray)
                        .font(.footnote)
                        Text("Does not recommend")
                            .font(.footnote)
                            .bold()
                }
            }
                VStack(alignment: .leading){
                    Text(review.description)
                        .font(.caption)
                        .lineLimit(2)
                    HStack{
                        if let favoriteItems = review.favoriteItems, !favoriteItems.isEmpty {
                            Text("Favorite Dishes:")
                                .font(.caption)
                                
                            
                            ForEach(favoriteItems, id: \.self) { item in
                                Text(item)
                                    .font(.caption)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black, lineWidth: 1))
                            }
                        }
                    }
                }
                .multilineTextAlignment(.leading)
            }
        .sheet(isPresented: $showUserProfile) {
            NavigationStack{
                ProfileView(uid: review.user.id)
            }
        }
        }
}
#Preview {
    ReviewCell(review: DeveloperPreview.reviews[0])
}
