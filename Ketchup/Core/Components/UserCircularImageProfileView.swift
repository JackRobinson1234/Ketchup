//
//  UserCircularImageProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Kingfisher

enum ProfileImageSize {
    case xxSmall
    case xSmall
    case small
    case medium
    case large
    case xLarge
    case xxLarge
    
    var dimension: CGFloat {
        switch self {
        case .xxSmall: return 28
        case .xSmall: return 32
        case .small: return 40
        case .medium: return 48
        case .large: return 64
        case .xLarge: return 80
        case .xxLarge: return 90
        }
    }
}

struct UserCircularProfileImageView: View {
    var profileImageUrl: String?
    let size: ProfileImageSize
    var color: Color? = nil
    
    var body: some View {
        if let imageUrl = profileImageUrl {
            ZStack{
                if let color = color{
                    Circle()
                        .fill(color)
                    .frame(width: size.dimension + 4, height: size.dimension + 4)}
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.dimension, height: size.dimension)
                    .clipShape(Circle())
            }
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: size.dimension, height: size.dimension)
                .foregroundColor(Color(.systemGray5))
        }
    }
}

#Preview {
    UserCircularProfileImageView(size: .medium)
}
