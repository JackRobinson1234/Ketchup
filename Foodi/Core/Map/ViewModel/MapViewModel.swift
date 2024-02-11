//
//  MapViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 2/11/24.
//

/*protocol CoordinateProvider {
    func getCoordinates() -> [String: CLLocationCoordinate2D]
}*/

import Foundation
import MapKit
class MapViewModel: ObservableObject {
    @Published var restaurants = [String: CLLocationCoordinate2D]()
    
    private let restaurantService: RestaurantService
    private let postService: PostService
    
    init(restaurantService: RestaurantService, postService: PostService) {
        
        self.restaurantService = restaurantService
        self.postService = postService
    }
}
    
