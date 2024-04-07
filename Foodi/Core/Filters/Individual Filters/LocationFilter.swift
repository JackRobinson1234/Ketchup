//
//  LocationFilter.swift
//  Foodi
//
//  Created by Jack Robinson on 4/6/24.
//
import SwiftUI
import Combine
import CoreLocation
import MapKit

struct LocationFilter: View {
    @StateObject private var mapSearch = MapSearch()


    // Form Variables

    @FocusState private var isFocused: Bool

    @State private var btnHover = false
    @State private var isBtnActive = false

    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""

// Main UI

    var body: some View {

            VStack {
                List {
                    
                    VStack{
                        HStack{
                            Text("Filter by Location")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        HStack{
                            Image(systemName: "magnifyingglass")
                                .imageScale(.small)
                            TextField("Search destinations", text: $mapSearch.searchTerm)
                                .font(.subheadline)
                                .frame(height:44)
                                .padding(.horizontal)
                        }
                        .frame(height: 44)
                        .padding(.horizontal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(lineWidth: 1.0)
                                .foregroundStyle(Color(.systemGray4))
                        )
                        
                        // Show auto-complete results
                        if address != mapSearch.searchTerm && isFocused == false {
                            ForEach(mapSearch.locationResults, id: \.self) { location in
                                Button {
                                    reverseGeo(location: location)
                                } label: {
                                    HStack{
                                        VStack(alignment: .leading) {
                                            Text(location.title)
                                                .foregroundColor(Color.black)
                                            Text(location.subtitle)
                                                .font(.system(.caption))
                                                .foregroundColor(Color.black)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }                         // End show auto-complete results
                        
                        
                    }

            } // End List

            } // End Main VStack

    } 
    private func reverseGeo(location: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: location)
        let search = MKLocalSearch(request: searchRequest)
        var coordinateK : CLLocationCoordinate2D?
        search.start { (response, error) in
        if error == nil, let coordinate = response?.mapItems.first?.placemark.coordinate {
            coordinateK = coordinate
        }

        if let c = coordinateK {
            let location = CLLocation(latitude: c.latitude, longitude: c.longitude)
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in

            guard let placemark = placemarks?.first else {
                let errorString = error?.localizedDescription ?? "Unexpected Error"
                print("Unable to reverse geocode the given location. Error: \(errorString)")
                return
            }

            let reversedGeoLocation = ReversedGeoLocation(with: placemark)

            address = "\(reversedGeoLocation.streetNumber) \(reversedGeoLocation.streetName)"
            city = "\(reversedGeoLocation.city)"
            state = "\(reversedGeoLocation.state)"
            zip = "\(reversedGeoLocation.zipCode)"
            mapSearch.searchTerm = ""
                mapSearch.locationResults = []
            isFocused = false

                }
            }
        }
    }

} // End Struct

#Preview{
    LocationFilter()
}

class MapSearch : NSObject, ObservableObject {
    @Published var locationResults : [MKLocalSearchCompletion] = []
    @Published var searchTerm = ""
    
    private var cancellables : Set<AnyCancellable> = []
    
    private var searchCompleter = MKLocalSearchCompleter()
    private var currentPromise : ((Result<[MKLocalSearchCompletion], Error>) -> Void)?

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = MKLocalSearchCompleter.ResultType([.address])
        
        $searchTerm
            .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMap({ (currentSearchTerm) in
                self.searchTermToResults(searchTerm: currentSearchTerm)
            })
            .sink(receiveCompletion: { (completion) in
                //handle error
            }, receiveValue: { (results) in
                self.locationResults = results.filter { $0.subtitle.contains("United States") } // This parses the subtitle to show only results that have United States as the country. You could change this text to be Germany or Brazil and only show results from those countries.
            })
            .store(in: &cancellables)
    }
    
    func searchTermToResults(searchTerm: String) -> Future<[MKLocalSearchCompletion], Error> {
        Future { promise in
            self.searchCompleter.queryFragment = searchTerm
            self.currentPromise = promise
        }
    }
}

extension MapSearch : MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            currentPromise?(.success(completer.results))
        }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        //could deal with the error here, but beware that it will finish the Combine publisher stream
        //currentPromise?(.failure(error))
    }
}

struct ReversedGeoLocation {
    let streetNumber: String    // eg. 1
    let streetName: String      // eg. Infinite Loop
    let city: String            // eg. Cupertino
    let state: String           // eg. CA
    let zipCode: String         // eg. 95014
    let country: String         // eg. United States
    let isoCountryCode: String  // eg. US

    var formattedAddress: String {
        return """
        \(streetNumber) \(streetName),
        \(city), \(state) \(zipCode)
        \(country)
        """
    }

    // Handle optionals as needed
    init(with placemark: CLPlacemark) {
        self.streetName     = placemark.thoroughfare ?? ""
        self.streetNumber   = placemark.subThoroughfare ?? ""
        self.city           = placemark.locality ?? ""
        self.state          = placemark.administrativeArea ?? ""
        self.zipCode        = placemark.postalCode ?? ""
        self.country        = placemark.country ?? ""
        self.isoCountryCode = placemark.isoCountryCode ?? ""
    }
}

