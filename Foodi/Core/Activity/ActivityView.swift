//
//  ActivityView.swift
//  Foodi
//
//  Created by Jack Robinson on 3/8/24.
//

import SwiftUI
import FirebaseDatabase
import GeoFire


struct ActivityView: View {
        
        init() {
        }
        
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}
func setupGeofire() {
    let geofireRef = Database.database().reference()
    let geoFire = GeoFire(firebaseRef: geofireRef)
}
#Preview {
    ActivityView()
}
