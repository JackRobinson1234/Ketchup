//
//  CollectionRequestRestaurantView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/18/24.
//

import SwiftUI
import FirebaseFirestoreInternal
import FirebaseAuth
import Firebase
import GeoFire

struct CollectionAddRestaurantView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @State private var name: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @Binding var dismissListView: Bool
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var scrapedRestaurants: [[String: Any]] = []
    @State private var isScraping = false
    @State private var buttonText = "Search"
    @State private var scrapeTask: URLSessionDataTask?
    @State private var selectedRestaurant: [String: Any]? = nil
    @State private var showConfirmationCover = false
    @State private var actorRunId: String? = nil
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
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $collectionsViewModel.notes)
                            .frame(height: 100)
                            .padding(4)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        dismissKeyboard()
                                    }
                                }
                            }
                        
                        if collectionsViewModel.notes.isEmpty {
                            Text("Add some notes...")
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                        }
                    }
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
                    VStack {}
                    Text("If searching for a new restaurant finds no results, no worries! You can continue by adding to collection by requesting a restaurant.")
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
                            Task {
                                await submitRestaurantRequest()
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
            .navigationBarTitle("Add Restaurant to Collection", displayMode: .inline)
            .fullScreenCover(isPresented: $showConfirmationCover) {
                ConfirmRestaurantView(
                    scrapedRestaurants: scrapedRestaurants,
                    selectedRestaurant: $selectedRestaurant,
                    name: name,
                    city: city,
                    state: state,
                    uploadViewModel: collectionsViewModel,  // Adjust to use collectionsViewModel if necessary
                    dismiss: {
                        showConfirmationCover = false
                        if let selectedRestaurant = selectedRestaurant {
                            dismissListView = true
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
                    print("Error scraping restaurant: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func submitRestaurantRequest() async {
        do {
            let newRestaurantRequest = RestaurantRequest(
                id: UUID().uuidString,
                userid: Auth.auth().currentUser!.uid,  // Ensure the user is logged in
                name: name,
                state: state,
                city: city,
                timestamp: Timestamp(),
                postType: "CollectionItem"
            )
            collectionsViewModel.restaurantRequest = newRestaurantRequest
            collectionsViewModel.restaurant = nil
            try await collectionsViewModel.addItemToCollection(collectionItem: collectionsViewModel.convertRequestToCollectionItem(name: name, city: city, state: state))
            dismissListView = true
            dismiss()
        } catch {
            print("Failed to add restaurant to collection: \(error.localizedDescription)")
            // You can show an alert here if needed
            alertMessage = "Failed to add restaurant to collection."
            showAlert = true
        }
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
                print("Scrape request was cancelled.")
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
                print("Polling request was cancelled.")
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
                        print("Run is still in progress...")
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
                print("Data fetch request was cancelled.")
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
                print("Data fetch request was cancelled.")
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
        print("Scraping process has been canceled.")
    }
    
    func abortActorRun(runId: String) {
        let abortUrl = URL(string: "https://api.apify.com/v2/actor-runs/\(runId)/abort?token=apify_api_Q2H4ps9lrqxTVJ18aQFmevTFJBsR2y2kE8Xq")!
        
        var request = URLRequest(url: abortUrl)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error aborting actor run: \(error.localizedDescription)")
            } else {
                print("Actor run \(runId) aborted successfully.")
            }
        }
        
        task.resume()
    }

    private var isSubmitButtonDisabled: Bool {
        name.isEmpty || city.isEmpty || state.isEmpty
    }
}
