//
//  RestaurantProfileHeaderView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import SwiftUI
import Kingfisher
import MapKit
import SafariServices


struct RestaurantProfileHeaderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var feedViewModel: FeedViewModel
    @ObservedObject var viewModel: RestaurantViewModel
    @State var showAddToCollection = false
    @State var user: User? = nil
    @State var showMapView: Bool = false
    @State var route: MKRoute?
    @State private var travelInterval: TimeInterval?
    @Binding var scrollPosition: String?
    @Binding var scrollTarget: String?
    @State private var showRatingDetails = false
    @State private var showSafariView = false
    
    var body: some View {
        if let restaurant = viewModel.restaurant {
            VStack(alignment: .leading, spacing: 6) {
                // Image and overlay
                ZStack(alignment: .bottomLeading) {
                    if let imageURLs = restaurant.profileImageUrl {
                        ListingImageCarouselView(images: [imageURLs])
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.clear, location: 0.4),
                                        .init(color: Color.black.opacity(0.7), location: 0.8),
                                        .init(color: Color.black.opacity(0.9), location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    
                    VStack {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.5))
                                            .frame(width: 30, height: 30)
                                    )
                            }
                            Spacer()
                        }
                        .padding(40)
                        .padding(.top, 15)
                        Spacer()
                    }
                    
                    HStack(alignment: .bottom){
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(restaurant.name)")
                                .font(.custom("MuseoSansRounded-300", size: 20))
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.white)
                            
                            if let city = restaurant.city, !city.isEmpty, let state = restaurant.state, !state.isEmpty {
                                Text("\(city), \(state)")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(.white)
                            } else if let city = restaurant.city, !city.isEmpty {
                                Text("\(city)")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(.white)
                            } else if let state = restaurant.state, !state.isEmpty {
                                Text("\(state)")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(.white)
                            }
                            
                            Text(combineRestaurantDetails(restaurant: restaurant))
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .foregroundStyle(.white)
                        }
                        .padding([.horizontal, .bottom])
                        
                        Spacer()
                        Button(action: {
                            Task {
                                await viewModel.toggleBookmark()
                            }
                        }) {
                            Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(viewModel.isBookmarked ? Color("Colors/AccentColor") : .white)
                                .font(.system(size: 24))
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Buttons for menu, map, and overall rating
                HStack(alignment: .bottom){
                    if let menuUrl = restaurant.menuUrl, let url = URL(string: menuUrl) {
                        Button {
                            showSafariView = true
                        } label: {
                            Label("View Menu", systemImage: "menucard")
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .foregroundStyle(.black)
                        }
                        .sheet(isPresented: $showSafariView) {
                            SafariView(url: url)
                        }
                    } else if let website = restaurant.website, let url = URL(string: website){
                        Button {
                            showSafariView = true
                        } label: {
                            Label("Website", systemImage: "globe")
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .foregroundStyle(.black)
                        }
                        .sheet(isPresented: $showSafariView) {
                            SafariView(url: url)
                        }
                    }
                    
                    Button {
                        showMapView.toggle()
                    } label: {
                        Label("View Map", systemImage: "map")
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .foregroundStyle(.black)
                    }
                    
                    
                    Spacer()
                    
                    if let overallRating = viewModel.overallRating {
                        Button {
                            withAnimation {
                                showRatingDetails.toggle()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 2){
                                Text("Average")
                                    .font(.custom("MuseoSansRounded-500", size: 12))
                                    .foregroundStyle(.gray)
                                HStack(alignment: .center, spacing: 4) {
                                    
                                    FeedOverallRatingView(rating: overallRating, font: .primary)
                                    
                                    Image(systemName: showRatingDetails ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.gray)
                                        .frame(width: 25)
                                        .rotationEffect(.degrees(showRatingDetails  ? 0 : -90))
                                        .animation(.easeInOut(duration: 0.3), value: showRatingDetails)
                                    
                                }
                                
                                
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Rating details dropdown
                if showRatingDetails {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Average Ratings")
                            .font(.custom("MuseoSansRounded-700", size: 14))
                        if let foodRating = viewModel.foodRating {
                            RatingSlider(rating: foodRating, label: "Food", isOverall: false, fontColor: .primary)
                        }
                        if let atmosphereRating = viewModel.atmosphereRating {
                            RatingSlider(rating: atmosphereRating, label: "Atmosphere", isOverall: false, fontColor: .primary)
                        }
                        if let valueRating = viewModel.valueRating {
                            RatingSlider(rating: valueRating, label: "Value", isOverall: false, fontColor: .primary)
                        }
                        if let serviceRating = viewModel.serviceRating {
                            RatingSlider(rating: serviceRating, label: "Service", isOverall: false, fontColor: .primary)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.top)
                //                VStack(alignment: .leading) {
                //                    Text("\(restaurant.bio ?? "")")
                //                        .font(.custom("MuseoSansRounded-300", size: 16))
                //                        .multilineTextAlignment(.leading)
                //                }
                //.padding()
                
                RestaurantProfileSlideBarView(viewModel: viewModel, feedViewModel: feedViewModel, scrollPosition: $scrollPosition,
                                              scrollTarget: $scrollTarget)
            }
            .onAppear {
                Task {
                    await viewModel.checkBookmarkStatus()
                }
            }
            .ignoresSafeArea()
            .sheet(isPresented: $showAddToCollection) {
                if let user {
                    AddItemCollectionList(restaurant: restaurant)
                }
            }
            .sheet(isPresented: $showMapView) {
                MapRestaurantProfileView(viewModel: viewModel)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
            }
        }
    }
    
    private func combineRestaurantDetails(restaurant: Restaurant) -> String {
        var details = [String]()
        
        if let cuisine = restaurant.categoryName {
            details.append(cuisine)
        }
        if let price = restaurant.price {
            details.append(price)
        }
        
        if let todaysHours = getTodaysHours(restaurant: restaurant) {
            details.append(todaysHours)
        }
        
        return details.joined(separator: " | ")
    }
    
    private func getTodaysHours(restaurant: Restaurant) -> String? {
        guard let openingHours = restaurant.openingHours else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let currentDayOfWeek = dateFormatter.string(from: Date())
        
        for hour in openingHours {
            if let day = hour.day {
                if day.lowercased() == currentDayOfWeek.lowercased() {
                    return hour.hours
                }
            }
        }
        
        return nil
    }
}
