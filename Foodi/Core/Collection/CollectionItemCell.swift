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
    var width: CGFloat = 175
    
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
                    .foregroundColor(Color.yellow.opacity(0.1)) // Light yellow background with opacity
                    .offset(y: 25)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack{
                        Text(item.name)
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.black)
                        if let city = item.city, let state = item.state {
                            Text("\(city), \(state)")
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(.black)
                        } else if let name = item.postUsername {
                            Text("by @\(name)")
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(.black)
                        }
                    }
                .padding(7)
                }
        }
        .frame(width: width, height: 200)
    }
}
#Preview {
    CollectionItemCell(item: (DeveloperPreview.collections[0].items?[1])!)
}



//VStack {
//    ZStack(alignment: .topTrailing) {
//        if let images = restaurant.imageURLs {
//            TabView {
//                ForEach(images, id: \.self) { image in
//                    KFImage(URL(string: image))
//                        .resizable()
//                        .scaledToFill()
//                        .clipShape(Rectangle())
//                }
//                }
//            .frame(height: 200)
//            .tabViewStyle(.page)
//        }
//    }
//    
//    HStack(alignment: .top) {
//        VStack(alignment: .leading) {
//            NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id)) {
//                Text("\(restaurant.name)")
//                    .font(.subheadline)
//                    .bold()
//                    .multilineTextAlignment(.leading)
//            }
//               
//            
//            Text("\(restaurant.city ?? ""), \(restaurant.state ?? "")")
//                .foregroundStyle(.gray)
//            Text("\(restaurant.cuisine ?? ""), \(restaurant.price ?? "")")
//                .foregroundStyle(.gray)
//        }
//        
//        Spacer()
//        NavigationLink(destination: RestaurantProfileView(restaurantId: restaurant.id, currentSection: .menu)) {
//                Text("View Menu")
//            }
//            .modifier(StandardButtonModifier(width: 150))
//            
//    }
//    .foregroundColor(.black)
//    .font(.footnote)
//    .padding(8)
//}
//.background(.white)
//.clipShape(RoundedRectangle(cornerRadius: 10))
//.padding()
//.frame(width: UIScreen.main.bounds.width)
//}
//}
//
//
//#Preview {
//MapRestaurantView(restaurant: DeveloperPreview.restaurants[0])
//}
