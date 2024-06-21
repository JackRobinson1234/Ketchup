//
//  CollectionItemCell.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI
import Kingfisher
import _MapKit_SwiftUI

struct CollectionItemCell: View {
    var item: CollectionItem
    var width: CGFloat = 190
    var previewMode: Bool = false ///hides notes icon
    @ObservedObject var viewModel: CollectionsViewModel
    var body: some View {
        ZStack {
            VStack(spacing: -50) {
                if let image = item.image{
                    ZStack{
                        KFImage(URL(string: image))
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: width)
                            .offset(y: -25)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                    }
                } else {
                    Image(systemName: "building.2.crop.circle.fill")
                        .resizable()
                        .frame(width: width, height: width)
                        .scaledToFill()
                        .offset(y: -25)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                }
                ZStack(alignment: .bottom){
                    Rectangle()
                        .frame(width: width, height: 70) // Height of the caption background
                        .foregroundColor(Color(.white)) // Light yellow background with opacity
                        .offset(y: 25)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Rectangle()
                        .frame(width: width, height: 70) // Height of the caption background
                        .foregroundColor(.gray.opacity(0.1)) // Light yellow background with opacity
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
}

#Preview {
    CollectionItemCell(item: DeveloperPreview.items[0], width: 200, viewModel: CollectionsViewModel(user: DeveloperPreview.user))
}


