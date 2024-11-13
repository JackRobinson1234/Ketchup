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
    var imageUrl: String?
    var color: Color? = .white
    let size: RestaurantImageSize
    var ratingScore: Double? = nil  // Optional rating score

    var body: some View {
        ZStack {
            ZStack {
                if let color = color {
                    Circle()
                        .fill(color)
                        .frame(width: size.dimension + 4, height: size.dimension + 4)
                }

                if let imageUrl, !imageUrl.isEmpty {
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

            // Overlay the rating score if provided
            if let ratingScore = ratingScore, ratingScore != 0 {
                VStack {
                    HStack {
                        Spacer()
                        Text(String(format: "%.1f", ratingScore))
                            .font(.custom("MuseoSansRounded-700", size: 11))
                            .foregroundColor(.black)
                            .padding(2)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white)
                                    .shadow(color: Color.gray.opacity(0.5), radius: 1, x: 0, y: 1)
                            )
                    }
                    Spacer()
                }
            }
        }
    }
}

struct RestaurantRectangleProfileImageView: View {
    var imageUrl: String?
    var color: Color? = .white
    let size: RestaurantImageSize
    var cornerRadius: CGFloat = 10 // Adjust this value for the desired corner radius

    var body: some View {
        ZStack {
            if let color = color {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color)
                    .frame(width: size.dimension + 4, height: size.dimension + 4)
            }

            if let imageUrl, !imageUrl.isEmpty {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.dimension, height: size.dimension)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                Image(systemName: "building.2.crop.circle.fill")
                    .resizable()
                    .frame(width: size.dimension, height: size.dimension)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .foregroundColor(Color(.systemGray5))
            }
        }
    }
}



#Preview {
    RestaurantCircularProfileImageView(size: .medium)
}
