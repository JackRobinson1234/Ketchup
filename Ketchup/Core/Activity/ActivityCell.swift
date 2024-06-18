//
//  ActivityCell.swift
//  Foodi
//
//  Created by Jack Robinson on 5/2/24.
//

import SwiftUI
import Kingfisher
import FirebaseFirestoreInternal
struct ActivityCell: View {
    var activity: Activity
    @Environment(\.dismiss) var dismiss
    @State var showPost: Bool = false
    @State var showCollection: Bool = false
    @State var showUserProfile: Bool = false
    @State var showRestaurant = false
    @State var post: Post?
    @State var collection: Collection?
    @ObservedObject var viewModel: ActivityViewModel
    @State var selectedRestaurantId: String? = nil
    @StateObject var collectionsViewModel: CollectionsViewModel = CollectionsViewModel(user: DeveloperPreview.user)
    var body: some View {
        VStack {
            //MARK: newPost
            if activity.type == .newPost {
                if let postType = activity.postType {
                    HStack {
                        Button { 
                            showUserProfile = true
                        } label: {
                            UserCircularProfileImageView(profileImageUrl: activity.profileImageUrl, size: .large)
                        }
                        //MARK: Post: Restaurant
                        if postType == .dining {
                
                                VStack(alignment: .leading) {
                                    Text("@\(activity.username) created a new restaurant post for: ")
                                        .foregroundStyle(.primary)
                                        .activityCellFontStyle() +
                                    Text(activity.name)
                                        .bold()
                                        .activityCellFontStyle()
                                    Text(getTimeElapsedString(from: activity.timestamp))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .multilineTextAlignment(.leading)
                            
                        //MARK: Post: AtHome
                        } else if postType == .cooking {
                            VStack(alignment: .leading) {
                                Text("@\(activity.username) created a new at home post: ")
                                    .activityCellFontStyle() +
                                Text(activity.name)
                                    .activityCellFontStyle()
                                    .bold() +
                                Text(" !")
                                    .activityCellFontStyle()
                                Text(getTimeElapsedString(from: activity.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        //MARK: Post Image
                        if let image = activity.image {
                            Button {
                                if let postId = activity.postId {
                                    Task {
                                        print("Fetching post with ID \(postId)")
                                        self.post = try await PostService.shared.fetchPost(postId: postId)
                                        if self.post != nil {
                                            print("Fetched post: \(String(describing: self.post))")
                                            showPost.toggle()
                                        }
                                    }
                                }
                            } label: {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .frame(width: 50, height: 70)
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding()
                }
            //MARK: New Collection
            } else if activity.type == .newCollection {
                HStack {
                    Button { showUserProfile = true } label: {
                        UserCircularProfileImageView(profileImageUrl: activity.profileImageUrl, size: .large)
                    }
                    VStack(alignment: .leading) {
                        Text("@\(activity.username) created a new collection: ")
                            .activityCellFontStyle() +
                        Text((activity.name))
                            .bold()
                            .activityCellFontStyle() +
                        Text("!")
                            .activityCellFontStyle()
                        Text(getTimeElapsedString(from: activity.timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .multilineTextAlignment(.leading)
                    Spacer()
                    if let image = activity.image {
                        KFImage(URL(string: image))
                            .resizable()
                            .frame(width: 50, height: 70)
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Button {
                            Task {
                                if let collectionId = activity.collectionId {
                                    self.collection = try await CollectionService.shared.fetchCollection(withId: collectionId)
                                    if let collection = self.collection , viewModel.user != nil {
                                        print("Fetched collection: \(String(describing: self.collection))")
                                        viewModel.collectionsViewModel.updateSelectedCollection(collection: collection)
                                        showCollection.toggle()
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "folder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding()
            //MARK: CollectionItem
            } else if activity.type == .newCollectionItem {
                HStack {
                    Button { showUserProfile = true } label: {
                        UserCircularProfileImageView(profileImageUrl: activity.profileImageUrl, size: .large)
                    }
                    VStack(alignment: .leading) {
                        Text("@\(activity.username) added ")
                            .activityCellFontStyle() +
                        Text(activity.name)
                            .activityCellFontStyle()
                            .bold() +
                        Text(" to a collection")
                            .activityCellFontStyle()
                        Text(getTimeElapsedString(from: activity.timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .multilineTextAlignment(.leading)
                    Spacer()
                    if let image = activity.image {
                        Button {
                            Task {
                                if let collectionId = activity.collectionId {
                                    self.collection = try await CollectionService.shared.fetchCollection(withId: collectionId)
                                    if let collection = self.collection, viewModel.user != nil {
                                        viewModel.collectionsViewModel.updateSelectedCollection(collection: collection)
                                        print("Fetched collection: \(String(describing: self.collection))")
                                        showCollection.toggle()
                                    }
                                }
                            }
                        } label: {
                            KFImage(URL(string: image))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    } else {
                        Button {
                            Task {
                                if let collectionId = activity.collectionId {
                                    self.collection = try await CollectionService.shared.fetchCollection(withId: collectionId)
                                    if let collection = self.collection, viewModel.user != nil {
                                        print("Fetched collection: \(String(describing: self.collection))")
                                        viewModel.collectionsViewModel.updateSelectedCollection(collection: collection)
                                        showCollection.toggle()
                                    }
                                    
                                }
                            }
                        } label: {
                            Image(systemName: "folder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding()
            //MARK: newReview
            } else if activity.type == .newReview {
                HStack {
                    Button { showUserProfile = true } label: {
                        UserCircularProfileImageView(profileImageUrl: activity.profileImageUrl, size: .large)
                    }
                    if let text = activity.text {
                        VStack(alignment: .leading) {
                            if let recs = activity.recommendation, recs {
                                HStack(spacing: 0) {
                                    Image(systemName: "heart")
                                        .foregroundColor(Color("Colors/AccentColor"))
                                    Text("Recommends")
                                        .foregroundStyle(.primary)
                                }
                                .font(.caption)
                            } else {
                                HStack(spacing: 0) {
                                    Image(systemName: "heart.slash")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                    Text("Does not recommend")
                                        .foregroundColor(.gray)
                                        .bold()
                                }
                                .font(.caption)
                            }
                            Text("@\(activity.username) reviewed ")
                                .activityCellFontStyle() +
                            Text(activity.name)
                                .activityCellFontStyle()
                                .bold() +
                            Text(": \(text)")
                                .activityCellFontStyle()
                            Text(getTimeElapsedString(from: activity.timestamp))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    if let image = activity.image {
                        if let restaurantId = activity.restaurantId {
                            Button {
                                print("Setting selectedRestaurantId to \(restaurantId)")
                                self.selectedRestaurantId = restaurantId
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    self.showRestaurant.toggle()
                                }
                            } label: {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                .padding()
            }
        }
        //MARK: Sheets
        .sheet(isPresented: Binding(
            get: { showPost && post != nil },
            set: { showPost = $0 }
        )) {
            if let post = self.post {
                let _ = print("Showing FeedView for post: \(post)")
                FeedView(videoCoordinator: VideoPlayerCoordinator(), posts: [post], hideFeedOptions: true)
            }
        }
        .sheet(isPresented: Binding(
            get: { showCollection && collection != nil },
            set: { showCollection = $0 }
        )) {
            if  self.collection != nil {
                CollectionView(collectionsViewModel: viewModel.collectionsViewModel)
            }
        }
        .sheet(isPresented: Binding(
            get: { showRestaurant && selectedRestaurantId != nil },
            set: { showRestaurant = $0 }
        )) {
            if let selectedRestaurantId = selectedRestaurantId {
                let _ = print("Showing RestaurantProfileView for \(selectedRestaurantId)")
                NavigationStack {
                    RestaurantProfileView(restaurantId: selectedRestaurantId)
                }
            }
        }
        .sheet(isPresented: $showUserProfile) {
            NavigationStack {
                ProfileView(uid: activity.uid)
            }
        }
    }

    
}

extension Text {
    func activityCellFontStyle() -> Text {
        self.font(.subheadline)
            .foregroundColor(.primary)
    }
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
