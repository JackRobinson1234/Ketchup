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
    @ObservedObject var filtersViewModel: FiltersViewModel
    @StateObject private var mapSearch = MapSearch()
    @FocusState private var isFocused: Bool
    var autoCompleteNumber: Int = 4 // # of autocomplete suggestions
    
    var body: some View {
        // MARK: Title
        VStack{
            HStack{
                Text("Filter by Location")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            //MARK: Search
            /// if no filters are selected, search bar
            if filtersViewModel.selectedLocation.isEmpty{
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
                
                // MARK: Auto-complete results
                if isFocused == false {
                    ForEach(mapSearch.locationResults.prefix(autoCompleteNumber), id: \.self) { location in
                        Button {
                            reverseGeo(location: location)
                            print("test", location)
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
                }
            //MARK: Selected Restaurant
            } else {
                HStack{
                    HStack {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    filtersViewModel.selectedLocation.removeAll()
                                    filtersViewModel.selectedCity = ""
                                    filtersViewModel.selectedState = ""
                                }
                            }
                        Text("\(filtersViewModel.selectedCity), \(filtersViewModel.selectedState)")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 5)
                    Spacer()
                }
                
            }
                
        }
        .onChange(of: filtersViewModel.selectedLocation) {
            filtersViewModel.disableFilters()
        }
        
    }
    //MARK: ReverseGeo
    
    /// Takes in the selected MKLocalSearchCompletion value and makes it into a coordinate, the reverses that coordinate into a geocode to get the address information.
    /// - Parameter location: Selected MKocalSearchCompletion from the autocomplete suggestions
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
                    let city = "\(reversedGeoLocation.city)"
                    let state = "\(reversedGeoLocation.state)"
                    
                    mapSearch.searchTerm = ""
                    mapSearch.locationResults = []
                    ///adds the selected location to the view model
                    filtersViewModel.selectedLocation = [c]
                    filtersViewModel.selectedCity = city
                    filtersViewModel.selectedState = state
                    isFocused = false
                    
                }
            }
        }
    }
    
} // End Struct

#Preview{
    LocationFilter(filtersViewModel: FiltersViewModel(feedViewModel: FeedViewModel()))
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

