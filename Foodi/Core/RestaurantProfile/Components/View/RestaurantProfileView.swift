//
//  RestaurantProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import SwiftUI

struct RestaurantProfileView: View {
    var body: some View {
        
        VStack{
            RestaurantProfileHeaderView()
        }
        .overlay(alignment: .bottom) {
            CTAButtonOverlay()
        }
    }
}

#Preview {
    RestaurantProfileView()
}
