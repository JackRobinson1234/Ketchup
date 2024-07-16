//
//  UserCircularImageProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Kingfisher

enum ProfileImageSize {
    case xxxSmall
    case xxSmall
    case xSmall
    case small
    case medium
    case large
    case xLarge
    case xxLarge
    case xxxLarge
    
    var dimension: CGFloat {
        switch self {
        case .xxxSmall: return 18
        case .xxSmall: return 28
        case .xSmall: return 32
        case .small: return 40
        case .medium: return 48
        case .large: return 64
        case .xLarge: return 80
        case .xxLarge: return 90
        case .xxxLarge: return UIScreen.main.bounds.width * 5 / 6
            
        }
    }
}

struct UserCircularProfileImageView: View {
    var profileImageUrl: String?
    let size: ProfileImageSize
    var color: Color? = nil
    
    var body: some View {
        ZStack {
            if let color = color {
                Circle()
                    .fill(color)
                    .frame(width: size.dimension + 4, height: size.dimension + 4)
            }
            
            if let imageUrl = profileImageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .circularProfileStyle(size: size)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .circularProfileStyle(size: size)
                    .foregroundColor(Color(.systemGray5))
            }
        }
    }
}

extension View {
    func circularProfileStyle(size: ProfileImageSize) -> some View {
        self
            .scaledToFill()
            .frame(width: size.dimension, height: size.dimension)
            .clipShape(Circle())
    }
}
