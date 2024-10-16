//
//  RestaurantCardView.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/16/24.
//

import SwiftUI
import FirebaseAuth
import CoreLocation
import FirebaseFirestoreInternal
import Kingfisher

struct RestaurantCardView: View {
    let userLocation: CLLocation?
    let restaurant: Restaurant
    @State private var friendsPostCount: Int = 0
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomLeading){
                if let imageUrl = restaurant.profileImageUrl {
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 130)
                        .clipped()
                } else {
                    Image("placeholderImage")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 130)
                        .cornerRadius(8)
                        .clipped()
                }
                if friendsPostCount > 0 {
                    Text("\(friendsPostCount) friend\(friendsPostCount > 1 ? "s" : "")")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        .padding(8)
                }
            }
            VStack(alignment: .leading){
                Text(restaurant.name)
                    .font(.custom("MuseoSansRounded-700", size: 14))
                    .foregroundColor(.black)
                    .lineLimit(1)
                if let city = restaurant.city {
                    Text(city)
                        .font(.custom("MuseoSansRounded-500", size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                if let cuisine = restaurant.categoryName, let price = restaurant.price {
                    Text("\(cuisine), \(price)")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else if let cuisine = restaurant.categoryName {
                    Text(cuisine)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else if let price = restaurant.price {
                    Text(price)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if let count = restaurant.stats?.postCount {
                    HStack {
                        Text("\(count) posts")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        if let overallRating = restaurant.overallRating?.average {
                            Text("(\(String(format: "%.1f", overallRating)))")
                                .font(.custom("MuseoSansRounded-300", size: 10))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                }
                if let distance = distanceString {
                    Text(distance)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 220)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(5)
        .onAppear{
            Task {
                await fetchFriendsPostCount()
            }
        }
    }
    
    private var distanceString: String? {
        guard let userLocation = userLocation,
              let restaurantLat = restaurant.geoPoint?.latitude,
              let restaurantLon = restaurant.geoPoint?.longitude else {
            return nil
        }
        let restaurantLocation = CLLocation(latitude: restaurantLat, longitude: restaurantLon)
        let distanceInMeters = userLocation.distance(from: restaurantLocation)
        let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles
        
        return String(format: "%.1f mi", distanceInMiles)
    }
    
    func fetchFriendsPostCount() async {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        do {
            let followingPostsRef = Firestore.firestore().collection("followingposts").document(currentUserID).collection("posts")
            let query = followingPostsRef
                .whereField("restaurant.id", isEqualTo: restaurant.id)
            
            let count = try await query.count.getAggregation(source: .server).count
            
            self.friendsPostCount = Int(truncating: count)
        } catch {
            print("Error fetching friends post count: \(error.localizedDescription)")
        }
    }
}
