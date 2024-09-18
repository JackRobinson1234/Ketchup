//
//  MapPriceFilter.swift
//  Foodi
//
//  Created by Jack Robinson on 4/9/24.
//

import SwiftUI

struct MapPriceFilter: View {
    @Binding var selectedPrice: [String]
    @State private var filteredPrice: [String] = []
    
    var body: some View {
        VStack {
            /// Title
            HStack{
                Text("Filter by Price")
                    .font(.custom("MuseoSansRounded-300", size: 22))
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                Spacer()
            }
            .padding(.leading)
            HStack{
                Text("Price Filters Selected:")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding(.leading)
            
            //MARK: Selected prices
            /// Selected Prices from the list that have been selected
            if !selectedPrice.isEmpty {
                ScrollView(.horizontal){
                    HStack{
                        ForEach(selectedPrice, id: \.self) { price in
                            HStack {
                                Image(systemName: "xmark")
                                    .foregroundColor(Color("Colors/AccentColor"))
                                    .onTapGesture {
                                        withAnimation(.snappy) {
                                            selectedPrice.removeAll(where: { $0 == price })
                                        }
                                    }
                                Text(price)
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                                    .foregroundStyle(.black)
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
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundStyle(.black)
                        .bold()
                    Spacer()
                }
                .padding()
            }
            //MARK: Price Options
            /// If there are still price options available
            if selectedPrice.count <= 3 {
                ScrollView(.horizontal){
                    HStack{
                        ForEach(filteredPrice, id: \.self) { price in
                            Text(price)
                                .foregroundStyle(.black)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .onTapGesture {
                                    withAnimation(.snappy) {
                                        if !selectedPrice.contains(price) {
                                            selectedPrice.insert(price, at: 0)}
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
        .onChange(of: selectedPrice) {oldValue in
            filteredPrice = filteredPrices()
        }
        .onAppear{
            filteredPrice = filteredPrices()
        }
    }
    func filteredPrices() -> [String] {
        let priceOptions = ["$", "$$", "$$$", "$$$$"]
        return priceOptions.filter { price in
            !selectedPrice.contains(price)}
    }
}
