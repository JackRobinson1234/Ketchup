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
    var body: some View {
        VStack{
            Button{setupGeofire()}
        label: {Text("Test")}
            Button{fetchLocation()}
        label: {Text("Test")}
        }
    }
    func setupGeofire() {
        let geofireRef = Database.database().reference()
        let geoFire = GeoFire(firebaseRef: geofireRef)
        geoFire.setLocation(CLLocation(latitude: 34.0168871, longitude: -118.5013209), forKey: "VSi3d9KUlIsEc60rhAZs") { (error) in
            if (error != nil) {
                print("An error occured: \(error)")
            } else {
                print("Saved location successfully!")
            }
        }
    }
    func fetchLocation() {
        let geofireRef = Database.database().reference()
        let geoFire = GeoFire(firebaseRef: geofireRef)
        let center = CLLocation(latitude: 37.7832889, longitude: -122.4056973)
        let radius = 0.6 // in kilometers
        
        // Query locations within the specified radius from the center
        let circleQuery = geoFire.query(at: center, withRadius: radius)
        circleQuery.observe(.keyEntered, with: { (key, location) in
            print("Key: \(key), Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        })
    }
}
#Preview {
    ActivityView()
}
