//
//  CameraTabBar.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/8/24.
//

import SwiftUI

struct CameraTabBarButton: View {
    let text: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            if text == "Written" && isSelected {
                Text(text)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    
            } else {
                Text(text)
                    .foregroundColor(isSelected ? .white : .gray)
                    .padding(.horizontal, 20)
                    .font(.custom("MuseoSansRounded-300", size: 16))
            }

            if isSelected {
                if text == "Written" {
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(.gray)
                } else {
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundColor(.white)
                }
                
            } else {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(.clear)
            }
        }
        .frame(width: 100, height: 50)
    }
}

