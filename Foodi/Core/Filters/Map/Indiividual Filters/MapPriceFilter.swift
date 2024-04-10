//
//  MapPriceFilter.swift
//  Foodi
//
//  Created by Jack Robinson on 4/9/24.
//

import SwiftUI

struct MapPriceFilter: View {
    @ObservedObject var mapViewModel: MapViewModel
    
    /// will get assigned when .onAppear is called
    @State private var filteredPrice: [String] = []
    
    var body: some View {
        VStack {
            /// Title
            HStack{
                Text("Filter by Price")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.leading)
            HStack{
                Text("Price Filters Selected:")
                    .font(.caption)
                Spacer()
            }
            .padding(.leading)
            
            //MARK: Selected prices
            /// Selected Prices from the list that have been selected
            if !mapViewModel.selectedPrice.isEmpty {
                ScrollView(.horizontal){
                    HStack{
                        ForEach(mapViewModel.selectedPrice, id: \.self) { price in
                            HStack {
                                Image(systemName: "xmark")
                                    .foregroundColor(.red)
                                    .onTapGesture {
                                        withAnimation(.snappy) {
                                            mapViewModel.selectedPrice.removeAll(where: { $0 == price })
                                        }
                                    }
                                Text(price)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 5)
                        }
                    }
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                HStack{
                    Text("No Price Filters Selected")
                        .font(.subheadline)
                        .bold()
                    Spacer()
                }
                .padding()
            }
            //MARK: Price Options
            /// If there are still price options available
            if mapViewModel.selectedPrice.count <= 3 {
                ScrollView(.horizontal){
                    HStack{
                        ForEach(filteredPrice, id: \.self) { price in
                            Text(price)
                                .font(.subheadline)
                                .onTapGesture {
                                    withAnimation(.snappy) {
                                        if !mapViewModel.selectedPrice.contains(price) {
                                            mapViewModel.selectedPrice.insert(price, at: 0)}
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 5)
                        }
                    }
                    .padding()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            
            }
        }
        .onChange(of: mapViewModel.selectedPrice) {oldValue, newValue in
            filteredPrice = filteredPrices()
        }
        .onAppear{
            filteredPrice = filteredPrices()
        }
    }
    func filteredPrices() -> [String] {
            let priceOptions = ["$", "$$", "$$$", "$$$$"]
            return priceOptions.filter { price in
                !mapViewModel.selectedPrice.contains(price)}
        }
    }

#Preview {
    MapPriceFilter(mapViewModel: MapViewModel())
}
