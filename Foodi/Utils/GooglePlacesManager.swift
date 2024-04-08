//
//  GooglePlacesManager.swift
//  Foodi
//
//  Created by Jack Robinson on 4/6/24.
//

import Foundation
import GooglePlaces 


struct Place {
    let name: String
    let identifier: String
}
final class GooglePlacesManager {
    static let shared = GooglePlacesManager()
    private let client = GMSPlacesClient.shared()
    private init() {}
    
    enum PlacesError: Error {
        case failedToFind
    }
    //TODO: Add Fields
    public func findPlaces(query: String, completion: @escaping (Result<[Place], Error>) -> Void) {
        let filter = GMSAutocompleteFilter()
        filter.countries = ["US"]
        filter.types = ["geocode"]
        client.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: nil){ results, error in
            guard let results = results, error == nil else {completion(.failure(PlacesError.failedToFind))
            return }
            let places: [Place] = results.compactMap({
                Place(name: $0.attributedFullText.string, identifier: $0.placeID)
            })
            completion(.success(places))
        }
    }
}

