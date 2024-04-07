//
//  GeoFireManager.swift
//  Foodi
//
//  Created by Jack Robinson on 4/6/24.
//

import GeoFire
import Firebase

class GeoFireManager {
    static let shared = GeoFireManager()

    let geoFire: GeoFire
    let geoFireRef: DatabaseReference

    private init() {
        geoFireRef = Database.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
    }
}
