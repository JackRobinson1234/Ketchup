//
//  CollectionItemCell.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI
import Kingfisher

struct CollectionItemCell: View {
    var item: CollectionItem
    var width: CGFloat = 190
    
    var body: some View {
        VStack(spacing: -50) {
            if let image = item.image{
                KFImage(URL(string: image))
                    .resizable()
                    .frame(width: width, height: width)
                    .scaledToFill()
                    .offset(y: -25)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            ZStack(alignment: .bottom){
                Rectangle()
                    .frame(width: width, height: 70) // Height of the caption background
                    .foregroundColor(item.postType == "restaurant" ? .gray.opacity(0.1): .blue.opacity(0.1)) // Light yellow background with opacity
                    .offset(y: 25)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack{
                    Text(item.name)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.black)
                        .lineLimit(1)
                    HStack{
                        if let city = item.city, let state = item.state {
                            Text("\(city), \(state)")
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(.black)
                        } else if let name = item.postUserFullname {
                            Text("by @\(name)")
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(.black)
                        } else if let city = item.city {
                            Text("\(city)")
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(.black)
                        } else if let state = item.state {
                            Text("\(state)")
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(.black)
                        }
                    }
                }
                .padding(7)
                }
        }
        .frame(width: width, height: width + 25)
    }
}

