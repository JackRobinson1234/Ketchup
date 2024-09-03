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
    @State private var showCollections = false
    @State var showUploadPost = false
    @StateObject var cameraViewModel: CameraViewModel = CameraViewModel()
    @StateObject var uploadViewModel: UploadViewModel
    @State var showFriendsList = false
    init(feedViewModel: FeedViewModel, viewModel: RestaurantViewModel, scrollPosition: Binding<String?>, scrollTarget: Binding<String?>) {
        self._feedViewModel = ObservedObject(wrappedValue: feedViewModel)
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._scrollPosition = scrollPosition
        self._scrollTarget = scrollTarget
        
        // Initialize uploadViewModel with feedViewModel
        _uploadViewModel = StateObject(wrappedValue: UploadViewModel(feedViewModel: feedViewModel, currentUserFeedViewModel: FeedViewModel()))
    }

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
                        VStack(spacing: 15){
                            Button(action: {
                                showCollections.toggle()
                            }) {
                                Image(systemName: "folder.badge.plus")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24))
                            }
                            Button(action: {
                                Task {
                                    await viewModel.toggleBookmark()
                                }
                            }) {
                                Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                                    .foregroundColor(viewModel.isBookmarked ? Color("Colors/AccentColor") : .white)
                                    .font(.system(size: 24))
                            }
                            Button{
                                uploadViewModel.restaurant = viewModel.restaurant
                                uploadViewModel.fromRestaurantProfile = true
                                showUploadPost = true
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24))
                            }
                            
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
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .font(.custom("MuseoSansRounded-500", size: 16))
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
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .font(.custom("MuseoSansRounded-500", size: 16))
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
                                    .stroke(Color.black, lineWidth: 1)
                            )
                            .font(.custom("MuseoSansRounded-500", size: 16))
                            .foregroundStyle(.black)
                    }
                    
                    
                    Spacer()
                    
                    if let overallRating = viewModel.overallRating {
                        Button {
                            withAnimation {
                                showRatingDetails.toggle()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4){
                                Text("Average")
                                    .font(.custom("MuseoSansRounded-500", size: 12))
                                    .foregroundStyle(.gray)
                                    
                                HStack(alignment: .center, spacing: 4) {
                                    
                                    FeedOverallRatingView(rating: overallRating, font: .black)
                                    
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
                        
                        // Food Rating with Friends' Rating
                        if let foodRating = viewModel.foodRating {
                            RatingSlider(rating: foodRating, label: "Food", isOverall: false, fontColor: .black, friendsRating: feedViewModel.friendsFoodRating)
                        }
                        
                        // Atmosphere Rating with Friends' Rating
                        if let atmosphereRating = viewModel.atmosphereRating {
                            RatingSlider(rating: atmosphereRating, label: "Atmosphere", isOverall: false, fontColor: .black, friendsRating: feedViewModel.friendsAtmosphereRating)
                        }
                        
                        // Value Rating with Friends' Rating
                        if let valueRating = viewModel.valueRating {
                            RatingSlider(rating: valueRating, label: "Value", isOverall: false, fontColor: .black, friendsRating: feedViewModel.friendsValueRating)
                        }
                        
                        // Service Rating with Friends' Rating
                        if let serviceRating = viewModel.serviceRating {
                            RatingSlider(rating: serviceRating, label: "Service", isOverall: false, fontColor: .black, friendsRating: feedViewModel.friendsServiceRating)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                    .padding(.horizontal)
                }
                
               
                //                VStack(alignment: .leading) {
                //                    Text("\(restaurant.bio ?? "")")
                //                        .font(.custom("MuseoSansRounded-300", size: 16))
                //                        .multilineTextAlignment(.leading)
                //                }
                //.padding()
                if !viewModel.friendsWhoPosted.isEmpty {
                    Button{
                        showFriendsList = true
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Eaten at by your friends")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .foregroundColor(.gray)
                            HStack(spacing: -10) {
                                ForEach(viewModel.friendsWhoPosted.prefix(3)) { user in
                                    UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .xSmall)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                }
                                
                                if viewModel.friendsWhoPosted.count > 3 {
                                    Text("+ \(viewModel.friendsWhoPosted.count - 3) others")
                                        .font(.custom("MuseoSansRounded-300", size: 12))
                                        .foregroundColor(.gray)
                                        .padding(.leading, 10)
                                }
                            }
                            
                            
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                } else {
                    Text("No reviews from friends")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundColor(.gray)
                        .padding(.leading, 10)
                }
                Divider()
                    .padding(.top)
                RestaurantProfileSlideBarView(viewModel: viewModel, feedViewModel: feedViewModel, scrollPosition: $scrollPosition,
                                              scrollTarget: $scrollTarget)
            }
            .overlay{
                if uploadViewModel.showSuccessMessage {
                                successOverlay
                                    .transition(.opacity)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            withAnimation {
                                                uploadViewModel.showSuccessMessage = false
                                            }
                                        }
                                    }
                            }
            }
            .sheet(isPresented: $showFriendsList) {
                TaggedUsersSheetView(taggedUsers: viewModel.friendsWhoPosted, title: "Friends who have eaten here")
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
            }
            .onAppear {
                Task {
                    await viewModel.checkBookmarkStatus()
                    await viewModel.fetchFriendsWhoPosted()
                }
            }
            .fullScreenCover(isPresented: $showUploadPost){
                CameraView(cameraViewModel: cameraViewModel, uploadViewModel: uploadViewModel)
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
            .sheet(isPresented: $showCollections) {
                if let currentUser = AuthService.shared.userSession {
                    AddItemCollectionList(restaurant: viewModel.restaurant)
                        
                }
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
    private var successOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "checkmark")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.red)
                    Text("Post Uploaded")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.top, 5)
                        .font(.custom("MuseoSansRounded-300", size: 14))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 4) // Optional: add a shadow for better visibility
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
}
