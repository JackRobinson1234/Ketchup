

import SwiftUI

struct TestRestaurantListView: View {

    @StateObject var viewModel = RestaurantListViewModel(restaurantService: RestaurantService())
    @State private var searchText = ""
    @Binding var selectedRestaurant: Restaurant?
    @State var isLoading: Bool = true


    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
                    .onAppear {
                        Task {
                            try await viewModel.fetchRestaurants()
                            isLoading = false
                        }
                    }
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.restaurants) { restaurant in
                            Button(action: {
                                self.selectedRestaurant = restaurant
                            }) {
                                RestaurantCell(restaurant: restaurant)
                                    .padding(3)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            }
        }
    }
}

//Preview setup
struct TestRestaurantListView_Previews: PreviewProvider {
    static var previews: some View {
        TestRestaurantListView(selectedRestaurant: .constant(nil))
    }
}

