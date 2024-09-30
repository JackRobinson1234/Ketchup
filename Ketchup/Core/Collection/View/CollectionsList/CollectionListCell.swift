//
//  ProfileCollectionCell.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI
import Kingfisher
import FirebaseAuth
struct CollectionListCell: View {
    var collection: Collection
    var searchCollection: CollectionSearchModel?
    var size: CGFloat = 60
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    var showChevron: Bool = true

    var body: some View {
        HStack {
            if let cover = collection.coverImageUrl {
                CollageImage(tempImageUrls: [cover], width: size)
            } else if let tempImageUrls = collection.tempImageUrls {
                CollageImage(tempImageUrls: tempImageUrls, width: size)
            } else {
                Image(systemName: "folder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.black)
            }
            VStack(alignment: .leading) {
                HStack {
                    Text(collection.name)
                        .font(.custom("MuseoSansRounded-300", size: 18))
                        .bold()
                        .lineLimit(1)
                        .foregroundStyle(.black)
                    
                    if isCollaborator {
                        Image(systemName: "link")
                            .foregroundColor(.red)
                    }
                }
                if showChevron {
                    itemCountText(for: collection)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .foregroundStyle(.black)
                }
                collaboratorsText(for: collection)
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .lineLimit(1)
                    .foregroundStyle(.black)
                if showChevron {
                    if let description = collection.description {
                        Text(description)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .lineLimit(1)
                            .foregroundStyle(.black)
                    }
                } else {
                    if let timestamp = collection.timestamp {
                        Text(getTimeElapsedString(from: timestamp))
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.black)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    private var isCollaborator: Bool {
        return !collection.collaborators.isEmpty
    }
    
    private func itemCountText(for collection: Collection) -> some View {
        let restaurantCount = collection.restaurantCount
        let itemCountText: String
        if restaurantCount > 0 {
            itemCountText = "\(restaurantCount) \(pluralText(for: restaurantCount, singular: "Restaurant", plural: "Restaurants"))"
        } else {
            itemCountText = "No Items Yet"
        }
        
        return Text(itemCountText)
    }

    private func collaboratorsText(for collection: Collection) -> some View {
        let collaboratorCount = collection.collaborators.count
        let collaboratorText: String
        if collaboratorCount > 0 {
            collaboratorText = "By \(collection.username) + \(collaboratorCount) \(pluralText(for: collaboratorCount, singular: "collaborator", plural: "collaborators"))"
        } else {
            collaboratorText = "By \(collection.username)"
        }
        
        return Text(collaboratorText)
    }

    private func pluralText(for count: Int, singular: String, plural: String) -> String {
        return count == 1 ? singular : plural
    }
}
