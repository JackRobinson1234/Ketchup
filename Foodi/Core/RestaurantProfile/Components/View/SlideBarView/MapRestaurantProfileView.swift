//
//  MapRestaurantProfileView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import MapKit
struct MapRestaurantProfileView: View {
    var body: some View {
        Map()
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MapRestaurantProfileView()
}
