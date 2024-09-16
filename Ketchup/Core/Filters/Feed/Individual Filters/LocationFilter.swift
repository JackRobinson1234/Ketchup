//
//  LocationFilter.swift
//  Foodi
//  Created by Jack Robinson on 4/6/24.
//
import SwiftUI
import Combine
import CoreLocation
import MapKit

struct LocationFilter: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var filtersViewModel: FiltersViewModel
    @StateObject private var mapSearch = MapSearch()
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Current Location")
                .font(.custom("MuseoSansRounded-300", size: 22))
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.blue)
                Text("\(filtersViewModel.city ?? "Unknown"), \(filtersViewModel.state ?? "")")
                    .font(.custom("MuseoSansRounded-300", size: 16))
            }
            
            Text("Search Other Locations")
                .font(.custom("MuseoSansRounded-300", size: 22))
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search destinations", text: $mapSearch.searchTerm)
                    .font(.custom("MuseoSansRounded-300", size: 16))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if !mapSearch.searchTerm.isEmpty {
                List(mapSearch.locationResults.prefix(5), id: \.self) { location in
                    Button(action: {
                        selectLocation(location)
                    }) {
                        VStack(alignment: .leading) {
                            Text(location.title)
                            Text(location.subtitle)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationBarItems(trailing: Button("Save") {
            saveFilters()
            dismiss()
        })
    }
    
    private func selectLocation(_ location: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: location)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            filtersViewModel.updateLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            mapSearch.searchTerm = ""
        }
    }
    
    private func saveFilters() {
        Task {
            await filtersViewModel.fetchFilteredPosts()
        }
    }
} 


//MARK: ViewModel
/// Taken from "stackoverflow.com/questions/70571615/swiftui-using-mapkit-for-address-auto-complete"
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
