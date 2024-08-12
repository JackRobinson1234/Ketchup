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
    @ObservedObject var viewModel: ActivityViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Square Restaurant/Collection Image
            Button {
                handleImageTap()
            } label: {
                activityImage
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Activity Info
            
            Button {
                viewModel.selectedUid = activity.uid
                viewModel.showUserProfile = true
            } label: {
                HStack(spacing: 8) {
                    UserCircularProfileImageView(profileImageUrl: activity.profileImageUrl, size: .small)
                    
                    Text("@\(activity.username)")
                        .font(.custom("MuseoSansRounded-700", size: 14))
                        .foregroundColor(.black)
                        .lineLimit(1)
                }
            }
            if let restaurantId = activity.restaurantId {
                NavigationLink(value: activity){
                    activityDescription
                }
            }
            Text(getTimeElapsedString(from: activity.timestamp))
                .font(.custom("MuseoSansRounded-300", size: 11))
                .foregroundColor(.gray)
        }
        .frame(width: 160)
        .background(Color(.systemBackground))
    }
    
    var activityDescription: some View {
        Group {
            switch activity.type {
            case .newPost:
                textWithHighlight(prefix: "Created a new post for: ", highlight: activity.name)
            case .newCollection:
                textWithHighlight(prefix: "Created a new collection: ", highlight: activity.name)
            case .newCollectionItem:
                textWithHighlight(prefix: "Added ", highlight: activity.name, suffix: " to a collection")
            }
        }
        .font(.custom("MuseoSansRounded-300", size: 13))
        .foregroundColor(.black)
        .lineLimit(3)
        .multilineTextAlignment(.leading)
    }
    
    func textWithHighlight(prefix: String, highlight: String, suffix: String = "") -> some View {
        (Text(prefix)
         + Text(highlight).font(.custom("MuseoSansRounded-500", size: 13))
         + Text(suffix))
    }
    
    var activityImage: some View {
        Group {
            if let image = activity.image, !image.isEmpty {
                KFImage(URL(string: image))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Fallback image or icon based on activity type
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: fallbackImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.gray)
                        .padding(40)
                }
            }
        }
    }
    
    var fallbackImageName: String {
        switch activity.type {
        case .newPost:
            return "square.text.square"
        case .newCollection:
            return "square.grid.2x2"
        case .newCollectionItem:
            return "plus.square.on.square"
        }
    }
    
    func handleImageTap() {
        switch activity.type {
        case .newPost:
            if let postId = activity.postId {
                if let image = activity.image, !image.isEmpty{
                    Task {
                        viewModel.post = try await PostService.shared.fetchPost(postId: postId)
                        if viewModel.post != nil {
                            viewModel.showPost.toggle()
                        }
                    }
                } else {
                    Task {
                        viewModel.writtenPost = try await PostService.shared.fetchPost(postId: postId)
                    }
                }
            }
        case .newCollection, .newCollectionItem:
            if let collectionId = activity.collectionId {
                Task {
                    viewModel.collection = try await CollectionService.shared.fetchCollection(withId: collectionId)
                    if let collection = viewModel.collection, viewModel.user != nil {
                        viewModel.collectionsViewModel.updateSelectedCollection(collection: collection)
                        viewModel.showCollection.toggle()
                    }
                }
            }
        }
    }
}
extension Text {
    func activityCellFontStyle() -> Text {
        self.font(.custom("MuseoSansRounded-300", size: 14))
            .foregroundColor(.black)
    }
}

func getTimeElapsedString(from timestamp: Timestamp) -> String {
    let calendar = Calendar.current
    let now = Date()
    let date = timestamp.dateValue()
    
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date, to: now)
    
    if let year = components.year, year > 0 {
        return "\(year)y ago"
    } else if let month = components.month, month > 0 {
        return "\(month)mo ago"
    } else if let day = components.day, day > 0 {
        if day == 1 {
            return "Yesterday"
        }
        return "\(day)d ago"
    } else if let hour = components.hour, hour > 0 {
        return "\(hour)h ago"
    } else if let minute = components.minute, minute > 0 {
        return "\(minute)m ago"
    } else {
        return "Just now"
    }
}
