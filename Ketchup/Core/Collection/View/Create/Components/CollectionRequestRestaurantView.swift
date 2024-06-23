//
//  CollectionRequestRestaurantView.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/18/24.
//

import SwiftUI
import FirebaseFirestoreInternal
import FirebaseAuth

struct CollectionAddRestaurantView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var collectionsViewModel: CollectionsViewModel
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
                ZStack(alignment: .topLeading) {
                    
                    TextEditor(text: $collectionsViewModel.notes)
                        .frame(height: 100)  // Adjust the height as needed
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
                
                
                Button {
                    if isSubmitButtonDisabled {
                        showAlert.toggle()
                    } else {
                        Task{ try await
                            submitRestaurantDetails()
                        }
                        collectionsViewModel.dismissListView = true
                        dismiss()
                    }
                } label: {
                    Text("Add Restaurant to Collection")
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
                    .font(.custom("MuseoSans-500", size: 10))
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
        collectionsViewModel.restaurantRequest = newRestaurantRequest
        try await collectionsViewModel.addItemToCollection(collectionItem: collectionsViewModel.convertRequestToCollectionItem(name: name, city: city, state: state))
    }
    
    private var isSubmitButtonDisabled: Bool {
        // Check if any of the required fields are empty
        name.isEmpty || city.isEmpty || state.isEmpty
    }
}

//#Preview{
//    AddRestaurantView(uploadViewModel: UploadViewModel(), dismissRestaurantList: .constant(true))
//}
