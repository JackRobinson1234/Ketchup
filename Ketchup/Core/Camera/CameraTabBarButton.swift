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
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(isSelected ? .black : .gray)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            //.background(isSelected ? Color.white : Color.clear)
            .cornerRadius(20)
    }
}
