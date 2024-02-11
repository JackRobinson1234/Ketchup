//
//  RestaurantCircularProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//
import SwiftUI
import Kingfisher

enum RestaurantImageSize {
    case xxSmall
    case xSmall
    case small
    case medium
    case large
    case xLarge
    
    var dimension: CGFloat {
        switch self {
        case .xxSmall: return 28
        case .xSmall: return 32
        case .small: return 40
        case .medium: return 48
        case .large: return 64
        case .xLarge: return 80
        }
    }
}

struct RestaurantCircularProfileImageView: View {
    var restaurant: Restaurant?
    var color: Color? = .white
    let size: RestaurantImageSize
    var body: some View {
        ZStack{
            if let color = color{
                Circle()
                .fill(color)
                .frame(width: size.dimension + 4, height: size.dimension + 4)}
            if let imageUrl = restaurant?.profileImageUrl, !imageUrl.isEmpty {
                
            KFImage(URL(string: imageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(Circle())
        } else {
            Image(systemName: "building.2.crop.circle.fill")
                .resizable()
                .frame(width: size.dimension, height: size.dimension)
                .foregroundColor(Color(.systemGray5))
        }
        }
    }
}

#Preview {
    RestaurantCircularProfileImageView(size: .medium)
}
