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
    @State var post: Post?
    @State var collection: Collection?
    @ObservedObject var viewModel: ActivityViewModel
    var body: some View {
        //MARK: newPost
        VStack{
            if activity.type == .newPost {
                if let postType = activity.postType {
                    HStack{
                        Button{showUserProfile.toggle()} label: {
                            UserCircularProfileImageView(profileImageUrl: activity.profileImageUrl, size: .medium)
                        }
                        //MARK: Post: Restaurant
                        if postType == "restaurant"{
                            if let restaurantId = activity.restaurantId{
                                NavigationLink(destination: RestaurantProfileView(restaurantId: restaurantId)) {
                                    VStack(alignment: .leading){
                                        Text("@\(activity.username) created a new restaurant post for ")
                                            .activityCellFontStyle()
                                        +
                                        Text(activity.name)
                                            .bold()
                                            .activityCellFontStyle()
                                    }
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                }
                            }
                            else {
                                VStack(alignment: .leading){
                                    Text("@\(activity.username) created a new restaurant post for: ")
                                        .foregroundStyle(.black)
                                    +
                                    Text(activity.name)
                                        .bold()
                                        .activityCellFontStyle()
                                    Text(getTimeElapsedString(from: activity.timestamp))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                                
                            }
                            //MARK: Post: AtHome
                        } else if postType == "atHome" {
                            VStack(alignment: .leading){
                                Text("@\(activity.username) created a new at home post: ")
                                    .activityCellFontStyle() +
                                Text(activity.name)
                                    .activityCellFontStyle()
                                    .bold()
                                
                                Text(getTimeElapsedString(from: activity.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                            }
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            
                            
                        }
                        Spacer()
                        //MARK: Post Image
                        if let image = activity.image {
                            Button{
                                if let postId = activity.postId{
                                    Task{
                                        self.post = try await PostService.shared.fetchPost(postId: postId)
                                        if self.post != nil {
                                            showPost.toggle()
                                        }
                                    }
                                }
                            } label: {
                                KFImage(URL(string: image))
                                    .resizable()
                                    .frame(width: 50, height: 70) // Set the image size to 50x50
                                    .aspectRatio(contentMode: .fit) // Maintain aspect ratio
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            
                            
                        }
                    }
                    .padding()
                }
            }
            //MARK: New Collection
            else if activity.type == .newCollection {
                HStack{
                    Button{showUserProfile.toggle()} label: {
                        UserCircularProfileImageView(profileImageUrl: activity.profileImageUrl, size: .medium)
                    }
                    VStack(alignment: .leading){
                        Text("@\(activity.username) created a new collection: ") +
                        Text(activity.name)
                            .bold()
                            .activityCellFontStyle()
                        Text(getTimeElapsedString(from: activity.timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                    }
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    Spacer()
                    if let image = activity.image {
                        KFImage(URL(string: image))
                            .resizable()
                            .frame(width: 50, height: 70) // Set the image size to 50x50
                            .aspectRatio(contentMode: .fit) // Maintain aspect ratio
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Button{
                            Task{
                                if let collectionId = activity.collectionId{
                                    self.collection = try await CollectionService.shared.fetchCollection(withId: collectionId)
                                    if self.collection != nil, viewModel.user != nil{
                                        showCollection.toggle()
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "folder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height:60)
                                .foregroundStyle(.black)
                        }
                    }
                }
                .padding()
                
                //MARK: CollectionItem
            } else if activity.type == .newCollectionItem {
                HStack{
                    Button{showUserProfile.toggle()} label: {
                        UserCircularProfileImageView(profileImageUrl: activity.profileImageUrl, size: .medium)
                    }
                    VStack(alignment: .leading){
                        Text("\(activity.username) added a new item to the collection: ")
                            .activityCellFontStyle() +
                        Text(activity.name)
                            .activityCellFontStyle()
                            .bold()
                        Text(getTimeElapsedString(from: activity.timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    Spacer()
                    if let image = activity.image {
                        KFImage(URL(string: image))
                            .resizable()
                            .frame(width: 50, height: 70) // Set the image size to 50x50
                            .aspectRatio(contentMode: .fit) // Maintain aspect ratio
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Button{
                            Task{
                                if let collectionId = activity.collectionId{
                                    self.collection = try await CollectionService.shared.fetchCollection(withId: collectionId)
                                    if self.collection != nil, viewModel.user != nil{
                                        showCollection.toggle()
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "folder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height:60)
                                .foregroundStyle(.black)
                        }
                    }
                }
                .padding()
                
            }
            
        }
        //MARK: Sheets
        .sheet(isPresented: $showPost){
            if let post = self.post{
                FeedView(videoCoordinator: VideoPlayerCoordinator(), posts: [post], hideFeedOptions: true)
            }
        }
        .sheet(isPresented: $showCollection) {
            if let collection = self.collection, let user = viewModel.user {
                
                CollectionView(collectionsViewModel: CollectionsViewModel(user: user, selectedCollection: collection))
                
            }
        }
        .sheet(isPresented: $showUserProfile) {
            NavigationStack{
                ProfileView(uid: activity.uid)
            }
        }
    }
    //MARK: getTimeElapsedString
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
extension Text {
    func activityCellFontStyle() -> Text {
        self.font(.subheadline) // Customize the font style here
            .foregroundColor(.black) // Customize the text color if needed
    }
}
#Preview {
    ActivityCell(activity: DeveloperPreview.activity2, viewModel: ActivityViewModel())
}
