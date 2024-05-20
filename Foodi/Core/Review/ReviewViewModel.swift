//
//  ReviewViewModel.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import Foundation

class ReviewsViewModel: ObservableObject {
    @Published var collections = [Review]()
    @Published var isLoading: Bool = false
    @Published var selectedRestaurant: Restaurant?
    init(restaurant: Restaurant? = nil) {
        self.selectedRestaurant = restaurant
    }
}
