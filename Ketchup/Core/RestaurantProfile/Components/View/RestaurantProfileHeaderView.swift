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
    @State private var urlToShow: URL?
    @State private var showCollections = false
    @State var showUploadPost = false
    @StateObject var cameraViewModel: CameraViewModel = CameraViewModel()
    @StateObject var uploadViewModel: UploadViewModel
    @State var showFriendsList = false
    @State private var highlightsAndTags: [String] = []
    @State private var showOrderSheet = false
    
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
            VStack(alignment: .leading, spacing: 4) {
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
                                            .fill(Color.gray)
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
                if let bio = restaurant.bio {
                    VStack( alignment: .leading, spacing: 0){
                        Text("Bio")
                            .font(.custom("MuseoSansRounded-900", size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        
                        Text(bio)
                            .font(.custom("MuseoSansRounded-300", size: 14))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                }
                if !highlightsAndTags.isEmpty{
                    VStack( alignment: .leading, spacing: 0){
                        Text("Known for")
                            .font(.custom("MuseoSansRounded-900", size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(highlightsAndTags, id: \.self) { item in
                                    HStack(spacing: 4) {
                                        Text(item)
                                            .font(.custom("MuseoSansRounded-300", size: 14))
                                            .foregroundColor(.gray)
                                        
                                        if item != highlightsAndTags.last {
                                            Circle()
                                                .fill(Color.gray)
                                                .frame(width: 3, height: 3)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .frame(height: 40)
                        }
                    }
                }
                
                
                
                
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading){
                        HStack(spacing: 2) {
                            Text("Features")
                                .font(.custom("MuseoSansRounded-900", size: 14))
                                .foregroundColor(.black)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.gray)
                            
                        }
                        
                        
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack{
                                HStack(spacing: 6) {
                                    featureItem(icon: "sun.max", title: "Breakfast", isAvailable: restaurant.additionalInfo?.diningOptions?.contains { $0.name == "Breakfast" && $0.value == true } ?? false)
                                    featureItem(icon: "fork.knife", title: "Lunch", isAvailable: restaurant.additionalInfo?.diningOptions?.contains { $0.name == "Lunch" && $0.value == true } ?? false)
                                    featureItem(icon: "moon.stars", title: "Dinner", isAvailable: restaurant.additionalInfo?.diningOptions?.contains { $0.name == "Dinner" && $0.value == true } ?? false)
                                    featureItem(icon: "birthday.cake", title: "Dessert", isAvailable: restaurant.additionalInfo?.diningOptions?.contains { $0.name == "Dessert" && $0.value == true } ?? false)
                                    featureItem(icon: "wineglass", title: "Alcohol", isAvailable: restaurant.additionalInfo?.offerings?.contains { $0.name == "Alcohol" && $0.value == true } ?? false)
                                    featureItem(icon: "beach.umbrella", title: "Outdoor Seating", isAvailable: restaurant.additionalInfo?.serviceOptions?.contains { $0.name == "Outdoor seating" && $0.value == true } ?? false)
                                    featureItem(icon: "calendar.badge.clock", title: "Accepts Reservations", isAvailable: restaurant.additionalInfo?.planning?.contains { $0.name == "Accepts reservations" && $0.value == true } ?? false)
                                    featureItem(icon: "calendar.badge.checkmark", title: "Reservations Required", isAvailable: restaurant.additionalInfo?.planning?.contains { $0.name == "Reservations required" && $0.value == true } ?? false)
                                    featureItem(icon: "bicycle", title: "Delivery", isAvailable: restaurant.additionalInfo?.serviceOptions?.contains { $0.name == "Delivery" && $0.value == true } ?? false)
                                    featureItem(icon: "leaf", title: "Vegetarian options", isAvailable: restaurant.additionalInfo?.offerings?.contains { $0.name == "Vegetarian options" && $0.value == true } ?? false)
                                    featureItem(icon: "wineglass", title: "Happy Hour", isAvailable: restaurant.additionalInfo?.offerings?.contains { $0.name == "Happy hour drinks" && $0.value == true } ?? false)
                                    featureItem(icon: "parkingsign", title: "Parking Lot", isAvailable: restaurant.additionalInfo?.parking?.contains { $0.name == "Free parking lot" && $0.value == true } ?? false)
                                    featureItem(icon: "pawprint", title: "Dogs Allowed", isAvailable: restaurant.additionalInfo?.pets?.contains { $0.name == "Dogs allowed" && $0.value == true } ?? false)
                                    featureItem(icon: "wifi", title: "Wi-Fi", isAvailable: restaurant.additionalInfo?.amenities?.contains { $0.name == "Wi-Fi" && $0.value == true } ?? false)
                                    featureItem(icon: "car", title: "Valet Parking", isAvailable: restaurant.additionalInfo?.parking?.contains { $0.name == "Valet parking" && $0.value == true } ?? false)
                                    featureItem(icon: "calendar.badge.clock", title: "Lunch Reservations Recommended", isAvailable: restaurant.additionalInfo?.planning?.contains { $0.name == "Lunch reservations recommended" && $0.value == true } ?? false)
                                    featureItem(icon: "calendar.badge.clock", title: "Dinner Reservations Recommended", isAvailable: restaurant.additionalInfo?.planning?.contains { $0.name == "Dinner reservations recommended" && $0.value == true } ?? false)
                                    featureItem(icon: "figure.roll", title: "Wheelchair Seating", isAvailable: restaurant.additionalInfo?.accessibility?.contains { $0.name == "Wheelchair accessible seating" && $0.value == true } ?? false)
                                    featureItem(icon: "creditcard", title: "Credit Cards", isAvailable: restaurant.additionalInfo?.payments?.contains { $0.name == "Credit cards" && $0.value == true } ?? false)
                                    featureItem(icon: "toilet", title: "Restroom", isAvailable: restaurant.additionalInfo?.amenities?.contains { $0.name == "Restroom" && $0.value == true } ?? false)
                                }
                                HStack (spacing: 2){
                                    Text("See all")
                                        .font(.custom("MuseoSansRounded-300", size: 12))
                                        .foregroundColor(.gray)
                                        .padding(.leading, 10)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                    }
                    
                    
                }
                .onTapGesture{
                    viewModel.currentSection = .stats
                    viewModel.scrollTarget = "additionalInfo"
                    scrollPosition = "additionalInfo"
                }
                
                
                
                
                
                VStack(alignment: .leading){
                    HStack(spacing: 2) {
                        Text("Scores")
                            .font(.custom("MuseoSansRounded-900", size: 14))
                            .foregroundColor(.black)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundStyle(.gray)
                    }
                    HStack(spacing: 10) {
                        overallScoreSection
                        friendsScoreSection
                    }
                }
                .onTapGesture {
                    withAnimation {
                        showRatingDetails.toggle()
                    }
                }
                
                
                
                
                
                .padding(.horizontal)
                if showRatingDetails {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Average Ratings")
                            .font(.custom("MuseoSansRounded-700", size: 14))
                            .foregroundStyle(.black)
                        Text(" \"|\" indicates friends average")
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .foregroundColor(.gray)
                        
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
                    .onTapGesture{
                        withAnimation {
                            showRatingDetails.toggle()
                        }
                    }
                }
                VStack (alignment: .leading){
                    
                    Text("People Also Search")
                        .font(.custom("MuseoSansRounded-900", size: 14))
                        .foregroundColor(.black)
                    
                        .padding(.horizontal)
                    peopleAlsoSearchSection
                    
                    
                    // Rating details dropdown
                    
                }
                .padding(.vertical)
                VStack (alignment: .leading){
                    
                    Text("Info")
                        .font(.custom("MuseoSansRounded-900", size: 14))
                        .foregroundColor(.black)
                    
                    
                        .padding(.horizontal)
                    actionButtonsView(restaurant: restaurant)
                    
                    
                    // Rating details dropdown
                    
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
                    calculateHighlightsAndTags(restaurant: restaurant)
                    
                }
            }
            .fullScreenCover(isPresented: $showUploadPost){
                CameraView(cameraViewModel: cameraViewModel, uploadViewModel: uploadViewModel)
            }
            .sheet(item: $urlToShow) { url in
                SafariView(url: url)
            }
            .ignoresSafeArea()
            .sheet(isPresented: $showAddToCollection) {
                if let user {
                    AddItemCollectionList(restaurant: restaurant)
                }
            }
            .sheet(isPresented: $showMapView) {
                //                if #available(iOS 17, *) {
                //                    MapRestaurantProfileView(viewModel: viewModel)
                //                        .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                //                }
                Ios16MapRestaurantProfileView(viewModel: viewModel)
                    .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
            }
            .sheet(isPresented: $showCollections) {
                if let currentUser = AuthService.shared.userSession {
                    AddItemCollectionList(restaurant: viewModel.restaurant)
                    
                }
            }
            .sheet(isPresented: $showOrderSheet) {
                OrderSheetView(restaurant: restaurant)
                    .presentationDetents([.fraction(0.25)])
            }
        }
    }
    @ViewBuilder
    private func actionButtonsView(restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let menuUrl = restaurant.menuUrl, !menuUrl.isEmpty, let url = URL(string: menuUrl) {
                        actionButton(title: "Menu", icon: "menucard") {
                            ////print("Menu URL:", menuUrl)
                            urlToShow = url
                        }
                    }
                    
                    if let website = restaurant.website, !website.isEmpty, let url = URL(string: website) {
                        actionButton(title: "Website", icon: "globe") {
                            urlToShow = url
                        }
                    }
                    
                    if restaurant.geoPoint != nil {
                        actionButton(title: "Map", icon: "map") {
                            showMapView.toggle()
                        }
                    }
                    
                    if let phone = restaurant.phone, !phone.isEmpty {
                        actionButton(title: "Call", icon: "phone") {
                            if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
            }
            
            HStack(spacing: 8) {
                if let orderBy = restaurant.orderBy, !orderBy.isEmpty {
                    actionButton(title: "Order", icon: "bag") {
                        showOrderSheet = true
                    }
                }
                
                if let website = restaurant.reserveTableUrl, !website.isEmpty, let url = URL(string: website) {
                    actionButton(title: "Reserve", icon: "calendar") {
                        urlToShow = url
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    private var peopleAlsoSearchSection: some View {
        VStack{
            if !viewModel.similarRestaurants.isEmpty {
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(viewModel.similarRestaurants.indices, id: \.self) { index in
                            
                            SimilarRestaurantCell(restaurant: viewModel.similarRestaurants[index])
                            
                            
                            if index < viewModel.similarRestaurants.count - 1 {
                                Divider()
                            }
                        }
                    }
                    
                }
            }
        }
    }
    private func calculateHighlightsAndTags(restaurant: Restaurant) {
        var items = [String]()
        
        // Add highlights from additional info
        if let highlights = restaurant.additionalInfo?.highlights {
            items.append(contentsOf: highlights.compactMap { $0.name })
        }
        
        // Add review tags (without count)
        if let reviewTags = restaurant.reviewsTags {
            items.append(contentsOf: reviewTags.compactMap { $0.title })
        }
        
        // Remove duplicates and capitalize first letter of each item
        highlightsAndTags = Array(Set(items)).map { $0.capitalized }
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
    private var overallScoreSection: some View {
        VStack(alignment: .leading) {
            if let overallRating = viewModel.overallRating {
                HStack(alignment: .center, spacing: 6) {
                    FeedOverallRatingView(rating: overallRating, font: .black)
                    VStack(alignment: .leading){
                        Text("Overall Score")
                            .font(.custom("MuseoSansRounded-700", size: 14))
                            .foregroundColor(.black)
                        if let stats = viewModel.restaurant?.stats {
                            Text("\(stats.postCount) posts")
                                .font(.custom("MuseoSansRounded-500", size: 12))
                                .foregroundColor(.gray)
                            Text("\(stats.collectionCount) Collections")
                                .font(.custom("MuseoSansRounded-500", size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
            } else {
                Text("No reviews yet")
                    .font(.custom("MuseoSansRounded-300", size: 14))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .padding(2)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var friendsScoreSection: some View {
        VStack(alignment: .leading) {
            if let friendsOverallRating = feedViewModel.friendsOverallRating {
                HStack(alignment: .center, spacing: 6) {
                    FeedOverallRatingView(rating: friendsOverallRating, font: .black)
                    VStack(alignment: .leading, spacing: 0){
                        Text("Friends Score")
                            .font(.custom("MuseoSansRounded-700", size: 14))
                            .foregroundColor(.black)
                        if !viewModel.friendsWhoPosted.isEmpty {
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
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .foregroundColor(.gray)
                                        .padding(.leading, 10)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No reviews from friends")
                    .font(.custom("MuseoSansRounded-300", size: 14))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .padding(2)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    private func featureItem(icon: String, title: String, isAvailable: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18)) // Smaller icon size
                .foregroundColor(isAvailable ? .black : .gray.opacity(0.5))
            Text(title)
                .font(.custom("MuseoSansRounded-300", size: 10)) // Smaller font size
                .foregroundColor(isAvailable ? .black : .gray.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
            
        }
        .frame(width: 60, height: 60)
    }
    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 1) { // Horizontal stack to align icon and title
                Image(systemName: icon)
                    .font(.system(size: 16)) // Smaller icon size
                Text(title)
                    .font(.custom("MuseoSansRounded-300", size: 12))
                    .padding(.horizontal, 8)
            }
            
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .overlay(
                Capsule()
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1) // Rounded pill border
            )
        }
        .foregroundColor(.black)
        
    }
    
}
extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}
struct OrderSheetView: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Options")
                .font(.custom("MuseoSansRounded-700", size: 18))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if let orderOptions = restaurant.orderBy {
                        let sortedOrderOptions = orderOptions.sorted { option1, option2 in
                            // Custom sorting based on desired order
                            orderPriority(option: option1) < orderPriority(option: option2)
                        }
                        
                        ForEach(sortedOrderOptions, id: \.name) { option in
                            OrderOptionView(option: option)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct OrderOptionView: View {
    let option: OrderBy
    
    var body: some View {
        VStack(spacing: 4) {
            Group {
                if imageNameForOption() == "globe" {
                    Image(systemName: "globe")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray)
                } else {
                    Image(imageNameForOption())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            Text(option.name ?? "Order")
                .font(.custom("MuseoSansRounded-500", size: 12))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .frame(width: 80, height: 90)
        .onTapGesture {
            if let orderUrl = option.orderUrl, let url = URL(string: orderUrl) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func imageNameForOption() -> String {
        guard let name = option.name?.lowercased() else { return "globe" }
        
        switch name {
        case "doordash":
            return "Doordash"
        case "postmates":
            return "Postmates"
        case "caviar":
            return "Caviar"
        case "toast", "toast local":
            return "Toast"
        case "grubhub":
            return "Grubhub"
        case "ubereats":
            return "UberEats"
        default:
            return "globe"
        }
    }
}

private func orderPriority(option: OrderBy) -> Int {
    guard let name = option.name?.lowercased() else { return 999 } // Default to high number for options with "globe"
    
    switch name {
    case "ubereats":
        return 1
    case "doordash":
        return 2
    case "grubhub":
        return 3
    case "toast", "toast local":
        return 4
    case "caviar":
        return 5
    case "postmates":
        return 6
    default:
        return 999 // Place others (like those with "globe") at the end
    }
}
