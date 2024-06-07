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
    var body: some View {
        HStack{
            if let imageUrl = collection.coverImageUrl  {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Rectangle())
                    .cornerRadius(10)
            } else {
                Image(systemName: "folder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height:size)
            }
            VStack(alignment: .leading){
                Text(collection.name)
                    .font(.title3)
                    .bold()
                    .lineLimit(1)
                    itemCountText(for: collection)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                Text("By \(collection.username)")
                    .font(.caption)
                    .lineLimit(1)
                if let description = collection.description {
                    Text(description)
                        .font(.caption)
                        .lineLimit(1)
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
    let atHomeCount = collection.atHomeCount
    let itemCountText: String
    if restaurantCount == 0 && atHomeCount == 0 {
        itemCountText = "0 Items"
    } else {
        itemCountText = "\(restaurantCount > 0 ? "\(restaurantCount) \(pluralText(for: restaurantCount, singular: "Restaurant", plural: "Restaurants"))" : "")\(restaurantCount > 0 && atHomeCount > 0 ? ", " : "")\(atHomeCount > 0 ? "\(atHomeCount) \(pluralText(for: atHomeCount, singular: "At Home Post", plural: "At Home Posts"))" : "")"
    }
    
    return Text(itemCountText)
}
private func pluralText(for count: Int, singular: String, plural: String) -> String {
    return count == 1 ? singular : plural
}
}

#Preview {
    CollectionListCell(collection: DeveloperPreview.collections[0])
}
