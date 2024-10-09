//
//  CreateRestaurantView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/14/24.
//

import SwiftUI
import FirebaseFirestoreInternal
import FirebaseAuth
import GeoFire
import Firebase

struct AddRestaurantView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var uploadViewModel: UploadViewModel
    @State private var name: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @Binding var dismissRestaurantList: Bool
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var scrapedRestaurants: [[String: Any]] = []
    @State private var isScraping = false
    @State private var buttonText = "Search"
    @State private var scrapeTask: URLSessionDataTask?
    @State private var selectedRestaurant: [String: Any]? = nil
    @State private var showConfirmationCover = false
    @State private var actorRunId: String? = nil  // Store the actor run ID
    @State private var continueWithRequest: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    TextField("Restaurant Name", text: $name)
                        .padding()
                    Divider()
                    TextField("City", text: $city)
                        .padding()
                    Divider()
                    TextField("State", text: $state)
                        .padding()
                    Divider()
                    
                    if isScraping {
                        VStack {
                            FastCrossfadeFoodImageView()
                                .padding(5)
                            Text("Gathering restaurant data, this may take 30 seconds.")
                        }
                    }
                    
                    Button {
                        if isScraping {
                            cancelScrape()
                        } else if isSubmitButtonDisabled {
                            showAlert.toggle()
                            alertMessage = "Please fill out all required fields before submitting."
                        } else {
                            submitRestaurantDetails()
                        }
                    } label: {
                        Text(buttonText)
                            .modifier(OutlineButtonModifier(width: 300))
                    }
                    .opacity(isSubmitButtonDisabled && !isScraping ? 0.5 : 1.0)
                    .padding()
                    .alert("Notification", isPresented: $showAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(alertMessage)
                    }
                    
                    Text("If searching for a new restaurant finds no results, no worries! You can continue with your post by requesting a restaurant.")
                        .font(.custom("MuseoSansRounded-300", size: 12))
                        .padding(.horizontal)
                        .foregroundStyle(.gray)
                    
                    Button {
                        if isScraping {
                            showAlert.toggle()
                            alertMessage = "Please wait until the scraping process is complete before proceeding."
                        } else if isSubmitButtonDisabled {
                            showAlert.toggle()
                            alertMessage = "Please fill out all required fields before continuing."
                        } else {
                            continueWithRequest.toggle()
                            if continueWithRequest {
                                submitRestaurantRequest()
                            }
                        }
                    } label: {
                        VStack {
                            Text("Continue by Requesting Restaurant")
                                .foregroundStyle(Color("Colors/AccentColor"))
                                .font(.custom("MuseoSansRounded-300", size: 12))
                        }
                    }

                    
                }
                .padding(.vertical)
            }
            .modifier(BackButtonModifier())
            .navigationBarTitle("Add New Restaurant", displayMode: .inline)
            .fullScreenCover(isPresented: $showConfirmationCover) {
                ConfirmRestaurantView(
                    scrapedRestaurants: scrapedRestaurants,
                    selectedRestaurant: $selectedRestaurant,
                    name: name,
                    city: city,
                    state: state,
                    uploadViewModel: uploadViewModel,
                    dismiss: {
                        showConfirmationCover = false
                        if let selectedRestaurant = selectedRestaurant {
                            dismissRestaurantList = true
                            dismiss()
                        }
                    }
                )
            }
        }
    }

    func submitRestaurantDetails() {
        isScraping = true
        buttonText = "Cancel"
        
        startActorRun(name: name, city: city, state: state) { result in
            DispatchQueue.main.async {
                isScraping = false
                buttonText = "Search"
                
                switch result {
                case .success(let data):
                    if data.isEmpty {
                        showAlert = true
                        alertMessage = "No Results Found"
                    } else {
                        scrapedRestaurants = data
                        showConfirmationCover = true
                    }
                case .failure(let error):
                    showAlert = true
                    alertMessage = "Error: \(error.localizedDescription)"
                    ////print("Error scraping restaurant: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func submitRestaurantRequest() {
        let newRestaurantRequest = RestaurantRequest(
            id: UUID().uuidString,
            userid: Auth.auth().currentUser!.uid,  // Ensure the user is logged in
            name: name,
            state: state,
            city: city,
            timestamp: Timestamp(),
            postType: "Post"
        )
        uploadViewModel.restaurantRequest = newRestaurantRequest
        uploadViewModel.restaurant = nil
        dismissRestaurantList = true
        dismiss()
    }

    func startActorRun(name: String, city: String, state: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let actorId = "compass~google-maps-extractor"
        let url = URL(string: "https://api.apify.com/v2/acts/\(actorId)/runs?token=apify_api_Q2H4ps9lrqxTVJ18aQFmevTFJBsR2y2kE8Xq")!
        
        let requestData: [String: Any] = [
            //"categoryFilterWords": ["restaurant", "bar", "cafe"],
            "searchStringsArray": ["\(name), \(city), \(state)"],
            "deeperCityScrape": true,
            "language": "en",
            "maxCrawledPlacesPerSearch": 3,
            "skipClosedPlaces": true,
            "searchMatching": "all",
            "placeMinimumStars": "",
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestData, options: [])
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        scrapeTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                ////print("Scrape request was cancelled.")
                return
            } else if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let runId = (jsonResponse["data"] as? [String: Any])?["id"] as? String {
                    actorRunId = runId  // Store the actor run ID
                    pollRunStatus(runId: runId, completion: completion)
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        scrapeTask?.resume()
    }
    
    func pollRunStatus(runId: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let statusUrl = URL(string: "https://api.apify.com/v2/actor-runs/\(runId)?token=apify_api_Q2H4ps9lrqxTVJ18aQFmevTFJBsR2y2kE8Xq")!
        
        scrapeTask = URLSession.shared.dataTask(with: statusUrl) { data, response, error in
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                ////print("Polling request was cancelled.")
                return
            } else if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let status = (jsonResponse["data"] as? [String: Any])?["status"] as? String {
                    if status == "SUCCEEDED" {
                        fetchRunData(runId: runId, completion: completion)
                    } else if status == "FAILED" {
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Run failed"])))
                    } else if status == "ABORTED" {
                      return
                    } else {
                        ////print("Run is still in progress...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.pollRunStatus(runId: runId, completion: completion)
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        scrapeTask?.resume()
    }
    
    func fetchRunData(runId: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let statusUrl = URL(string: "https://api.apify.com/v2/actor-runs/\(runId)?token=apify_api_Q2H4ps9lrqxTVJ18aQFmevTFJBsR2y2kE8Xq")!
        
        scrapeTask = URLSession.shared.dataTask(with: statusUrl) { data, response, error in
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                ////print("Data fetch request was cancelled.")
                return
            } else if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let datasetId = (jsonResponse["data"] as? [String: Any])?["defaultDatasetId"] as? String {
                    fetchDatasetItems(datasetId: datasetId, completion: completion)
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        scrapeTask?.resume()
    }
    
    func fetchDatasetItems(datasetId: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        let dataUrl = URL(string: "https://api.apify.com/v2/datasets/\(datasetId)/items?token=apify_api_Q2H4ps9lrqxTVJ18aQFmevTFJBsR2y2kE8Xq&format=json")!
        
        scrapeTask = URLSession.shared.dataTask(with: dataUrl) { data, response, error in
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                ////print("Data fetch request was cancelled.")
                return
            } else if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let result = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    completion(.success(result))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        scrapeTask?.resume()
    }
    
    func cancelScrape() {
        scrapeTask?.cancel()
        if let runId = actorRunId {
            abortActorRun(runId: runId)
        }
        isScraping = false
        buttonText = "Search"
        ////print("Scraping process has been canceled.")
    }
    
    func abortActorRun(runId: String) {
        let abortUrl = URL(string: "https://api.apify.com/v2/actor-runs/\(runId)/abort?token=apify_api_Q2H4ps9lrqxTVJ18aQFmevTFJBsR2y2kE8Xq")!
        
        var request = URLRequest(url: abortUrl)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                ////print("Error aborting actor run: \(error.localizedDescription)")
            } else {
                ////print("Actor run \(runId) aborted successfully.")
            }
        }
        
        task.resume()
    }
    
    private var isSubmitButtonDisabled: Bool {
        name.isEmpty || city.isEmpty || state.isEmpty
    }
}

struct ConfirmRestaurantView<T: RestaurantUploadable>: View {
    let scrapedRestaurants: [[String: Any]]
    @Binding var selectedRestaurant: [String: Any]?
    var name: String
    var city: String
    var state: String
    @ObservedObject var uploadViewModel: T
    let dismiss: () -> Void
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Button {
                    dismiss()
                } label: {
                    VStack {
                        Text("Still not what you're looking for?")
                            .foregroundStyle(.gray)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                        Text("Continue with post")
                            .foregroundStyle(Color("Colors/AccentColor"))
                            .font(.custom("MuseoSansRounded-300", size: 10))
                    }
                }
                .padding(.top, 8)
                
                List(scrapedRestaurants.indices, id: \.self) { index in
                    let restaurant = scrapedRestaurants[index]
                    if let title = restaurant["title"] as? String,
                       let address = restaurant["address"] as? String,
                       let imageUrl = restaurant["imageUrl"] as? String,
                       let category = restaurant["categoryName"] as? String {
                        
                        Button(action: {
                            if selectedRestaurant?["title"] as? String == title && selectedRestaurant?["address"] as? String == address {
                                selectedRestaurant = nil
                            } else {
                                selectedRestaurant = restaurant
                            }
                        }) {
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 50, height: 50)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(title)
                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                        .fontWeight(.semibold)
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(.black)
                                    
                                    Text(category)
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(.black)
                                    
                                    Text(address)
                                        .font(.custom("MuseoSansRounded-300", size: 10))
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(.black)
                                }
                                .foregroundStyle(.black)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.black)
                                    .padding([.leading, .trailing])
                            }
                            .padding()
                            .background(
                                selectedRestaurant?["title"] as? String == title && selectedRestaurant?["address"] as? String == address
                                ? Color("Colors/AccentColor").opacity(0.2)
                                : Color.clear
                            )
                        }
                    }
                }
                
                Button(action: {
                    if let selectedRestaurant = selectedRestaurant {
                        let cleanedRestaurant = cleanRestaurantData(restaurant: selectedRestaurant)
                        uploadRestaurantToFirebase(restaurantData: cleanedRestaurant)
                    }
                }) {
                    Text("Confirm")
                        .fontWeight(.semibold)
                        .modifier(OutlineConfirmButtonModifier(width: 300))
                        .opacity(selectedRestaurant == nil ? 0.2 : 1.0)
                }
                .disabled(selectedRestaurant == nil)
                .padding()
                
            }
            .navigationBarTitle("Confirm Restaurant", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }

        }
    }
    
    func uploadRestaurantToFirebase(restaurantData: [String: Any]) {
        guard let matchingId = restaurantData["matchingId"] as? String else {
            ////print("Matching ID is missing, cannot proceed.")
            return
        }
        
        let query = FirestoreConstants.RestaurantCollection
            .whereField("matchingId", isEqualTo: matchingId)
        
        query.getDocuments { (snapshot, error) in
            if let error = error {
                ////print("Error querying Firestore: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = snapshot, let document = snapshot.documents.first {
                // Restaurant with the same matchingId already exists
                DispatchQueue.main.async {
                    ////print("MATCHING ID FOUND: Using Existing Restaurant")
                    if let existingRestaurant = self.mapToRestaurant(from: document.data()) {
                        self.uploadViewModel.restaurant = existingRestaurant
                        // Dismiss the view after setting the existing restaurant
                        self.dismiss()
                    }
                }
            } else {
                // No existing restaurant found, proceed with upload
                let newDocRef = FirestoreConstants.RestaurantCollection.document()
                var restaurantDataWithId = restaurantData
                restaurantDataWithId["id"] = newDocRef.documentID
                
                newDocRef.setData(restaurantDataWithId, merge: true) { error in
                    if let error = error {
                        ////print("Error uploading restaurant: \(error.localizedDescription)")
                    } else {
                        ////print("Restaurant uploaded successfully with id \(newDocRef.documentID)")
                        if let updatedRestaurant = self.mapToRestaurant(from: restaurantDataWithId) {
                            self.uploadViewModel.restaurant = updatedRestaurant
                            if let collectionsViewModel = self.uploadViewModel as? CollectionsViewModel {
                                let collectionItem = collectionsViewModel.convertRestaurantToCollectionItem(restaurant: updatedRestaurant)
                                Task {
                                    try await collectionsViewModel.addItemToCollection(collectionItem: collectionItem)
                                }
                            }
                        }
                        // Dismiss the view after successful upload
                        self.dismiss()
                    }
                }
            }
        }
    }


    
    
    func cleanRestaurantData(restaurant: [String: Any]) -> [String: Any] {
        // Specify the keys to keep, equivalent to the `keep_columns` in your Python script
        ////print("in clean func")
        let keepKeys: Set<String> = [
            "name", "bio", "categoryName", "categories", "subCategories", "reviewsTags", "price",
            "address", "neighborhood", "street", "city", "postalCode", "state", "countryCode", "location",
            "plusCode", "parentPlaceUrl", "locatedIn", "website", "phone", "additionalInfo", "url", "menuUrl",
            "reserveTableUrl", "googleFoodUrl", "tableReservationLinks", "orderBy", "permanentlyClosed",
            "temporarilyClosed", "openingHours", "updatesFromCustomers", "peopleAlsoSearch",
            "popularTimesHistogram", "imageUrl", "scrapedAt", "cid", "profileImageUrl", "geoPoint",
            "geoHash", "matchingId", "stats", "mergedCategories"
        ]
        
        // Create a cleaned dictionary containing only the keys specified in `keepKeys`
        var cleanedRestaurant: [String: Any] = [:]
        
        // Rename and keep relevant fields
        if let subCategories = restaurant["imageCategories"] {
            cleanedRestaurant["subCategories"] = subCategories
        }
        if let menuUrl = restaurant["menu"] {
            cleanedRestaurant["menuUrl"] = menuUrl
        }
        if let name = restaurant["title"] {
            cleanedRestaurant["name"] = name
        }
        if let bio = restaurant["description"] {
            cleanedRestaurant["bio"] = bio
        }
        
        // Add other fields that match the keepKeys
        for (key, value) in restaurant {
            if keepKeys.contains(key) {
                cleanedRestaurant[key] = value
            }
        }
        
        // Remove unwanted categories
        if let categoryName = cleanedRestaurant["categoryName"] as? String, categoriesToExclude.contains(categoryName) {
            return [:] // Return an empty dictionary if the category is to be excluded
        }
        
        // Clean subCategories
        if let subCategories = cleanedRestaurant["subCategories"] as? [String] {
            cleanedRestaurant["subCategories"] = cleanImageCategories(categories: subCategories)
        }
        
        // Create profile photo URL
        if let imageUrl = cleanedRestaurant["imageUrl"] as? String {
            cleanedRestaurant["profileImageUrl"] = imageUrl
        }
        
        // Initialize stats
        cleanedRestaurant["stats"] = ["collectionCount": 0, "postCount": 0]
        
        // Merge categories
        cleanedRestaurant["mergedCategories"] = mergeCategories(data: cleanedRestaurant)
        
        // Create geoPoint and geoHash
        if let location = cleanedRestaurant["location"] as? [String: Double] {
            let geoPoint = convertToGeoPoint(location: location)
            cleanedRestaurant["geoPoint"] = geoPoint
            cleanedRestaurant["geoHash"] = calculateGeoHash(geoPoint: geoPoint)
        }
        
        // Generate matching ID
        if let name = cleanedRestaurant["name"] as? String, let location = cleanedRestaurant["location"] as? [String: Double] {
            cleanedRestaurant["matchingId"] = generateMatchingId(name: name, location: location)
        }
        
        // Return only the keys that are in keepKeys
        return cleanedRestaurant.filter { keepKeys.contains($0.key) }
    }
    
    
    func cleanImageCategories(categories: [String]) -> [String] {
        let dropWords = ["All", "Latest", "Vibe", "By owner", "Street View & 360°", "Menu", "Videos", "Food & drink"]
        return categories.filter { !dropWords.contains($0) }
    }
    
    
    func mergeCategories(data: [String: Any]) -> [String] {
        var mergedSet = Set<String>()
        if let categoryName = data["categoryName"] as? String {
            mergedSet.insert(categoryName)
        }
        if let categories = data["categories"] as? [String] {
            mergedSet.formUnion(categories)
        }
        if let subCategories = data["subCategories"] as? [String] {
            mergedSet.formUnion(subCategories)
        }
        return Array(mergedSet)
    }
    
    func convertToGeoPoint(location: [String: Double]) -> GeoPoint {
        return GeoPoint(latitude: location["lat"] ?? 0.0, longitude: location["lng"] ?? 0.0)
    }
    
    func calculateGeoHash(geoPoint: GeoPoint) -> String {
        return GFUtils.geoHash(forLocation: CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude))
    }
    
    func generateMatchingId(name: String, location: [String: Double]) -> String {
        let cleanedName = name.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        return "\(cleanedName)_\(round(location["lat"] ?? 0.0, to: 4))_\(round(location["lng"] ?? 0.0, to: 4))".lowercased()
    }
    
    func round(_ value: Double, to decimalPlaces: Int) -> Double {
        let multiplier = pow(10.0, Double(decimalPlaces))
        return Foundation.round(value * multiplier) / multiplier
    }
    
    let categoriesToExclude = [
        "Eyebrow Bar", "Supermarket"
    ]
    
    
    func mapToRestaurant(from data: [String: Any]) -> Restaurant? {
        guard let name = data["name"] as? String else {
            ////print("Failed to extract name")
            return nil
        }
        ////print("Extracted name: \(name)")
        
        // Create RestaurantStats directly
        let statsDict = data["stats"] as? [String: Int] ?? [:]
        ////print("Extracted statsDict: \(statsDict)")
        
        let stats = RestaurantStats(postCount: statsDict["postCount"] ?? 0, collectionCount: statsDict["collectionCount"] ?? 0)
        ////print("Created stats: \(stats)")
        
        let geoPoint: GeoPoint?
        if let location = data["location"] as? [String: Double], let lat = location["lat"], let lng = location["lng"] {
            geoPoint = GeoPoint(latitude: lat, longitude: lng)
            ////print("Extracted GeoPoint: \(geoPoint!)")
        } else {
            geoPoint = nil
            ////print("GeoPoint is nil")
        }
        
        // Constructing the Restaurant object without the id
        let restaurant = Restaurant(
            id: data["id"] as? String ?? "placeholderId",
            categoryName: data["categoryName"] as? String,
            price: data["price"] as? String,
            name: name,
            geoPoint: geoPoint,
            geoHash: data["geoHash"] as? String,
            address: data["address"] as? String,
            city: data["city"] as? String,
            state: data["state"] as? String,
            imageURLs: data["imageUrls"] as? [String],
            profileImageUrl: data["profileImageUrl"] as? String,
            bio: data["bio"] as? String,
            _geoloc: geoLoc(lat: geoPoint?.latitude ?? 0, lng: geoPoint?.longitude ?? 0),
            stats: stats,
            additionalInfo: data["additionalInfo"] as? AdditionalInfo,
            categories: data["categories"] as? [String],
            containsMenuImage: data["containsMenuImage"] as? Bool,
            countryCode: data["countryCode"] as? String,
            googleFoodUrl: data["googleFoodUrl"] as? String,
            locatedIn: data["locatedIn"] as? String,
            menuUrl: data["menuUrl"] as? String,
            neighborhood: data["neighborhood"] as? String,
            openingHours: data["openingHours"] as? [OpeningHour],
            orderBy: data["orderBy"] as? [OrderBy],
            parentPlaceUrl: data["parentPlaceUrl"] as? String,
            peopleAlsoSearch: data["peopleAlsoSearch"] as? [PeopleAlsoSearch],
            permanentlyClosed: data["permanentlyClosed"] as? Bool,
            phone: data["phone"] as? String,
            plusCode: data["plusCode"] as? String,
            popularTimesHistogram: data["popularTimesHistogram"] as? PopularTimesHistogram,
            reviewsTags: data["reviewsTags"] as? [ReviewTag],
            scrapedAt: data["scrapedAt"] as? String,
            street: data["street"] as? String,
            subCategories: data["subCategories"] as? [String],
            temporarilyClosed: data["temporarilyClosed"] as? Bool,
            url: data["url"] as? String,
            website: data["website"] as? String,
            mergedCategories: data["mergedCategories"] as? [String],
            ratingStats: data["ratingStats"] as? RatingStats
        )
        return restaurant
    }
    
    
    
}

struct OutlineConfirmButtonModifier: ViewModifier {
    let width: CGFloat
    
    func body(content: Content) -> some View {
        content
            .frame(width: width, height: 44)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("Colors/AccentColor"), lineWidth: 2)
            )
            .cornerRadius(8)
    }
}


protocol RestaurantUploadable: ObservableObject {
    var restaurantRequest: RestaurantRequest? { get set }
    var restaurant: Restaurant? { get set }
    
    // Add any other common properties or methods needed by ConfirmRestaurantView
}

extension UploadViewModel: RestaurantUploadable {}
extension CollectionsViewModel: RestaurantUploadable {}
