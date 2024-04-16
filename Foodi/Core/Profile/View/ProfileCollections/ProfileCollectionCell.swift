//
//  ProfileCollectionCell.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI

struct ProfileCollectionCell: View {
    var collection: Collection
    var body: some View {
        HStack{
            Image(systemName: "folder")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
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
    ProfileCollectionCell(collection: DeveloperPreview.collections[0])
}
