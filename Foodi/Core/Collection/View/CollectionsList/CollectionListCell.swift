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
    var size: CGFloat = 50
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
                Text("By \(collection.username)")
                    .font(.caption)
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
}

#Preview {
    CollectionListCell(collection: DeveloperPreview.collections[0])
}
