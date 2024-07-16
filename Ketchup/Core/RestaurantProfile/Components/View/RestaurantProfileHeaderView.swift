//
//  RestaurantProfileHeaderView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import SwiftUI
import Kingfisher
import MapKit
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

    var travelTime: String? {
        guard let travelInterval else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        formatter.maximumUnitCount = 2
        return formatter.string(from: travelInterval)
    }

    var body: some View {
        if let restaurant = viewModel.restaurant {
            VStack(alignment: .leading, spacing: 6) {
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
                    
                    HStack {
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

                        // Add bookmark button
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
                        .padding(50)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading) {
                    HStack{
                        Button {
                            showMapView.toggle()
                        } label: {
                            if let street = restaurant.address, !street.isEmpty {
                                VStack(alignment: .leading) {
                                    if let travelTime {
                                        HStack(spacing: 0) {
                                            Image(systemName: "car")
                                            Text(" \(travelTime)")
                                                .font(.custom("MuseoSansRounded-300", size: 16))
                                                .foregroundStyle(.primary)
                                        }
                                    }
                                    
                                    Text("(Click to view on map)")
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                }
                            }
                        }
                        Spacer()
                        
                    }
                    
                }
                .padding()
                
                RestaurantProfileSlideBarView(viewModel: viewModel, feedViewModel: feedViewModel, scrollPosition: $scrollPosition,
                                              scrollTarget: $scrollTarget)
            }
            .onAppear {
                Task {
                    await viewModel.checkBookmarkStatus()
                }
            }
            .onReceive(LocationManager.shared.$userLocation.dropFirst().prefix(1)) { userLocation in
                guard userLocation != nil else {
                    return
                }
                Task {
                    if let restaurant = viewModel.restaurant, let coordinates = restaurant.coordinates {
                        let result = await LocationManager.shared.fetchRoute(coordinates: coordinates)
                        route = result.0
                        travelInterval = result.1
                    }
                }
            }
            .ignoresSafeArea()
            .sheet(isPresented: $showAddToCollection) {
                if let user {
                    AddItemCollectionList(restaurant: restaurant)
                }
            }
            .sheet(isPresented: $showMapView) {
                MapRestaurantProfileView(viewModel: viewModel, route: $route, travelInterval: $travelInterval)
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
            if let day = hour.day{
                if day.lowercased() == currentDayOfWeek.lowercased() {
                    return hour.hours
                }
            }
        }
        
        return nil
    }
}
//#Preview {
//    RestaurantProfileHeaderView(viewModel: RestaurantViewModel(restaurantId: ""))
//}
