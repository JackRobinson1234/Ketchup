//
//  ReviewCell.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import SwiftUI
import FirebaseFirestoreInternal

struct ReviewCell: View {
    var review: Review
    @ObservedObject var viewModel: ReviewsViewModel
    @State var showUserProfile: Bool = false
    @State private var showingOptionsSheet = false
    var previewMode: Bool = false
    private var didLike: Bool { return review.didLike }
    
    var body: some View {
        HStack{
            VStack(alignment: .leading){
                HStack{
                    if viewModel.selectedRestaurant != nil {
                        Button{
                            showUserProfile.toggle()
                        } label: {
                            HStack {
                                if viewModel.selectedRestaurant != nil {
                                    UserCircularProfileImageView(profileImageUrl: review.user.profileImageUrl, size: .medium)
                                } else {
                                    RestaurantCircularProfileImageView(imageUrl: review.restaurant.profileImageUrl, size: .medium)
                                }
                                VStack(alignment: .leading){
                                    Text(getTimeElapsedString(from: review.timestamp))
                                        .font(.custom("MuseoSans-500", size: 12))
                                        .foregroundColor(.gray)
                                        Text("@\(review.user.username)")
                                            .font(.custom("MuseoSans-500", size: 16))
                                            .foregroundColor(.primary)
                                            .bold()
                                        if review.recommendation {
                                            HStack(spacing: 0){
                                                Image(systemName: "heart")
                                                    .foregroundColor(Color("Colors/AccentColor"))
                                                Text("Recommends")
                                                    .foregroundColor(.primary)
                                                
                                            }
                                            .font(.custom("MuseoSans-500", size: 12))
                                        } else {
                                            HStack(spacing: 0){
                                                Image(systemName: "heart.slash")
                                                    .foregroundColor(.gray)
                                                    .font(.custom("MuseoSans-500", size: 16))
                                                Text("Does not recommend")
                                                    .foregroundColor(.gray)
                                                    .bold()
                                                
                                                
                                            }
                                            .font(.custom("MuseoSans-500", size: 12))
                                        }
                                    }
                                }
                        }
                    } else {
                        NavigationLink(destination: RestaurantProfileView(restaurantId: review.restaurant.id)){
                            HStack {
                                if viewModel.selectedRestaurant != nil {
                                    UserCircularProfileImageView(profileImageUrl: review.user.profileImageUrl, size: .medium)
                                } else {
                                    RestaurantCircularProfileImageView(imageUrl: review.restaurant.profileImageUrl, size: .medium)
                                }
                                VStack(alignment: .leading){
                                    Text(getTimeElapsedString(from: review.timestamp))
                                        .font(.custom("MuseoSans-500", size: 12))
                                        .foregroundColor(.gray)
                                    
                                        Text("\(review.restaurant.name)")
                                            .font(.custom("MuseoSans-500", size: 16))
                                            .foregroundColor(.primary)
                                            .bold()
                                    
                                        if review.recommendation {
                                            HStack(spacing: 0){
                                                Image(systemName: "heart")
                                                    .foregroundColor(Color("Colors/AccentColor"))
                                                
                                                Text("Recommends")
                                                    .foregroundColor(.primary)
                                                
                                            }
                                            .font(.custom("MuseoSans-500", size: 12))
                                        } else {
                                            HStack(spacing: 0){
                                                Image(systemName: "heart.slash")
                                                    .foregroundColor(.gray)
                                                    .font(.custom("MuseoSans-500", size: 16))
                                                Text("Does not recommend")
                                                    .foregroundColor(.gray)
                                                    .bold()
                                                
                                                
                                            }
                                            .font(.custom("MuseoSans-500", size: 12))
                                        }
                                    }
                                }
                            }
                    }
                    Spacer()
                    if !previewMode{
                        HStack(spacing: 0){
                            Text("\(review.likes)")
                                .font(.custom("MuseoSans-500", size: 10))
                                .foregroundStyle(.gray)
                            Button {
                                handleLikeTapped()
                            } label: {
                                Image(systemName: didLike ? "heart.fill" : "heart")
                                    .foregroundStyle(didLike ? Color("Colors/AccentColor") : .primary)
                            }
                        }
                        Button {
                            showingOptionsSheet = true
                        } label: {
                            ZStack {
                                Color.clear
                                    .frame(width: 28, height: 28)
                                    .cornerRadius(14) // Optional: Adds a rounded corner
                                
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 18))
                            }
                        }
                    }
                }
                VStack(alignment: .leading){
                    HStack{
                        if let favoriteItems = review.favoriteItems, !favoriteItems.isEmpty {
                            Text("Favorite Dishes:")
                                .font(.custom("MuseoSans-500", size: 12))
                            
                            
                            ForEach(favoriteItems, id: \.self) { item in
                                Text(item)
                                    .font(.custom("MuseoSans-500", size: 12))
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 4)
                                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                            }
                        }
                    }
                    HStack{
                        Text("Review: ")
                            .font(.custom("MuseoSans-500", size: 16))
                            .bold() +
                        Text(review.description)
                            .font(.custom("MuseoSans-500", size: 16))
                    }
                    .padding(.top)
                        
                    
                }
                .multilineTextAlignment(.leading)
                
            }
            Spacer()
        }
        .padding()
            .sheet(isPresented: $showUserProfile) {
                NavigationStack{
                    ProfileView(uid: review.user.id)
                }
            }
            .sheet(isPresented: $showingOptionsSheet) {
                ReviewOptionsSheet(review: review, viewModel: viewModel)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.25)])
            }
        
    }
    private func handleLikeTapped() {
        Task { didLike ? await viewModel.unlike(review) : await viewModel.like(review) }
    }
    func getTimeElapsedString(from timestamp: Timestamp) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(timestamp.dateValue()) {
            let components = calendar.dateComponents([.hour, .minute], from: timestamp.dateValue(), to: now)
            if let hours = components.hour, hours > 0 {
                return "\(hours)h ago"
            } else if let minutes = components.minute, minutes > 5 {
                return "\(minutes)m ago"
            }
            return "Just now"
        } else if calendar.isDateInYesterday(timestamp.dateValue()) {
            return "Yesterday"
        } else {
            let components = calendar.dateComponents([.day, .weekOfYear], from: timestamp.dateValue(), to: now)
            if let days = components.day, days > 0 {
                return "\(days)d ago"
            } else if let weeks = components.weekOfYear, weeks > 0 {
                return "\(weeks)w ago"
            }
        }
        return ""
    }
}
#Preview {
    ReviewCell(review: DeveloperPreview.reviews[0], viewModel: ReviewsViewModel())
}
