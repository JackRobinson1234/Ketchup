//
//  ReviewCreateRestaurantView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/18/24.
//

import SwiftUI
import FirebaseFirestoreInternal
import FirebaseAuth

struct ReviewCreateRestaurantView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var reviewsViewModel: ReviewsViewModel
    @State private var name: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State var selectedItem: CollectionItem?
    @State private var showAlert = false
    @Binding var dismissListView: Bool
   
    
    var body: some View {
        NavigationStack{
            ZStack{
            VStack {
                TextField("Restaurant Name", text: $name)
                    .padding()
                Divider()
                TextField("City", text: $city)
                    .padding()
                Divider()
                TextField("State", text: $state)                            .padding()
                Divider()
                
                Button {
                    if isSubmitButtonDisabled {
                        showAlert.toggle()
                    } else {
                        Task{ try await
                            submitRestaurantDetails()
                        }
                        //reviewsViewModel.dismissListView = true
                        dismiss()
                    }
                } label: {
                    Text("Add Restaurant and Write a Review")
                        .modifier(OutlineButtonModifier(width: 300))
                }
                .opacity(isSubmitButtonDisabled ? 0.5 : 1.0)
                .padding()
                .alert("Missing Fields", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Please fill out all required fields before submitting.")
                }
                Text("The Ketchup team will update your restaurant profile request within 48 hours! Your post can still be posted now.")
                    .font(.footnote)
                    .padding(.horizontal)
                    .foregroundStyle(.gray)
            }
        }
            .padding(.vertical)
            .modifier(BackButtonModifier())
            .navigationBarTitle("Request New Restaurant", displayMode: .inline)
            
        }
    }
    
    func submitRestaurantDetails() async throws{
        let newRestaurantRequest = RestaurantRequest(
            id: UUID().uuidString,
            userid: Auth.auth().currentUser!.uid,  // Replace with actual user ID
            name: name,
            state: state,
            city: city,
            timestamp: Timestamp(),
            postType: "CollectionItem"
        )
        dismissListView = true
        reviewsViewModel.restaurantRequest = newRestaurantRequest
        reviewsViewModel.selectedRestaurant = convertRestaurantRequestToRestaurant(request: newRestaurantRequest)
    }
    
    private var isSubmitButtonDisabled: Bool {
        // Check if any of the required fields are empty
        name.isEmpty || city.isEmpty || state.isEmpty
    }
    func convertRestaurantRequestToRestaurant(request: RestaurantRequest) -> Restaurant {
        let geoLoc = geoLoc(lat: 0, lng: 0) // Replace with actual values if available
        let stats = RestaurantStats(postCount: 0, collectionCount: 0) // Replace with actual values if available
        return Restaurant(
            id: "construction" + NSUUID().uuidString,
            name: request.name,
            city: request.city,
            state: request.state,
            stats: (RestaurantStats(postCount: 0, collectionCount: 0))
        )
    }
}

//#Preview{
//    AddRestaurantView(uploadViewModel: UploadViewModel(), dismissRestaurantList: .constant(true))
//}

//#Preview {
//    ReviewCreateRestaurantView()
//}
