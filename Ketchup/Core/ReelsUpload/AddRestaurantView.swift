//
//  CreateRestaurantView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/14/24.
//

import SwiftUI
import FirebaseFirestoreInternal
import FirebaseAuth

struct AddRestaurantView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var uploadViewModel: UploadViewModel
    @State private var name: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @Binding var dismissRestaurantList: Bool
    @State private var showAlert = false
    
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
                    TextField("State", text: $state)                            .padding()
                    Divider()
                    
                    
                    Button {
                        if isSubmitButtonDisabled {
                            showAlert.toggle()
                        } else {
                            submitRestaurantDetails()
                            dismissRestaurantList = true
                            dismiss()
                        }
                    } label: {
                        Text("Add Restaurant")
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
                .padding(.vertical)
            }
            .modifier(BackButtonModifier())
            .navigationBarTitle("Request New Restaurant", displayMode: .inline)
        }
    }
    
    func submitRestaurantDetails() {
        
        let newRestaurantRequest = RestaurantRequest(
            id: UUID().uuidString,
            userid: Auth.auth().currentUser!.uid,  // Replace with actual user ID
            name: name,
            state: state,
            city: city,
            timestamp: Timestamp(),
            postType: "Post"
        )
        uploadViewModel.restaurantRequest = newRestaurantRequest
        uploadViewModel.restaurant = nil
        // Implement the logic to save this newRestaurant to your database
    }
    private var isSubmitButtonDisabled: Bool {
        // Check if any of the required fields are empty
        name.isEmpty || city.isEmpty || state.isEmpty
    }
}

#Preview{
    AddRestaurantView(uploadViewModel: UploadViewModel(), dismissRestaurantList: .constant(true))
}
