//
//  ProfileCollectionCell.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI
import Kingfisher
struct CollectionListCell: View {
    var collection: Collection
    var searchCollection: CollectionSearchModel?
    var size: CGFloat = 60
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    var body: some View {
        HStack{
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
            VStack(alignment: .leading){
                Text(collection.name)
                    .font(.custom("MuseoSansRounded-300", size: 18))
                    .bold()
                    .lineLimit(1)
                    .foregroundStyle(.black)
                itemCountText(for: collection)
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .foregroundStyle(.black)
                Text("By \(collection.username)")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .lineLimit(1)
                    .foregroundStyle(.black)
                if let description = collection.description {
                    Text(description)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .lineLimit(1)
                        .foregroundStyle(.black)
                }
                
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.black)
                .padding(.horizontal)
        }
        .padding(.horizontal)
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
    private func pluralText(for count: Int, singular: String, plural: String) -> String {
        return count == 1 ? singular : plural
    }
}


